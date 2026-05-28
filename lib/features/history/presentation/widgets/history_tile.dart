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
}
