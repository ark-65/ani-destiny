import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../domain/entities/download_task.dart';
import '../providers/download_providers.dart';
import '../widgets/download_task_tile.dart';

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  var _isClearingEndedTasks = false;

  @override
  Widget build(BuildContext context) {
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
                  final removableTaskIds = _removableTaskIds(items);
                  if (items.isEmpty) {
                    return AppEmptyView(
                      message: context.l10n.downloadsEmpty,
                      icon: Icons.download_outlined,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (removableTaskIds.isNotEmpty) ...[
                        OutlinedButton.icon(
                          key: const ValueKey('downloads-clear-ended-tasks'),
                          onPressed: _isClearingEndedTasks
                              ? null
                              : () => unawaited(
                                    _handleClearRemovableTasks(
                                      removableTaskIds,
                                    ),
                                  ),
                          icon: _isClearingEndedTasks
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.clear_all),
                          label: Text(context.l10n.clearEndedDownloads),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final task = items[index];
                            return DownloadTaskTile(
                              task: task,
                              onStart: () => unawaited(
                                _runTaskAction(
                                  context,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .start(task.id),
                                ),
                              ),
                              onPause: () => unawaited(
                                _runTaskAction(
                                  context,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .pause(task.id),
                                ),
                              ),
                              onCancel: () => unawaited(
                                _runTaskAction(
                                  context,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .cancel(task.id),
                                ),
                              ),
                              onRemove: () => unawaited(
                                _runTaskAction(
                                  context,
                                  () => ref
                                      .read(downloadRepositoryProvider)
                                      .deleteTask(task.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
    final taskId = await ref.read(downloadTaskCreatorProvider).create(
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

  Future<void> _clearRemovableTasks(
    BuildContext context,
    WidgetRef ref,
    List<String> taskIds,
  ) async {
    final repository = ref.read(downloadRepositoryProvider);
    var clearedCount = 0;
    var failedCount = 0;
    for (final taskId in taskIds) {
      try {
        await repository.deleteTask(taskId);
        clearedCount += 1;
      } catch (_) {
        failedCount += 1;
      }
    }
    if (!context.mounted) return;
    final message = failedCount == 0
        ? context.l10n.clearEndedDownloadsResult(clearedCount)
        : context.l10n.clearEndedDownloadsPartialResult(
            clearedCount,
            failedCount,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleClearRemovableTasks(List<String> taskIds) async {
    if (_isClearingEndedTasks) return;
    setState(() {
      _isClearingEndedTasks = true;
    });
    try {
      await _clearRemovableTasks(context, ref, taskIds);
    } finally {
      if (mounted) {
        setState(() {
          _isClearingEndedTasks = false;
        });
      }
    }
  }

  List<String> _removableTaskIds(List<DownloadTask> items) {
    return items
        .where(_isRemovableTask)
        .map((task) => task.id)
        .toList(growable: false);
  }

  bool _isRemovableTask(DownloadTask task) {
    return switch (task.status) {
      DownloadStatus.completed ||
      DownloadStatus.failed ||
      DownloadStatus.canceled ||
      DownloadStatus.unsupported =>
        true,
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.downloading ||
      DownloadStatus.paused =>
        false,
    };
  }
}
