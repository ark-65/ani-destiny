import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/diagnostics/diagnostic_sanitizer.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../download/domain/entities/download_kind.dart';
import '../../../download/domain/services/download_type_detector.dart';
import '../../../download/presentation/download_entry_feedback.dart';
import '../../../download/presentation/providers/download_providers.dart';
import '../../../favorite/domain/entities/favorite_anime.dart';
import '../../../favorite/presentation/providers/favorite_providers.dart';
import '../../../player/domain/entities/player_route_args.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/play_source.dart';
import '../providers/anime_providers.dart';
import '../widgets/anime_detail_header.dart';
import '../widgets/episode_list.dart';

class AnimeDetailPage extends ConsumerWidget {
  const AnimeDetailPage({
    required this.animeId,
    super.key,
    this.sourceId,
  });

  final String animeId;
  final String? sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceId = this.sourceId;
    final detailState = sourceId == null
        ? ref.watch(animeDetailProvider(animeId))
        : ref.watch(
            animeDetailBySourceProvider(
              (sourceId: sourceId, animeId: animeId),
            ),
          );

    return SafeArea(
      child: detailState.when(
        loading: () => AppLoadingView(message: context.l10n.loadingDetail),
        error: (error, stackTrace) => AppErrorView(
          message: '${context.l10n.sourceTemporarilyUnavailable}\n'
              '${context.l10n.sourceUnavailableSuggestion}',
          onRetry: () => sourceId == null
              ? ref.invalidate(animeDetailProvider(animeId))
              : ref.invalidate(
                  animeDetailBySourceProvider(
                    (sourceId: sourceId, animeId: animeId),
                  ),
                ),
        ),
        data: (result) {
          final detail = result.value;
          final isFavorite = ref
              .watch(
                isFavoriteProvider(
                  (sourceId: detail.sourceId, animeId: detail.id),
                ),
              )
              .valueOrNull;

          return AdaptivePage(
            child: ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.back,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: context.l10n.downloads,
                      onPressed: () => context.push('/downloads'),
                      icon: const Icon(Icons.download_outlined),
                    ),
                  ],
                ),
                AnimeDetailHeader(
                  detail: detail,
                  isFavorite: isFavorite ?? false,
                  onToggleFavorite: () => _toggleFavorite(ref, detail),
                ),
                if (result.usedFallback) ...[
                  const SizedBox(height: 12),
                  _FallbackNotice(
                    message: _fallbackNotice(
                      base: result.fromSourceId == null
                          ? context.l10n.sourceFallbackNotice
                          : context.l10n.sourceFallbackPlayerNotice(
                              context.l10n.sourceDisplayLabel(
                                result.fromSourceId!,
                              ),
                              context.l10n.sourceDisplayLabel(result.sourceId),
                            ),
                      reason: result.message,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(detail.description ?? context.l10n.noDescription),
                const SizedBox(height: 24),
                EpisodeList(
                  episodes: detail.episodes,
                  onPlay: (episode) =>
                      _playEpisode(context, ref, detail, episode),
                  onDownload: (episode) =>
                      _createDownload(context, ref, detail, episode),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, AnimeDetail detail) {
    return ref.read(favoriteRepositoryProvider).toggle(
          FavoriteAnime(
            animeId: detail.id,
            title: detail.title,
            coverUrl: detail.coverUrl,
            sourceId: detail.sourceId,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> _playEpisode(
    BuildContext context,
    WidgetRef ref,
    AnimeDetail detail,
    Episode episode,
  ) async {
    final sourceResult = await ref.read(
      playSourcesBySourceProvider(
        (sourceId: detail.sourceId, episodeId: episode.id),
      ).future,
    );
    if (!context.mounted) return;
    final sources = sourceResult.value;
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noPlayableSourceFound)),
      );
      return;
    }
    final fallbackNotice = sourceResult.usedFallback
        ? _fallbackNotice(
            base: context.l10n.sourceFallbackPlayerNotice(
              context.l10n.sourceDisplayLabel(
                sourceResult.fromSourceId ?? detail.sourceId,
              ),
              context.l10n.sourceDisplayLabel(sourceResult.sourceId),
            ),
            reason: sourceResult.message,
          )
        : null;
    final source = await _selectPlaySource(
      context,
      sources,
      fallbackNotice,
    );
    if (!context.mounted || source == null) return;
    context.push(
      '/player',
      extra: PlayerRouteArgs(
        animeId: detail.id,
        episodeId: episode.id,
        animeTitle: detail.title,
        episodeTitle: episode.title,
        coverUrl: detail.coverUrl,
        sourceId: sourceResult.sourceId,
        requestedSourceId: sourceResult.usedFallback
            ? sourceResult.fromSourceId ?? detail.sourceId
            : null,
        playSourceId: source.id,
        playSourceTitle: source.title,
        playUrl: source.url,
        playHeaders: source.headers,
        episodeIndex: episode.index,
      ),
    );
  }

  Future<void> _createDownload(
    BuildContext context,
    WidgetRef ref,
    AnimeDetail detail,
    Episode episode,
  ) async {
    try {
      final sourceResult = await ref.read(
        playSourcesBySourceProvider(
          (sourceId: detail.sourceId, episodeId: episode.id),
        ).future,
      );
      if (!context.mounted) return;
      final sources = sourceResult.value;
      if (sources.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noDownloadSource)),
        );
        return;
      }
      final downloadFallbackNotice = sourceResult.usedFallback
          ? _fallbackNotice(
              base: context.l10n.sourceFallbackNotice,
              reason: sourceResult.message,
            )
          : null;
      if (downloadFallbackNotice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(downloadFallbackNotice)),
        );
      }
      final fallbackNotice = sourceResult.usedFallback
          ? _fallbackNotice(
              base: context.l10n.sourceFallbackDownloadNotice(
                context.l10n.sourceDisplayLabel(
                  sourceResult.fromSourceId ?? detail.sourceId,
                ),
                context.l10n.sourceDisplayLabel(sourceResult.sourceId),
              ),
              reason: sourceResult.message,
            )
          : null;
      final source = await _selectDownloadSource(
        context,
        sources,
        fallbackNotice: fallbackNotice,
      );
      if (!context.mounted || source == null) return;
      final result = await ref.read(downloadTaskCreatorProvider).create(
            animeId: detail.id,
            episodeId: episode.id,
            sourceId: sourceResult.sourceId,
            url: source.url,
            title: detail.title,
            episodeTitle: episode.title,
            lineTitle: source.title,
            headers: source.headers,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(downloadEntryFeedbackMessage(context.l10n, result.kind)),
          action: SnackBarAction(
            label: downloadEntryFeedbackActionLabel(context.l10n, result.kind),
            onPressed: () => context.push(
              '/downloads?taskId=${Uri.encodeComponent(result.taskId)}',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(downloadEntryFeedbackErrorMessage(context.l10n, error)),
        ),
      );
    }
  }

  Future<PlaySource?> _selectPlaySource(
    BuildContext context,
    List<PlaySource> sources,
    String? fallbackNotice,
  ) {
    return _selectSource(
      context,
      sources,
      title: context.l10n.selectPlaySource,
      actionIcon: Icons.play_arrow,
      topNotice: fallbackNotice,
      forceSheet: fallbackNotice != null,
    );
  }

  Future<PlaySource?> _selectDownloadSource(
    BuildContext context,
    List<PlaySource> sources, {
    String? fallbackNotice,
  }) {
    return _selectSource(
      context,
      sources,
      title: context.l10n.selectDownloadSource,
      actionIcon: Icons.download_outlined,
      subtitleBuilder: (source) => _downloadSourceSubtitle(context, source),
      topNotice: fallbackNotice,
      forceSheet: fallbackNotice != null ||
          (sources.length == 1 &&
              _requiresDownloadSelectionConfirmation(sources.first)),
    );
  }

  Future<PlaySource?> _selectSource(
    BuildContext context,
    List<PlaySource> sources, {
    required String title,
    required IconData actionIcon,
    String? Function(PlaySource source)? subtitleBuilder,
    String? topNotice,
    bool forceSheet = false,
  }) async {
    if (sources.length == 1 && !forceSheet) return sources.first;
    return showModalBottomSheet<PlaySource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: sources.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (topNotice != null && topNotice.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          topNotice,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final source = sources[index - 1];
              final subtitle =
                  subtitleBuilder?.call(source) ?? _sourceSubtitle(source);
              return ListTile(
                isThreeLine: subtitle.contains('\n'),
                leading: CircleAvatar(child: Text('$index')),
                title: Text(source.title),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: Icon(actionIcon),
                onTap: () => Navigator.of(context).pop(source),
              );
            },
          ),
        );
      },
    );
  }

  bool _requiresDownloadSelectionConfirmation(PlaySource source) {
    return detectDownloadKind(source.url) != DownloadKind.directFile;
  }

  String _downloadSourceSubtitle(BuildContext context, PlaySource source) {
    final baseSubtitle = _sourceSubtitle(source);
    final kind = detectDownloadKind(source.url);
    final downloadNote = kind == DownloadKind.directFile
        ? '${context.l10n.downloadKindDirectFile} · '
            '${context.l10n.downloadSelectionPendingNote}'
        : downloadEntryFeedbackMessage(context.l10n, kind);
    return [if (baseSubtitle.isNotEmpty) baseSubtitle, downloadNote].join('\n');
  }

  String _sourceSubtitle(PlaySource source) {
    final host = Uri.tryParse(source.url)?.host;
    return [
      if (source.quality != null) source.quality,
      if (host != null && host.isNotEmpty) host,
    ].join(' · ');
  }

  String _fallbackNotice({
    required String base,
    String? reason,
  }) {
    final normalizedReason = reason?.trim();
    if (normalizedReason == null || normalizedReason.isEmpty) return base;
    final displayReason = sanitizeSourceFallbackNoticeReason(normalizedReason);
    if (displayReason == null || displayReason.isEmpty) return base;
    return '$base\n$displayReason';
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.swap_horiz_outlined),
        title: Text(message),
        dense: true,
      ),
    );
  }
}
