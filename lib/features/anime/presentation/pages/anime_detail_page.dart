import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../download/presentation/providers/download_providers.dart';
import '../../../favorite/domain/entities/favorite_anime.dart';
import '../../../favorite/presentation/providers/favorite_providers.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/entities/episode.dart';
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
          message: error.toString(),
          onRetry: () => ref.invalidate(animeDetailProvider(animeId)),
        ),
        data: (detail) {
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
    final sources = await ref.read(
      playSourcesBySourceProvider(
        (sourceId: detail.sourceId, episodeId: episode.id),
      ).future,
    );
    if (!context.mounted) return;
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noPlaySource)),
      );
      return;
    }
    final source = sources.first;
    final query = <String, String>{
      'animeId': detail.id,
      'episodeId': episode.id,
      'title': detail.title,
      'episodeTitle': episode.title,
      'sourceId': detail.sourceId,
      'playUrl': source.url,
      if (detail.coverUrl != null) 'coverUrl': detail.coverUrl!,
    };
    context.push(Uri(path: '/player', queryParameters: query).toString());
  }

  Future<void> _createDownload(
    BuildContext context,
    WidgetRef ref,
    AnimeDetail detail,
    Episode episode,
  ) async {
    final sources = await ref.read(
      playSourcesBySourceProvider(
        (sourceId: detail.sourceId, episodeId: episode.id),
      ).future,
    );
    if (!context.mounted) return;
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noDownloadSource)),
      );
      return;
    }
    final taskId = await ref.read(httpDownloadServiceProvider).createTask(
          animeId: detail.id,
          episodeId: episode.id,
          sourceId: detail.sourceId,
          url: sources.first.url,
          title: detail.title,
          episodeTitle: episode.title,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.downloadTaskCreated(taskId))),
    );
  }
}
