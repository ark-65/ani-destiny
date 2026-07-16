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
import '../download_entry_feedback.dart';
import '../download_task_cleanup_state.dart';
import '../providers/download_providers.dart';
import '../widgets/download_task_tile.dart';

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({
    this.showDebugMockAction = kDebugMode,
    this.focusTaskId,
    super.key,
  });

  final bool showDebugMockAction;
  final String? focusTaskId;

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage>
    with WidgetsBindingObserver {
  var _isClearingEndedTasks = false;
  final Map<String, DownloadTaskBusyAction> _busyTaskActions =
      <String, DownloadTaskBusyAction>{};
  Set<String> _manualCleanupTaskIdsBeforeBackground = const <String>{};
  StreamSubscription<List<DownloadTask>>? _downloadTaskSubscription;

  _DownloadSnackBarAction? _followUpSnackBarAction(List<DownloadTask>? tasks) {
    if (tasks == null) {
      return null;
    }
    final clearableTaskIds = _clearableTaskIds(tasks);
    if (clearableTaskIds.length > 1) {
      return _DownloadSnackBarAction(
        label: context.l10n.clearEndedDownloadsCount(clearableTaskIds.length),
        onPressed: () => _handleClearEndedTasksAction(clearableTaskIds),
      );
    }
    if (clearableTaskIds.length == 1) {
      return _DownloadSnackBarAction(
        label: context.l10n.removeFromList,
        onPressed: () => _handleRemoveSingleReadyTask(clearableTaskIds.single),
      );
    }
    return null;
  }

  _DownloadSnackBarAction? _manualCleanupFollowUpSnackBarAction(
    List<DownloadTask>? tasks, {
    required int remainingCount,
  }) {
    if (remainingCount < 0 || tasks == null) {
      return null;
    }
    final followUpAction = _followUpSnackBarAction(tasks);
    if (followUpAction != null) {
      return followUpAction;
    }
    if (remainingCount == 0) {
      return null;
    }
    final manualCleanupTasks = tasks
        .where(downloadTaskNeedsManualCleanup)
        .toList(growable: false);
    if (manualCleanupTasks.isEmpty) {
      return null;
    }
    return _DownloadSnackBarAction(
      label: context.l10n.checkAgain,
      onPressed: () => _recheckManualCleanupTasks(manualCleanupTasks),
    );
  }

  _DownloadSnackBarAction? _manualCleanupFailureFollowUpSnackBarAction(
    List<DownloadTask>? tasks, {
    required List<String> manualCleanupTaskIds,
  }) {
    if (manualCleanupTaskIds.isEmpty || tasks == null || tasks.isEmpty) {
      return null;
    }
    final manualCleanupTasks = tasks
        .where((task) => manualCleanupTaskIds.contains(task.id))
        .toList(growable: false);
    if (manualCleanupTasks.isEmpty) {
      return null;
    }
    if (manualCleanupTasks.length == 1) {
      return _DownloadSnackBarAction(
        label: context.l10n.checkAgain,
        onPressed: () => _refreshCleanupStatus(manualCleanupTasks.single),
      );
    }
    return _DownloadSnackBarAction(
      label: context.l10n.checkAgain,
      onPressed: () => _recheckManualCleanupTasks(manualCleanupTasks),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _downloadTaskSubscription =
        ref.read(downloadRepositoryProvider).watchTasks().listen(
              _handleDownloadTaskUpdates,
            );
  }

  @override
  void dispose() {
    _downloadTaskSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleDownloadTaskUpdates(List<DownloadTask> tasks) {
    if (!mounted || _busyTaskActions.isEmpty) {
      return;
    }

    final settledStartTaskIds = tasks
        .where(
          (task) =>
              _busyTaskActions[task.id] == DownloadTaskBusyAction.start &&
              (task.status == DownloadStatus.preparing ||
                  task.status == DownloadStatus.downloading ||
                  task.status == DownloadStatus.completed),
        )
        .map((task) => task.id)
        .toList(growable: false);
    if (settledStartTaskIds.isEmpty) {
      return;
    }

    setState(() {
      for (final taskId in settledStartTaskIds) {
        _busyTaskActions.remove(taskId);
      }
    });
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
        final clearActionLabel =
            _clearEndedTasksActionLabel(clearableTaskCount);
        final removeActionLabel =
            _singleReadyTaskRemoveActionLabel(clearableTaskCount);
        final followUpAction = _manualCleanupFollowUpSnackBarAction(
          tasks,
          remainingCount: remainingCount,
        );
        _showDownloadSnackBar(
          context.l10n.downloadManualCleanupResumeResult(
            recoveredCleanupTaskIds.length,
            remainingCount,
            actionLabel: remainingCount > 1
                ? context.l10n.recheckLeftoverFilesCount(remainingCount)
                : clearActionLabel,
            clearActionLabel: remainingCount == 1 ? clearActionLabel : null,
            removeActionLabel: removeActionLabel,
          ),
          action: followUpAction,
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
                  message: _pageErrorMessage(error),
                  onRetry: () => ref.invalidate(downloadTasksProvider),
                ),
                data: (items) {
                  final focusedTaskId = widget.focusTaskId?.trim();
                  final focusedTask =
                      focusedTaskId == null || focusedTaskId.isEmpty
                          ? null
                          : items.cast<DownloadTask?>().firstWhere(
                                (task) => task?.id == focusedTaskId,
                                orElse: () => null,
                              );
                  final visibleItems = focusedTask == null
                      ? items
                      : [
                          focusedTask,
                          ...items.where((task) => task.id != focusedTaskId),
                        ];
                  final removableTaskIds = _removableTaskIds(items);
                  final clearableTaskIds = _clearableTaskIds(items);
                  final manualCleanupTaskIds = _manualCleanupTaskIds(items);
                  final manualCleanupTaskCount = manualCleanupTaskIds.length;
                  final showClearEndedTasksAction = clearableTaskIds.length > 1;
                  final showSingleReadyTaskAction =
                      clearableTaskIds.length == 1 &&
                      manualCleanupTaskCount > 0;
                  final showRecheckManualCleanupAction =
                      manualCleanupTaskCount > 0;
                  final manualCleanupBatchRecheckLabel =
                      showRecheckManualCleanupAction
                          ? context.l10n.recheckLeftoverFilesCount(
                              manualCleanupTaskCount,
                            )
                          : null;
                  final manualCleanupReadyActionLabel =
                      clearableTaskIds.length > 1
                          ? context.l10n.clearEndedDownloadsCount(
                              clearableTaskIds.length,
                            )
                          : clearableTaskIds.length == 1
                              ? context.l10n.removeFromList
                              : null;
                  final manualCleanupReadyActionIsBatch =
                      clearableTaskIds.length > 1;
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
                            showClearEndedTasksAction ||
                            showSingleReadyTaskAction)
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
                              if (showSingleReadyTaskAction)
                                OutlinedButton.icon(
                                  key: const ValueKey(
                                    'downloads-remove-ready-task',
                                  ),
                                  onPressed: _isClearingEndedTasks ||
                                          hasBusyRemovableTask
                                      ? null
                                      : () => _handleRemoveSingleReadyTask(
                                            clearableTaskIds.single,
                                          ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(context.l10n.removeFromList),
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
                      if (focusedTask != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.l10n.downloadFocusedTaskNotice,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: ListView.builder(
                          itemCount: visibleItems.length,
                          itemBuilder: (context, index) {
                            final task = visibleItems[index];
                            final batchRemovingTask = _isClearingEndedTasks &&
                                clearableTaskIds.contains(task.id);
                            final isBusy =
                                _busyTaskActions.containsKey(task.id) ||
                                    batchRemovingTask;
                            return DownloadTaskTile(
                              task: task,
                              isBusy: isBusy,
                              isHighlighted: task.id == focusedTaskId,
                              busyAction: _busyTaskActions[task.id] ??
                                  (batchRemovingTask
                                      ? DownloadTaskBusyAction.remove
                                      : null),
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
                              manualCleanupReadyActionLabel:
                                  downloadTaskNeedsManualCleanup(task)
                                      ? manualCleanupReadyActionLabel
                                      : null,
                              manualCleanupReadyActionIsBatch:
                                  manualCleanupReadyActionIsBatch,
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
    if (tasks.isEmpty || !mounted) {
      return;
    }
    if (tasks.length == 1) {
      final firstTask = tasks.single;
      final currentTask = _findTask(firstTask.id);
      _refreshCleanupStatus(currentTask ?? firstTask);
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
    final clearActionLabel = _clearEndedTasksActionLabel(clearableTaskCount);
    final removeActionLabel =
        _singleReadyTaskRemoveActionLabel(clearableTaskCount);
    final followUpAction = _manualCleanupFollowUpSnackBarAction(
      allTasks,
      remainingCount: remainingCount,
    );

    setState(() {});

    final message = switch ((clearedCount, remainingCount)) {
      (0, _) => context.l10n.downloadManualCleanupBulkRecheckStillNeeded(
          tasks.length,
        ),
      (_, 0) => context.l10n.downloadManualCleanupBulkRecheckCleared(
          clearedCount,
          actionLabel: clearActionLabel,
        ),
      _ => context.l10n.downloadManualCleanupBulkRecheckPartial(
          clearedCount,
          remainingCount,
          actionLabel: remainingCount > 1
              ? context.l10n.recheckLeftoverFilesCount(remainingCount)
              : null,
          clearActionLabel: remainingCount == 1 ? clearActionLabel : null,
          removeActionLabel: removeActionLabel,
        ),
    };
    _showDownloadSnackBar(
      message,
      action: followUpAction,
    );
  }

  Future<void> _createMockTask(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(downloadTaskCreatorProvider).create(
          animeId: 'mock-starlight-voyage',
          episodeId: 'mock-starlight-voyage-ep-1',
          sourceId: 'mock',
          url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
          title: 'Starlight Voyage',
          episodeTitle: 'Episode 1 - Departure Signal',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.mockDownloadTaskCreated(result.taskId)),
        action: SnackBarAction(
          label: context.l10n.openDownloads,
          onPressed: () => context
              .push('/downloads?taskId=${Uri.encodeComponent(result.taskId)}'),
        ),
      ),
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
      _showDownloadSnackBar(
        _actionErrorMessage(context, error),
        action: _taskActionFailureSnackBarAction(
          taskId: taskId,
          error: error,
          busyAction: busyAction,
        ),
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

  _DownloadSnackBarAction? _taskActionFailureSnackBarAction({
    required String taskId,
    required Object error,
    required DownloadTaskBusyAction busyAction,
  }) {
    if (busyAction != DownloadTaskBusyAction.remove) {
      return null;
    }
    if (downloadActionErrorCode(error) != 'download_manual_cleanup_required') {
      return null;
    }

    final task = _findTask(taskId);
    if (task == null) {
      return null;
    }

    return _DownloadSnackBarAction(
      label: context.l10n.checkAgain,
      onPressed: () => _refreshCleanupStatus(task),
    );
  }

  DownloadTask? _findTask(String taskId) {
    final tasks = ref.read(downloadTasksProvider).valueOrNull;
    if (tasks == null) {
      return null;
    }
    for (final task in tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<void> _clearRemovableTasks(
    BuildContext context,
    WidgetRef ref,
    List<String> taskIds,
  ) async {
    final service = ref.read(httpDownloadServiceProvider);
    final l10n = context.l10n;
    var clearedCount = 0;
    var failedCount = 0;
    final manualCleanupTaskIds = <String>[];
    final List<String> failureMessages = [];
    for (final taskId in taskIds) {
      try {
        await service.removeEndedTask(taskId);
        clearedCount += 1;
      } catch (error) {
        failedCount += 1;
        if (downloadActionErrorCode(error) == 'download_manual_cleanup_required') {
          manualCleanupTaskIds.add(taskId);
        }
        final failureMessage = error is AppException &&
                error.code == 'download_manual_cleanup_required'
            ? l10n.downloadManualCleanupRequiredError
            : downloadActionErrorMessage(l10n, error);
        if (!failureMessages.contains(failureMessage)) {
          failureMessages.add(failureMessage);
        }
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
    final remainingClearableTaskCount =
        remainingTasks == null ? 0 : _clearableTaskIds(remainingTasks).length;
    final actionFailureMessage = failedCount > 0 && failureMessages.isNotEmpty
        ? '$baseMessage\n${failureMessages.map((message) => '• $message').join('\n')}'
        : baseMessage;
    final message = remainingManualCleanupCount > 0
        ? '$actionFailureMessage\n${_manualCleanupRetentionGuidance(context, remainingManualCleanupCount, clearableTaskCount: remainingClearableTaskCount)}'
        : actionFailureMessage;
    final manualCleanupTasks = remainingTasks
        ?.where((task) => manualCleanupTaskIds.contains(task.id))
        .toList(growable: false);
    final followUpAction = _manualCleanupFailureFollowUpSnackBarAction(
      manualCleanupTasks,
      manualCleanupTaskIds: manualCleanupTaskIds,
    );
    _showDownloadSnackBar(
      message,
      action: followUpAction,
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
    final clearActionLabel = _clearEndedTasksActionLabel(clearableTaskCount);
    final followUpAction = _followUpSnackBarAction(allTasks);
    setState(() {});
    _showDownloadSnackBar(
      stillNeedsCleanup
          ? context.l10n.downloadManualCleanupRecheckStillNeeded
          : clearActionLabel != null
              ? context.l10n.downloadManualCleanupRecheckClearedAction(
                  clearActionLabel,
                )
              : context.l10n.downloadManualCleanupRecheckCleared,
      action: stillNeedsCleanup ? null : followUpAction,
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
      if (clearableTaskCount == 1) {
        return context.l10n
            .clearEndedDownloadsRetainedDiscardedRemoveActionNote(
          context.l10n.removeFromList,
        );
      }
      return context.l10n.clearEndedDownloadsRetainedDiscardedNote;
    }
    if (clearableTaskCount > 1) {
      return context.l10n
          .clearEndedDownloadsRetainedDiscardedBatchClearActionNote(
        context.l10n.clearEndedDownloadsCount(clearableTaskCount),
        context.l10n.recheckLeftoverFilesCount(count),
      );
    }
    if (clearableTaskCount == 1) {
      return context.l10n
          .clearEndedDownloadsRetainedDiscardedBatchRemoveActionNote(
        context.l10n.removeFromList,
        context.l10n.recheckLeftoverFilesCount(count),
      );
    }
    return context.l10n.clearEndedDownloadsRetainedDiscardedBatchRecheckNote(
      context.l10n.recheckLeftoverFilesCount(count),
    );
  }

  void _showDownloadSnackBar(
    String message, {
    _DownloadSnackBarAction? action,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action == null
            ? null
            : SnackBarAction(
                label: action.label,
                onPressed: action.onPressed,
              ),
      ),
    );
  }

  String? _clearEndedTasksActionLabel(int clearableTaskCount) {
    if (clearableTaskCount <= 1) {
      return null;
    }
    return context.l10n.clearEndedDownloadsCount(clearableTaskCount);
  }

  String? _singleReadyTaskRemoveActionLabel(int clearableTaskCount) {
    if (clearableTaskCount != 1) {
      return null;
    }
    return context.l10n.removeFromList;
  }

  void _handleClearEndedTasksAction(List<String> clearableTaskIds) {
    if (clearableTaskIds.length <= 1) {
      return;
    }
    unawaited(_handleClearRemovableTasks(clearableTaskIds));
  }

  void _handleRemoveSingleReadyTask(String taskId) {
    unawaited(
      _runTaskAction(
        context,
        taskId,
        DownloadTaskBusyAction.remove,
        () => ref.read(httpDownloadServiceProvider).removeEndedTask(taskId),
      ),
    );
  }

  String _actionErrorMessage(BuildContext context, Object error) {
    if (error is AppException &&
        error.code == 'download_manual_cleanup_required') {
      return context.l10n.downloadManualCleanupRequiredError;
    }
    return downloadActionErrorMessage(context.l10n, error);
  }

  String _pageErrorMessage(Object error) {
    if (error is AppException) {
      return downloadActionErrorMessage(context.l10n, error);
    }
    return context.l10n.downloadPageLoadFailedMessage;
  }
}

class _DownloadSnackBarAction {
  const _DownloadSnackBarAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}
