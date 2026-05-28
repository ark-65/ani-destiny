import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/player_state.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeed,
    required this.onDownload,
    required this.onToggleDanmaku,
    required this.danmakuEnabled,
    super.key,
  });

  final PlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSpeed;
  final VoidCallback onDownload;
  final VoidCallback onToggleDanmaku;
  final bool danmakuEnabled;

  @override
  Widget build(BuildContext context) {
    final durationMs = state.duration.inMilliseconds;
    final positionMs = state.position.inMilliseconds.clamp(0, durationMs);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: durationMs == 0 ? 0 : positionMs / durationMs,
              onChanged: (value) {
                onSeek(Duration(milliseconds: (durationMs * value).round()));
              },
            ),
            Row(
              children: [
                IconButton.filled(
                  tooltip:
                      state.isPlaying ? context.l10n.pause : context.l10n.play,
                  onPressed: onPlayPause,
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.playbackSpeed,
                  onPressed: onSpeed,
                  icon: const Icon(Icons.speed),
                ),
                IconButton(
                  tooltip: danmakuEnabled
                      ? context.l10n.hideDanmaku
                      : context.l10n.showDanmaku,
                  onPressed: onToggleDanmaku,
                  icon: Icon(
                    danmakuEnabled
                        ? Icons.subtitles
                        : Icons.subtitles_off_outlined,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.download,
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined),
                ),
                IconButton(
                  tooltip: context.l10n.fullscreenPlaceholder,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.fullscreenNotImplemented),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
