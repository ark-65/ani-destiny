import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/download_task.dart';

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({
    required this.task,
    required this.onStart,
    required this.onPause,
    required this.onCancel,
    super.key,
  });

  final DownloadTask task;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCancel;

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
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: task.progress.clamp(0, 1).toDouble(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${(task.progress * 100).round()}%'),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.start,
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                ),
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
            ),
          ],
        ),
      ),
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
      DownloadStatus.queued => context.l10n.queued,
      DownloadStatus.running => context.l10n.running,
      DownloadStatus.paused => context.l10n.paused,
      DownloadStatus.completed => context.l10n.completed,
      DownloadStatus.failed => context.l10n.failed,
      DownloadStatus.canceled => context.l10n.canceled,
    };
  }
}
