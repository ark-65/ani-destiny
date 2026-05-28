import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../providers/download_providers.dart';
import '../widgets/download_task_tile.dart';

class DownloadPage extends ConsumerWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadTasksProvider);

    return SafeArea(
      child: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/settings');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.downloads,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => unawaited(_createMockTask(context, ref)),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.mock),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tasks.when(
                loading: () =>
                    AppLoadingView(message: context.l10n.loadingDownloads),
                error: (error, stackTrace) => AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(downloadTasksProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyView(
                      message: context.l10n.downloadsEmpty,
                      icon: Icons.download_outlined,
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final task = items[index];
                      return DownloadTaskTile(
                        task: task,
                        onStart: () => unawaited(
                          _runTaskAction(
                            context,
                            () => ref.read(httpDownloadServiceProvider).start(
                                  task.id,
                                ),
                          ),
                        ),
                        onPause: () => unawaited(
                          ref.read(httpDownloadServiceProvider).pause(task.id),
                        ),
                        onCancel: () => unawaited(
                          ref.read(httpDownloadServiceProvider).cancel(task.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMockTask(BuildContext context, WidgetRef ref) async {
    final taskId = await ref.read(httpDownloadServiceProvider).createTask(
          animeId: 'mock-starlight-voyage',
          episodeId: 'mock-starlight-voyage-ep-1',
          sourceId: 'mock',
          url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
          title: 'Starlight Voyage',
          episodeTitle: 'Episode 1 - Departure Signal',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.mockDownloadTaskCreated(taskId))),
    );
  }

  Future<void> _runTaskAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}
