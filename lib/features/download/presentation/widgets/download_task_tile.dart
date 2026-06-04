import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/download_failure_reason.dart';
import '../../domain/entities/download_kind.dart';
import '../../domain/entities/download_task.dart';

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({
    required this.task,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    required this.onRemove,
    super.key,
  });

  final DownloadTask task;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
                if (task.failureReason != DownloadFailureReason.none)
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
            Text(_progressLabel(context, task)),
            if (task.failureMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                task.failureMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            if (task.localPath != null) ...[
              const SizedBox(height: 6),
              Text(
                '${context.l10n.downloadLocalPath}: ${task.localPath}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (_showPauseNote(task))
                  Expanded(
                    child: Text(
                      context.l10n.downloadBasicPauseNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  const Spacer(),
                ..._actions(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _showPauseNote(DownloadTask task) {
    return task.kind == DownloadKind.directFile &&
        switch (task.status) {
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.downloading ||
      DownloadStatus.paused =>
        true,
      DownloadStatus.failed ||
      DownloadStatus.completed ||
      DownloadStatus.canceled ||
      DownloadStatus.unsupported =>
            false,
        };
  }

  List<Widget> _actions(BuildContext context) {
    return switch (task.status) {
      DownloadStatus.pending => [
          IconButton(
            tooltip: context.l10n.start,
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.preparing => [
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.downloading => [
          IconButton(
            tooltip: context.l10n.pause,
            onPressed: onPause,
            icon: const Icon(Icons.pause),
          ),
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.paused => [
          IconButton(
            tooltip: context.l10n.start,
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      DownloadStatus.failed => [
          IconButton(
            tooltip: context.l10n.retry,
            onPressed: onStart,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: context.l10n.remove,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      DownloadStatus.completed ||
      DownloadStatus.unsupported ||
      DownloadStatus.canceled =>
        [
          IconButton(
            tooltip: context.l10n.remove,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
    };
  }

  String _progressLabel(BuildContext context, DownloadTask task) {
    final percent = '${(task.progress * 100).round()}%';
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
      DownloadStatus.paused => context.l10n.paused,
      DownloadStatus.completed => context.l10n.completed,
      DownloadStatus.failed => context.l10n.failed,
      DownloadStatus.canceled => context.l10n.canceled,
      DownloadStatus.unsupported => context.l10n.unsupported,
    };
  }
}
