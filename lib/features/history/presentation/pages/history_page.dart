import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../anime/presentation/providers/anime_providers.dart';
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
    final sources = await ref.read(
      playSourcesBySourceProvider(
        (sourceId: history.sourceId, episodeId: history.episodeId),
      ).future,
    );
    if (!context.mounted) return;
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noPlaySource)),
      );
      return;
    }
    context.push(
      Uri(
        path: '/player',
        queryParameters: {
          'animeId': history.animeId,
          'episodeId': history.episodeId,
          'title': history.animeTitle,
          'episodeTitle': history.episodeTitle,
          'sourceId': history.sourceId,
          'playUrl': sources.first.url,
          if (history.coverUrl != null) 'coverUrl': history.coverUrl!,
        },
      ).toString(),
    );
  }
}
