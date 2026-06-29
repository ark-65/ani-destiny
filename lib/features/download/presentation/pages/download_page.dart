import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../domain/entities/download_task.dart';
import '../download_task_cleanup_state.dart';
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

class _DownloadPageState extends ConsumerState<DownloadPage>
    with WidgetsBindingObserver {
  var _isClearingEndedTasks = false;
  final Map<String, DownloadTaskBusyAction> _busyTaskActions =
      <String, DownloadTaskBusyAction>{};
  Set<String> _manualCleanupTaskIdsBeforeBackground = const <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tasks = ref.read(downloadTasksProvider).valueOrNull;
    if (tasks == null) {
      return;
    }

    if (state == AppLifecycleState.resumed && mounted) {
      final currentManualCleanupTaskIds = _manualCleanupTaskIds(tasks);
      final recoveredCleanupTaskIds =
          _manualCleanupTaskIdsBeforeBackground.difference(
        currentManualCleanupTaskIds,
      );
      final remainingCount = currentManualCleanupTaskIds.length;
      _manualCleanupTaskIdsBeforeBackground = currentManualCleanupTaskIds;
      setState(() {});
      if (recoveredCleanupTaskIds.isNotEmpty) {
        final clearableTaskCount = _clearableTaskIds(tasks).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.downloadManualCleanupResumeResult(
                recoveredCleanupTaskIds.length,
                remainingCount,
                actionLabel: remainingCount > 1
                    ? context.l10n.recheckLeftoverFilesCount(remainingCount)
                    : clearableTaskCount > 1
                        ? context.l10n.clearEndedDownloadsCount(
                            clearableTaskCount,
                          )
                        : null,
                clearActionLabel: remainingCount == 1 && clearableTaskCount > 1
                    ? context.l10n.clearEndedDownloadsCount(
                        clearableTaskCount,
                      )
                    : null,
              ),
            ),
          ),
        );
      }
      return;
    }

    _manualCleanupTaskIdsBeforeBackground = _manualCleanupTaskIds(tasks);
  }

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
                  final clearableTaskIds = _clearableTaskIds(items);
                  final manualCleanupTaskIds = _manualCleanupTaskIds(items);
                  final manualCleanupTaskCount = manualCleanupTaskIds.length;
                  final showClearEndedTasksAction = clearableTaskIds.length > 1;
                  final showRecheckManualCleanupAction =
                      manualCleanupTaskCount > 1;
                  final manualCleanupBatchRecheckLabel =
                      showRecheckManualCleanupAction
                          ? context.l10n.recheckLeftoverFilesCount(
                              manualCleanupTaskCount,
                            )
                          : null;
                  final hasBusyRemovableTask = removableTaskIds.any(
                    _busyTaskActions.containsKey,
                  );
                  final hasCompletedTasks = items.any(
                    (task) => task.status == DownloadStatus.completed,
                  );
                  final hasDiscardedTasksAwaitingCleanup = items.any(
                    downloadTaskNeedsManualCleanup,
                  );
                  final showCleanupGuidance = showClearEndedTasksAction ||
                      hasCompletedTasks ||
                      hasDiscardedTasksAwaitingCleanup;
                  if (items.isEmpty) {
                    return AppEmptyView(
                      message: context.l10n.downloadsEmpty,
                      icon: Icons.download_outlined,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showCleanupGuidance) ...[
                        if (showRecheckManualCleanupAction ||
                            showClearEndedTasksAction)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (showRecheckManualCleanupAction)
                                OutlinedButton.icon(
                                  key: const ValueKey(
                                    'downloads-recheck-manual-cleanup',
                                  ),
                                  onPressed: _isClearingEndedTasks
                                      ? null
                                      : () => _recheckManualCleanupTasks(
                                            items
                                                .where(
                                                  (task) => manualCleanupTaskIds
                                                      .contains(task.id),
                                                )
                                                .toList(growable: false),
                                          ),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    context.l10n.recheckLeftoverFilesCount(
                                      manualCleanupTaskCount,
                                    ),
                                  ),
                                ),
                              if (showClearEndedTasksAction)
                                OutlinedButton.icon(
                                  key: const ValueKey(
                                    'downloads-clear-ended-tasks',
                                  ),
                                  onPressed: _isClearingEndedTasks ||
                                          hasBusyRemovableTask
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
                                  label: Text(
                                    context.l10n.clearEndedDownloadsCount(
                                      clearableTaskIds.length,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (hasCompletedTasks) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.clearEndedDownloadsKeepsFilesNote,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                        ],
                        if (hasDiscardedTasksAwaitingCleanup) ...[
                          const SizedBox(height: 8),
                          Text(
                            _manualCleanupRetentionGuidance(
                              context,
                              manualCleanupTaskCount,
                              clearableTaskCount: clearableTaskIds.length,
                            ),
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
                            final isBusy =
                                _busyTaskActions.containsKey(task.id) ||
                                    (_isClearingEndedTasks &&
                                        clearableTaskIds.contains(task.id));
                            return DownloadTaskTile(
                              task: task,
                              isBusy: isBusy,
                              busyAction: _busyTaskActions[task.id],
                              onStart: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  DownloadTaskBusyAction.start,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .start(task.id),
                                ),
                              ),
                              onPause: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  DownloadTaskBusyAction.pause,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .pause(task.id),
                                ),
                              ),
                              onCancel: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  DownloadTaskBusyAction.cancel,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .cancel(task.id),
                                ),
                              ),
                              onRemove: () => unawaited(
                                _runTaskAction(
                                  context,
                                  task.id,
                                  DownloadTaskBusyAction.remove,
                                  () => ref
                                      .read(httpDownloadServiceProvider)
                                      .removeEndedTask(task.id),
                                ),
                              ),
                              onRefreshCleanupStatus:
                                  downloadTaskNeedsManualCleanup(task)
                                      ? () => _refreshCleanupStatus(task)
                                      : null,
                              manualCleanupBatchRecheckLabel:
                                  downloadTaskNeedsManualCleanup(task)
                                      ? manualCleanupBatchRecheckLabel
                                      : null,
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

  void _recheckManualCleanupTasks(List<DownloadTask> tasks) {
    if (tasks.length < 2 || !mounted) {
      return;
    }

    var remainingCount = 0;
    for (final task in tasks) {
      if (downloadTaskNeedsManualCleanup(task)) {
        remainingCount += 1;
      }
    }
    final clearedCount = tasks.length - remainingCount;
    final allTasks = ref.read(downloadTasksProvider).valueOrNull;
    final clearableTaskCount =
        allTasks == null ? 0 : _clearableTaskIds(allTasks).length;

    setState(() {});

    final message = switch ((clearedCount, remainingCount)) {
      (0, _) => context.l10n.downloadManualCleanupBulkRecheckStillNeeded(
          tasks.length,
        ),
      (_, 0) => context.l10n.downloadManualCleanupBulkRecheckCleared(
          clearedCount,
          actionLabel: clearableTaskCount > 1
              ? context.l10n.clearEndedDownloadsCount(clearableTaskCount)
              : null,
        ),
      _ => context.l10n.downloadManualCleanupBulkRecheckPartial(
          clearedCount,
          remainingCount,
          actionLabel: remainingCount > 1
              ? context.l10n.recheckLeftoverFilesCount(remainingCount)
              : null,
          clearActionLabel: remainingCount == 1 && clearableTaskCount > 1
              ? context.l10n.clearEndedDownloadsCount(clearableTaskCount)
              : null,
        ),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    DownloadTaskBusyAction busyAction,
    Future<void> Function() action,
  ) async {
    if (_busyTaskActions.containsKey(taskId)) return;
    setState(() {
      _busyTaskActions[taskId] = busyAction;
    });
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_actionErrorMessage(context, error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyTaskActions.remove(taskId);
        });
      } else {
        _busyTaskActions.remove(taskId);
      }
    }
  }

  Future<void> _clearRemovableTasks(
    BuildContext context,
    WidgetRef ref,
    List<String> taskIds,
  ) async {
    final service = ref.read(httpDownloadServiceProvider);
    var clearedCount = 0;
    var failedCount = 0;
    for (final taskId in taskIds) {
      try {
        await service.removeEndedTask(taskId);
        clearedCount += 1;
      } catch (_) {
        failedCount += 1;
      }
    }
    if (!context.mounted) return;
    final baseMessage = failedCount == 0
        ? context.l10n.clearEndedDownloadsResult(clearedCount)
        : context.l10n.clearEndedDownloadsPartialResult(
            clearedCount,
            failedCount,
          );
    final remainingTasks = ref.read(downloadTasksProvider).valueOrNull;
    final remainingManualCleanupCount =
        remainingTasks?.where(downloadTaskNeedsManualCleanup).length ?? 0;
    final message = remainingManualCleanupCount > 0
        ? '$baseMessage\n${_manualCleanupRetentionGuidance(context, remainingManualCleanupCount)}'
        : baseMessage;
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

  void _refreshCleanupStatus(DownloadTask task) {
    if (!mounted) return;
    final stillNeedsCleanup = downloadTaskNeedsManualCleanup(task);
    final allTasks = ref.read(downloadTasksProvider).valueOrNull;
    final clearableTaskCount =
        allTasks == null ? 0 : _clearableTaskIds(allTasks).length;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stillNeedsCleanup
              ? context.l10n.downloadManualCleanupRecheckStillNeeded
              : clearableTaskCount > 1
                  ? context.l10n.downloadManualCleanupRecheckClearedAction(
                      context.l10n.clearEndedDownloadsCount(clearableTaskCount),
                    )
                  : context.l10n.downloadManualCleanupRecheckCleared,
        ),
      ),
    );
  }

  List<String> _removableTaskIds(List<DownloadTask> items) {
    return items
        .where(_isRemovableTask)
        .map((task) => task.id)
        .toList(growable: false);
  }

  List<String> _clearableTaskIds(List<DownloadTask> items) {
    return items
        .where(_isRemovableTask)
        .where((task) => !downloadTaskNeedsManualCleanup(task))
        .map((task) => task.id)
        .where((taskId) => !_busyTaskActions.containsKey(taskId))
        .toList(growable: false);
  }

  Set<String> _manualCleanupTaskIds(List<DownloadTask> items) {
    return items
        .where(downloadTaskNeedsManualCleanup)
        .map((task) => task.id)
        .toSet();
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

  String _manualCleanupRetentionGuidance(
    BuildContext context,
    int count, {
    int clearableTaskCount = 0,
  }) {
    assert(count > 0);
    if (count == 1) {
      if (clearableTaskCount > 1) {
        return context.l10n.clearEndedDownloadsRetainedDiscardedClearActionNote(
          context.l10n.clearEndedDownloadsCount(clearableTaskCount),
        );
      }
      return context.l10n.clearEndedDownloadsRetainedDiscardedNote;
    }
    return context.l10n.clearEndedDownloadsRetainedDiscardedBatchRecheckNote(
      context.l10n.recheckLeftoverFilesCount(count),
    );
  }

  String _actionErrorMessage(BuildContext context, Object error) {
    if (error is AppException &&
        error.code == 'download_manual_cleanup_required') {
      return context.l10n.downloadManualCleanupRequiredError;
    }
    if (error is AppException) {
      return error.message;
    }
    return error.toString();
  }
}
