import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../download_task_cleanup_state.dart';
import '../../domain/entities/download_failure_reason.dart';
import '../../domain/entities/download_kind.dart';
import '../../domain/entities/download_task.dart';

enum DownloadTaskBusyAction {
  start,
  pause,
  cancel,
  remove,
}

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({
    required this.task,
    required this.isBusy,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
    this.onRefreshCleanupStatus,
    this.manualCleanupBatchRecheckLabel,
    this.manualCleanupReadyActionLabel,
    this.manualCleanupReadyActionIsBatch = false,
    this.busyAction,
    super.key,
  });

  final DownloadTask task;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback? onRefreshCleanupStatus;
  final String? manualCleanupBatchRecheckLabel;
  final String? manualCleanupReadyActionLabel;
  final bool manualCleanupReadyActionIsBatch;
  final DownloadTaskBusyAction? busyAction;

  @override
  Widget build(BuildContext context) {
    final isRemovingFromList = _isRemovingFromList(task);
    final supportNote = _supportNote(context);
    final failureMessage = _failureMessage(context, task);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(
                  task: task,
                  busyAction: busyAction,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(task.episodeTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: _kindLabel(context, task.kind),
                ),
                if (_showFailureReason(task, isRemovingFromList))
                  _InfoChip(
                    icon: Icons.error_outline,
                    label: _failureLabel(context, task.failureReason),
                  ),
              ],
            ),
            if (_showProgress(task, isRemovingFromList)) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: task.progress.clamp(0, 1).toDouble(),
              ),
              const SizedBox(height: 8),
              Text(
                _progressLabel(context, task),
                key: ValueKey('download-task-progress-${task.id}'),
              ),
            ],
            if (failureMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                failureMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            if (_showLocalPath(task)) ...[
              const SizedBox(height: 6),
              Text(
                '${context.l10n.downloadLocalPath}: ${task.localPath}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (supportNote != null)
                  Expanded(
                    child: Text(
                      supportNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  const Spacer(),
                if (isBusy) ...[
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      key: ValueKey('download-task-busy-${task.id}'),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ..._actions(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _supportNote(BuildContext context) {
    if (_isRemovingFromList(task)) {
      return task.status == DownloadStatus.unsupported
          ? context.l10n.downloadRemovingListOnlyNote
          : context.l10n.downloadRemovingNote;
    }
    return switch (task.status) {
      DownloadStatus.pending => context.l10n.downloadPendingNote,
      DownloadStatus.preparing => context.l10n.downloadPreparingNote,
      DownloadStatus.paused
          when task.kind == DownloadKind.directFile &&
              busyAction == DownloadTaskBusyAction.pause =>
        context.l10n.downloadStoppingNote,
      DownloadStatus.canceled
          when task.kind == DownloadKind.directFile &&
              busyAction == DownloadTaskBusyAction.cancel =>
        context.l10n.downloadDiscardingNote,
      DownloadStatus.downloading when task.kind == DownloadKind.directFile =>
        context.l10n.downloadStopMayRestartNote,
      DownloadStatus.paused when task.kind == DownloadKind.directFile =>
        context.l10n.downloadPausedRetryNote,
      DownloadStatus.failed => context.l10n.downloadFailedRetryOrRemoveNote,
      DownloadStatus.canceled when task.kind == DownloadKind.directFile =>
        downloadTaskNeedsManualCleanup(task)
            ? context.l10n.downloadDiscardedNeedsManualCleanupGuidance(
                readyActionLabel: manualCleanupReadyActionLabel,
                readyActionIsBatch: manualCleanupReadyActionIsBatch,
                recheckActionLabel: manualCleanupBatchRecheckLabel,
              )
            : context.l10n.downloadDiscardedNote,
      DownloadStatus.unsupported => context.l10n.downloadUnsupportedRemoveNote,
      DownloadStatus.completed when _showLocalPath(task) =>
        context.l10n.downloadRemoveKeepsFileNote,
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.failed ||
      DownloadStatus.canceled ||
      DownloadStatus.downloading ||
      DownloadStatus.paused ||
      DownloadStatus.completed =>
        null,
    };
  }

  bool _showFailureReason(DownloadTask task, bool isRemovingFromList) {
    if (isRemovingFromList) {
      return false;
    }
    if (task.failureReason == DownloadFailureReason.unsupportedType) {
      return false;
    }
    return task.failureReason != DownloadFailureReason.none &&
        task.status != DownloadStatus.canceled;
  }

  bool _showLocalPath(DownloadTask task) {
    return downloadTaskShowsLocalPath(task);
  }

  String? _failureMessage(BuildContext context, DownloadTask task) {
    if (_isRemovingFromList(task)) {
      return null;
    }
    if (task.status == DownloadStatus.canceled) {
      return null;
    }
    if (task.failureReason == DownloadFailureReason.unsupportedType) {
      return switch (task.kind) {
        DownloadKind.hls => context.l10n.downloadUnsupportedHlsMessage,
        DownloadKind.bt => context.l10n.downloadUnsupportedBtMessage,
        DownloadKind.unknown => context.l10n.downloadUnsupportedUnknownMessage,
        DownloadKind.directFile => task.failureMessage,
      };
    }
    return task.failureMessage;
  }

  bool _showProgress(DownloadTask task, bool isRemovingFromList) {
    if (isRemovingFromList) {
      return false;
    }
    if (task.status == DownloadStatus.canceled) {
      return false;
    }
    if (task.status == DownloadStatus.pending ||
        task.status == DownloadStatus.preparing) {
      return false;
    }
    if (task.status == DownloadStatus.unsupported) {
      return false;
    }
    if (task.status == DownloadStatus.paused &&
        task.kind == DownloadKind.directFile) {
      return false;
    }
    return true;
  }

  bool _isRemovingFromList(DownloadTask task) {
    if (busyAction != DownloadTaskBusyAction.remove) {
      return false;
    }
    return switch (task.status) {
      DownloadStatus.completed ||
      DownloadStatus.failed ||
      DownloadStatus.unsupported =>
        true,
      DownloadStatus.canceled => !downloadTaskNeedsManualCleanup(task),
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.downloading ||
      DownloadStatus.paused =>
        false,
    };
  }

  List<Widget> _actions(BuildContext context) {
    return switch (task.status) {
      DownloadStatus.pending => [
          IconButton(
            key: ValueKey('download-task-start-${task.id}'),
            tooltip: context.l10n.start,
            onPressed: isBusy ? null : onStart,
            icon: const Icon(Icons.play_arrow),
          ),
          _discardTextAction(context),
        ],
      DownloadStatus.preparing => [
          _discardTextAction(context),
        ],
      DownloadStatus.downloading => [
          IconButton(
            key: ValueKey('download-task-pause-${task.id}'),
            tooltip: context.l10n.stopForNow,
            onPressed: isBusy ? null : onPause,
            icon: const Icon(Icons.stop_circle_outlined),
          ),
          _discardTextAction(context),
        ],
      DownloadStatus.paused => [
          IconButton(
            key: ValueKey('download-task-retry-${task.id}'),
            tooltip: context.l10n.retry,
            onPressed: isBusy ? null : onStart,
            icon: const Icon(Icons.refresh),
          ),
          _discardTextAction(context),
        ],
      DownloadStatus.failed => [
          IconButton(
            key: ValueKey('download-task-retry-${task.id}'),
            tooltip: context.l10n.retry,
            onPressed: isBusy ? null : onStart,
            icon: const Icon(Icons.refresh),
          ),
          _removeTextAction(context),
        ],
      DownloadStatus.completed => [
          _removeTextAction(context),
        ],
      DownloadStatus.unsupported => [
          _removeTextAction(context),
        ],
      DownloadStatus.canceled => downloadTaskNeedsManualCleanup(task)
          ? [
              TextButton.icon(
                key: ValueKey('download-task-refresh-cleanup-${task.id}'),
                onPressed: isBusy ? null : onRefreshCleanupStatus,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.l10n.checkAgain),
              ),
            ]
          : [
              _removeTextAction(context),
            ],
    };
  }

  Widget _removeTextAction(BuildContext context) {
    return Tooltip(
      message: context.l10n.removeFromList,
      child: TextButton.icon(
        key: ValueKey('download-task-remove-${task.id}'),
        onPressed: isBusy ? null : onRemove,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: Text(context.l10n.removeFromList),
      ),
    );
  }

  Widget _discardTextAction(BuildContext context) {
    return Tooltip(
      message: context.l10n.downloadDiscardTooltip,
      child: TextButton.icon(
        key: ValueKey('download-task-cancel-${task.id}'),
        onPressed: isBusy ? null : onCancel,
        icon: const Icon(Icons.close, size: 18),
        label: Text(context.l10n.downloadDiscardTooltip),
      ),
    );
  }

  String _progressLabel(BuildContext context, DownloadTask task) {
    final clampedProgress = task.progress.clamp(0.0, 1.0).toDouble();
    final percent = '${(clampedProgress * 100).round()}%';
    final totalBytes = task.totalBytes;
    if (totalBytes == null || totalBytes <= 0) {
      return '${context.l10n.downloadProgress}: $percent';
    }
    return '${context.l10n.downloadProgress}: $percent · '
        '${_formatBytes(task.downloadedBytes)} / ${_formatBytes(totalBytes)}';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _kindLabel(BuildContext context, DownloadKind kind) {
    return switch (kind) {
      DownloadKind.directFile => context.l10n.downloadKindDirectFile,
      DownloadKind.hls => context.l10n.downloadKindHls,
      DownloadKind.bt => context.l10n.downloadKindBt,
      DownloadKind.unknown => context.l10n.downloadKindUnknown,
    };
  }

  String _failureLabel(BuildContext context, DownloadFailureReason reason) {
    return switch (reason) {
      DownloadFailureReason.none => '',
      DownloadFailureReason.unsupportedType =>
        context.l10n.downloadFailureUnsupportedType,
      DownloadFailureReason.permissionDenied =>
        context.l10n.downloadFailurePermissionDenied,
      DownloadFailureReason.networkError =>
        context.l10n.downloadFailureNetworkError,
      DownloadFailureReason.sourceUnavailable =>
        context.l10n.downloadFailureSourceUnavailable,
      DownloadFailureReason.invalidUrl =>
        context.l10n.downloadFailureInvalidUrl,
      DownloadFailureReason.invalidManifest =>
        context.l10n.downloadFailureInvalidManifest,
      DownloadFailureReason.storageUnavailable =>
        context.l10n.downloadFailureStorageUnavailable,
      DownloadFailureReason.canceled => context.l10n.canceled,
      DownloadFailureReason.unknown => context.l10n.downloadFailureUnknown,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.task,
    this.busyAction,
  });

  final DownloadTask task;
  final DownloadTaskBusyAction? busyAction;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label(context, task)),
      visualDensity: VisualDensity.compact,
    );
  }

  String _label(BuildContext context, DownloadTask task) {
    if (downloadTaskNeedsManualCleanup(task)) {
      return context.l10n.downloadManualCleanupStatus;
    }
    if (_isRemovingFromList(task)) {
      return context.l10n.downloadRemovingStatus;
    }
    return switch (task.status) {
      DownloadStatus.pending => context.l10n.pending,
      DownloadStatus.preparing => context.l10n.preparing,
      DownloadStatus.downloading => context.l10n.downloading,
      DownloadStatus.paused when busyAction == DownloadTaskBusyAction.pause =>
        context.l10n.downloadStoppingStatus,
      DownloadStatus.paused => context.l10n.downloadStoppedStatus,
      DownloadStatus.completed => context.l10n.completed,
      DownloadStatus.failed => context.l10n.failed,
      DownloadStatus.canceled
          when busyAction == DownloadTaskBusyAction.cancel =>
        context.l10n.downloadDiscardingStatus,
      DownloadStatus.canceled => context.l10n.downloadDiscardedStatus,
      DownloadStatus.unsupported => context.l10n.unsupported,
    };
  }

  bool _isRemovingFromList(DownloadTask task) {
    if (busyAction != DownloadTaskBusyAction.remove) {
      return false;
    }
    return switch (task.status) {
      DownloadStatus.completed ||
      DownloadStatus.failed ||
      DownloadStatus.unsupported =>
        true,
      DownloadStatus.canceled => !downloadTaskNeedsManualCleanup(task),
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.downloading ||
      DownloadStatus.paused =>
        false,
    };
  }
}
