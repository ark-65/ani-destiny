import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/watch_history.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    required this.history,
    required this.onContinue,
    required this.onDelete,
    super.key,
  });

  final WatchHistory history;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = history.duration == null ||
            history.duration == Duration.zero
        ? 0.0
        : history.position.inMilliseconds / history.duration!.inMilliseconds;

    return ListTile(
      onTap: onContinue,
      leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
      title: Text(history.animeTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(history.episodeTitle),
          if (history.playSourceTitle != null) ...[
            const SizedBox(height: 2),
            Text(history.playSourceTitle!),
          ],
          const SizedBox(height: 2),
          Text(_formatPosition(history.position)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress.clamp(0, 1).toDouble()),
        ],
      ),
      trailing: IconButton(
        tooltip: context.l10n.deleteHistory,
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }

  String _formatPosition(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
