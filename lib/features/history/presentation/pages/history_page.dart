import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../anime/presentation/providers/anime_providers.dart';
import '../../../player/domain/entities/player_route_args.dart';
import '../../domain/entities/watch_history.dart';
import '../providers/history_providers.dart';
import '../widgets/history_tile.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);

    return SafeArea(
      child: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.history,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: history.when(
                loading: () =>
                    AppLoadingView(message: context.l10n.loadingHistory),
                error: (error, stackTrace) => AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(watchHistoryProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyView(
                      message: context.l10n.historyEmpty,
                      icon: Icons.history,
                    );
                  }
                  return ListView.separated(
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return HistoryTile(
                        history: item,
                        onContinue: () => _continue(context, ref, item),
                        onDelete: () =>
                            ref.read(historyRepositoryProvider).delete(item.id),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    WatchHistory history,
  ) async {
    final savedPlayUrl = history.playUrl?.trim();
    if (savedPlayUrl != null && savedPlayUrl.isNotEmpty) {
      _openPlayer(
        context,
        history,
        playUrl: savedPlayUrl,
        playHeaders: history.playHeaders,
        playSourceId: history.playSourceId,
        playSourceTitle: history.playSourceTitle,
      );
      return;
    }

    final sourceResult = await ref.read(
      playSourcesBySourceProvider(
        (sourceId: history.sourceId, episodeId: history.episodeId),
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
    final source = history.playSourceId == null
        ? sources.first
        : sources.firstWhere(
            (source) => source.id == history.playSourceId,
            orElse: () => sources.first,
          );
    _openPlayer(
      context,
      history,
      playUrl: source.url,
      playHeaders: source.headers,
      playSourceId: source.id,
      playSourceTitle: source.title,
      sourceId: sourceResult.sourceId,
      requestedSourceId: sourceResult.usedFallback
          ? sourceResult.fromSourceId ?? history.sourceId
          : null,
    );
  }

  void _openPlayer(
    BuildContext context,
    WatchHistory history, {
    required String playUrl,
    required Map<String, String> playHeaders,
    required String? playSourceId,
    required String? playSourceTitle,
    String? sourceId,
    String? requestedSourceId,
  }) {
    context.push(
      '/player',
      extra: PlayerRouteArgs(
        animeId: history.animeId,
        episodeId: history.episodeId,
        animeTitle: history.animeTitle,
        episodeTitle: history.episodeTitle,
        coverUrl: history.coverUrl,
        sourceId: sourceId ?? history.sourceId,
        requestedSourceId: requestedSourceId,
        playUrl: playUrl,
        playHeaders: playHeaders,
        playSourceId: playSourceId,
        playSourceTitle: playSourceTitle,
        initialPosition:
            history.position > Duration.zero ? history.position : null,
      ),
    );
  }
}
