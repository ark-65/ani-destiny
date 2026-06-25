import 'dart:async';

import 'package:flutter/foundation.dart';
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
  const DownloadPage({
    this.showDebugMockAction = kDebugMode,
    super.key,
  });

  final bool showDebugMockAction;

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  var _isClearingEndedTasks = false;
  final Set<String> _busyTaskIds = <String>{};

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
                if (widget.showDebugMockAction)
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
                  final clearableTaskIds = _clearableTaskIds(removableTaskIds);
                  final hasBusyRemovableTask = removableTaskIds.any(
                    _busyTaskIds.contains,
                  );
                  final hasCompletedTasks = items.any(
                    (task) => task.status == DownloadStatus.completed,
                  );
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
                          onPressed: _isClearingEndedTasks ||
                                  hasBusyRemovableTask ||
                                  clearableTaskIds.isEmpty
                              ? null
                              : () => unawaited(
                                    _handleClearRemovableTasks(
                                      clearableTaskIds,
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
                        if (hasCompletedTasks) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.clearEndedDownloadsKeepsFilesNote,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final task = items[index];
                            final isBusy = _busyTaskIds.contains(task.id) ||
                                (_isClearingEndedTasks &&
                                    clearableTaskIds.contains(task.id));
                            return DownloadTaskTile(
                              task: task,
                              isBusy: isBusy,
                              onStart: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .start(task.id),
                                ),
                              ),
                              onPause: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .pause(task.id),
                                ),
                              ),
                              onCancel: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .cancel(task.id),
                                ),
                              ),
                              onRemove: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
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
    String taskId,
    Future<void> Function() action,
  ) async {
    if (_busyTaskIds.contains(taskId)) return;
    setState(() {
      _busyTaskIds.add(taskId);
    });
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyTaskIds.remove(taskId);
        });
      } else {
        _busyTaskIds.remove(taskId);
      }
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

  List<String> _clearableTaskIds(List<String> removableTaskIds) {
    return removableTaskIds
        .where((taskId) => !_busyTaskIds.contains(taskId))
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
