import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../download/domain/entities/download_kind.dart';
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
                  _FallbackNotice(message: context.l10n.sourceFallbackNotice),
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
    if (sourceResult.usedFallback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sourceFallbackNotice)),
      );
    }
    final source = await _selectPlaySource(context, sources);
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
    if (sourceResult.usedFallback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sourceFallbackNotice)),
      );
    }
    final source = await _selectDownloadSource(context, sources);
    if (!context.mounted || source == null) return;
    final result = await ref.read(downloadTaskCreatorProvider).create(
          animeId: detail.id,
          episodeId: episode.id,
          sourceId: sourceResult.sourceId,
          url: source.url,
          title: detail.title,
          episodeTitle: episode.title,
          headers: source.headers,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_downloadTaskCreatedMessage(context, result.kind)),
        action: SnackBarAction(
          label: context.l10n.open,
          onPressed: () => context.push('/downloads'),
        ),
      ),
    );
  }

  String _downloadTaskCreatedMessage(
    BuildContext context,
    DownloadKind kind,
  ) {
    if (kind == DownloadKind.directFile) {
      return context.l10n.downloadTaskAdded;
    }
    final unsupportedMessage = switch (kind) {
      DownloadKind.hls => context.l10n.downloadUnsupportedHlsMessage,
      DownloadKind.bt => context.l10n.downloadUnsupportedBtMessage,
      DownloadKind.unknown => context.l10n.downloadUnsupportedUnknownMessage,
      DownloadKind.directFile => context.l10n.downloadTaskAdded,
    };
    return '$unsupportedMessage ${context.l10n.downloadUnsupportedListReviewNote}';
  }

  Future<PlaySource?> _selectPlaySource(
    BuildContext context,
    List<PlaySource> sources,
  ) {
    return _selectSource(
      context,
      sources,
      title: context.l10n.selectPlaySource,
      actionIcon: Icons.play_arrow,
    );
  }

  Future<PlaySource?> _selectDownloadSource(
    BuildContext context,
    List<PlaySource> sources,
  ) {
    return _selectSource(
      context,
      sources,
      title: context.l10n.selectDownloadSource,
      actionIcon: Icons.download_outlined,
    );
  }

  Future<PlaySource?> _selectSource(
    BuildContext context,
    List<PlaySource> sources, {
    required String title,
    required IconData actionIcon,
  }) async {
    if (sources.length == 1) return sources.first;
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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                );
              }

              final source = sources[index - 1];
              final host = Uri.tryParse(source.url)?.host;
              final subtitle = [
                if (source.quality != null) source.quality,
                if (host != null && host.isNotEmpty) host,
              ].join(' · ');
              return ListTile(
                leading: CircleAvatar(child: Text('$index')),
                title: Text(source.title),
                subtitle: subtitle.isEmpty ? null : Text(subtitle),
                trailing: Icon(actionIcon),
                onTap: () => Navigator.of(context).pop(source),
              );
            },
          ),
        );
      },
    );
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
