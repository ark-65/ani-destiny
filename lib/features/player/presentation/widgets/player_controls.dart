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
    required this.isOpeningExternalPlayer,
    this.isRetryingPlayback = false,
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
  final VoidCallback? onToggleFullscreen;
  final bool danmakuEnabled;
  final bool isFullscreen;
  final bool isSwitchingEpisode;
  final bool isOpeningExternalPlayer;
  final bool isRetryingPlayback;

  @override
  Widget build(BuildContext context) {
    final isInteractionLocked =
        isSwitchingEpisode || isOpeningExternalPlayer || isRetryingPlayback;
    final displayedDuration =
        isSwitchingEpisode ? Duration.zero : state.duration;
    final displayedPosition =
        isSwitchingEpisode ? Duration.zero : state.position;
    final durationMs = displayedDuration.inMilliseconds;
    final positionMs = displayedPosition.inMilliseconds.clamp(0, durationMs);
    final playbackActionsEnabled = hasPlayableSource &&
        !isInteractionLocked &&
        state.errorMessage == null &&
        state.isInitialized;
    final playbackActionTooltip = isSwitchingEpisode
        ? context.l10n.loadingNextEpisode
        : isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : isRetryingPlayback
                ? context.l10n.retryingPlayback
                : !hasPlayableSource
                    ? context.l10n.noPlayableSourceFound
                    : state.errorMessage != null
                        ? context.l10n.playbackFailedSuggestion
                        : context.l10n.playerPreparingPlayback;
    final nextEpisodeTooltip = isSwitchingEpisode
        ? context.l10n.loadingNextEpisode
        : isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : isRetryingPlayback
                ? context.l10n.retryingPlayback
                : context.l10n.nextEpisode;
    final resolvedDownloadTooltip = isOpeningExternalPlayer
        ? context.l10n.openingExternalPlayer
        : isRetryingPlayback
            ? context.l10n.retryingPlayback
            : downloadTooltip;
    final danmakuTooltip = isSwitchingEpisode
        ? context.l10n.loadingNextEpisode
        : isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : isRetryingPlayback
                ? context.l10n.retryingPlayback
                : danmakuEnabled
                    ? context.l10n.hideDanmaku
                    : context.l10n.showDanmaku;
    final canEnterFullscreen =
        hasPlayableSource && state.errorMessage == null && state.isInitialized;
    final canToggleFullscreen = isFullscreen
        ? !isInteractionLocked
        : !isInteractionLocked && canEnterFullscreen;
    final fullscreenTooltip = isSwitchingEpisode
        ? context.l10n.loadingNextEpisode
        : isOpeningExternalPlayer
            ? context.l10n.openingExternalPlayer
            : isRetryingPlayback
                ? context.l10n.retryingPlayback
                : isFullscreen
                    ? context.l10n.exitFullscreen
                    : !hasPlayableSource
                        ? context.l10n.noPlayableSourceFound
                        : state.errorMessage != null
                            ? context.l10n.playbackFailedSuggestion
                            : !state.isInitialized
                                ? context.l10n.playerPreparingPlayback
                                : context.l10n.enterFullscreen;

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
                Expanded(
                  child: Text(
                    isSwitchingEpisode
                        ? '--:-- / --:--'
                        : '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: playbackActionsEnabled
                      ? context.l10n.playbackSpeed
                      : playbackActionTooltip,
                  onPressed: playbackActionsEnabled ? onSpeed : null,
                  icon: const Icon(Icons.speed),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isFullscreen)
                    IconButton(
                      tooltip: nextEpisodeTooltip,
                      onPressed: isInteractionLocked ? null : onNextEpisode,
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
                      onPressed: isSwitchingEpisode || isOpeningExternalPlayer
                          ? null
                          : onOpenExternalPlayer,
                      icon: isOpeningExternalPlayer
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new),
                    ),
                  IconButton(
                    tooltip: danmakuTooltip,
                    onPressed: isInteractionLocked ? null : onToggleDanmaku,
                    icon: Icon(
                      danmakuEnabled
                          ? Icons.subtitles
                          : Icons.subtitles_off_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: resolvedDownloadTooltip,
                    onPressed: isInteractionLocked ? null : onDownload,
                    icon: const Icon(Icons.download_outlined),
                  ),
                  IconButton(
                    tooltip: fullscreenTooltip,
                    onPressed: canToggleFullscreen ? onToggleFullscreen : null,
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
