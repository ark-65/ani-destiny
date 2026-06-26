import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/download_failure_reason.dart';
import '../../domain/entities/download_kind.dart';
import '../../domain/entities/download_task.dart';

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({
    required this.task,
    required this.isBusy,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
    super.key,
  });

  final DownloadTask task;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final supportNote = _supportNote(context);

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
                _StatusChip(status: task.status),
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
                if (_showFailureReason(task))
                  _InfoChip(
                    icon: Icons.error_outline,
                    label: _failureLabel(context, task.failureReason),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: task.progress.clamp(0, 1).toDouble(),
            ),
            const SizedBox(height: 8),
            Text(
              _progressLabel(context, task),
              key: ValueKey('download-task-progress-${task.id}'),
            ),
            if (_showFailureMessage(task)) ...[
              const SizedBox(height: 6),
              Text(
                task.failureMessage!,
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
    return switch (task.status) {
      DownloadStatus.downloading when task.kind == DownloadKind.directFile =>
        context.l10n.downloadStopMayRestartNote,
      DownloadStatus.paused when task.kind == DownloadKind.directFile =>
        context.l10n.downloadPausedRetryNote,
      DownloadStatus.canceled when task.kind == DownloadKind.directFile =>
        task.localPath == null
            ? context.l10n.downloadDiscardedNote
            : context.l10n.downloadDiscardedNeedsManualCleanupNote,
      DownloadStatus.completed when _showLocalPath(task) =>
        context.l10n.downloadRemoveKeepsFileNote,
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.failed ||
      DownloadStatus.canceled ||
      DownloadStatus.unsupported ||
      DownloadStatus.downloading ||
      DownloadStatus.paused ||
      DownloadStatus.completed =>
        null,
    };
  }

  bool _showFailureReason(DownloadTask task) {
    return task.failureReason != DownloadFailureReason.none &&
        task.status != DownloadStatus.canceled;
  }

  bool _showFailureMessage(DownloadTask task) {
    return task.failureMessage != null &&
        task.status != DownloadStatus.canceled;
  }

  bool _showLocalPath(DownloadTask task) {
    return task.localPath != null &&
        (task.status == DownloadStatus.completed ||
            task.status == DownloadStatus.canceled);
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
          IconButton(
            key: ValueKey('download-task-cancel-${task.id}'),
            tooltip: context.l10n.downloadDiscardTooltip,
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.preparing => [
          IconButton(
            key: ValueKey('download-task-cancel-${task.id}'),
            tooltip: context.l10n.downloadDiscardTooltip,
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.downloading => [
          IconButton(
            key: ValueKey('download-task-pause-${task.id}'),
            tooltip: context.l10n.stopForNow,
            onPressed: isBusy ? null : onPause,
            icon: const Icon(Icons.stop_circle_outlined),
          ),
          IconButton(
            key: ValueKey('download-task-cancel-${task.id}'),
            tooltip: context.l10n.downloadDiscardTooltip,
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.paused => [
          IconButton(
            key: ValueKey('download-task-retry-${task.id}'),
            tooltip: context.l10n.retry,
            onPressed: isBusy ? null : onStart,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            key: ValueKey('download-task-cancel-${task.id}'),
            tooltip: context.l10n.downloadDiscardTooltip,
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.failed => [
          IconButton(
            key: ValueKey('download-task-retry-${task.id}'),
            tooltip: context.l10n.retry,
            onPressed: isBusy ? null : onStart,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            key: ValueKey('download-task-remove-${task.id}'),
            tooltip: context.l10n.removeFromList,
            onPressed: isBusy ? null : onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      DownloadStatus.completed || DownloadStatus.unsupported => [
          IconButton(
            key: ValueKey('download-task-remove-${task.id}'),
            tooltip: context.l10n.removeFromList,
            onPressed: isBusy ? null : onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      DownloadStatus.canceled => _requiresManualCleanupBeforeRemoval(task)
          ? const <Widget>[]
          : [
              IconButton(
                key: ValueKey('download-task-remove-${task.id}'),
                tooltip: context.l10n.removeFromList,
                onPressed: isBusy ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
    };
  }

  bool _requiresManualCleanupBeforeRemoval(DownloadTask task) {
    return task.status == DownloadStatus.canceled && task.localPath != null;
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
  const _StatusChip({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label(context, status)),
      visualDensity: VisualDensity.compact,
    );
  }

  String _label(BuildContext context, DownloadStatus status) {
    return switch (status) {
      DownloadStatus.pending => context.l10n.pending,
      DownloadStatus.preparing => context.l10n.preparing,
      DownloadStatus.downloading => context.l10n.downloading,
      DownloadStatus.paused => context.l10n.downloadStoppedStatus,
      DownloadStatus.completed => context.l10n.completed,
      DownloadStatus.failed => context.l10n.failed,
      DownloadStatus.canceled => context.l10n.canceled,
      DownloadStatus.unsupported => context.l10n.unsupported,
    };
  }
}
