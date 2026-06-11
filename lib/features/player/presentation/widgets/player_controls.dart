import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/player_state.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    required this.state,
    required this.hasPlayableSource,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeed,
    required this.onNextEpisode,
    required this.onOpenExternalPlayer,
    required this.externalPlayerTooltip,
    required this.downloadTooltip,
    required this.onDownload,
    required this.onToggleDanmaku,
    required this.onToggleFullscreen,
    required this.danmakuEnabled,
    required this.isFullscreen,
    required this.isSwitchingEpisode,
    super.key,
  });

  final PlayerState state;
  final bool hasPlayableSource;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSpeed;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onOpenExternalPlayer;
  final String externalPlayerTooltip;
  final String downloadTooltip;
  final VoidCallback? onDownload;
  final VoidCallback onToggleDanmaku;
  final VoidCallback onToggleFullscreen;
  final bool danmakuEnabled;
  final bool isFullscreen;
  final bool isSwitchingEpisode;

  @override
  Widget build(BuildContext context) {
    final durationMs = state.duration.inMilliseconds;
    final positionMs = state.position.inMilliseconds.clamp(0, durationMs);
    final playbackActionsEnabled = hasPlayableSource && !isSwitchingEpisode;
    final playbackActionTooltip = isSwitchingEpisode
        ? context.l10n.loadingNextEpisode
        : context.l10n.noPlayableSourceFound;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: durationMs == 0 ? 0 : positionMs / durationMs,
              onChanged: playbackActionsEnabled
                  ? (value) {
                      onSeek(
                        Duration(milliseconds: (durationMs * value).round()),
                      );
                    }
                  : null,
            ),
            Row(
              children: [
                IconButton.filled(
                  tooltip: playbackActionsEnabled
                      ? (state.isPlaying
                          ? context.l10n.pause
                          : context.l10n.play)
                      : playbackActionTooltip,
                  onPressed: playbackActionsEnabled ? onPlayPause : null,
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: playbackActionsEnabled
                      ? context.l10n.playbackSpeed
                      : playbackActionTooltip,
                  onPressed: playbackActionsEnabled ? onSpeed : null,
                  icon: const Icon(Icons.speed),
                ),
                if (isFullscreen)
                  IconButton(
                    tooltip: isSwitchingEpisode
                        ? context.l10n.loadingNextEpisode
                        : context.l10n.nextEpisode,
                    onPressed: onNextEpisode,
                    icon: isSwitchingEpisode
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.skip_next),
                  ),
                if (isFullscreen)
                  IconButton(
                    tooltip: externalPlayerTooltip,
                    onPressed: isSwitchingEpisode ? null : onOpenExternalPlayer,
                    icon: const Icon(Icons.open_in_new),
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
                  tooltip: downloadTooltip,
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined),
                ),
                IconButton(
                  tooltip: isFullscreen
                      ? context.l10n.exitFullscreen
                      : context.l10n.enterFullscreen,
                  onPressed: onToggleFullscreen,
                  icon: Icon(
                    isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
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
