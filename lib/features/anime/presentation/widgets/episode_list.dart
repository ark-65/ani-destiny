import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/episode.dart';

class EpisodeList extends StatelessWidget {
  const EpisodeList({
    required this.episodes,
    required this.onPlay,
    required this.onDownload,
    this.focusEpisodeId,
    super.key,
  });

  final List<Episode> episodes;
  final ValueChanged<Episode> onPlay;
  final ValueChanged<Episode> onDownload;
  final String? focusEpisodeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.episodes,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final episode in episodes)
          Builder(
            builder: (context) {
              final isFocusedEpisode =
                  focusEpisodeId != null && episode.id == focusEpisodeId;
              return Card(
                color: isFocusedEpisode
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                child: ListTile(
                  onTap: () => onPlay(episode),
                  selected: isFocusedEpisode,
                  leading: CircleAvatar(
                    child: Text('${episode.index ?? 0}'),
                  ),
                  title: Text(episode.title),
                  subtitle: Text(
                    context.l10n.sourceDisplayName(
                      episode.sourceId ?? AppConstants.defaultSourceId,
                      episode.sourceId ?? AppConstants.defaultSourceId,
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: context.l10n.checkDownloadLines,
                        onPressed: () => onDownload(episode),
                        icon: const Icon(Icons.download_outlined),
                      ),
                      IconButton.filledTonal(
                        tooltip: context.l10n.play,
                        onPressed: () => onPlay(episode),
                        icon: const Icon(Icons.play_arrow),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
