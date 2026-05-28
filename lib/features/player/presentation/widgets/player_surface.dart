import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../data/adapters/media_kit_player_adapter.dart';
import '../../domain/adapters/player_controller_adapter.dart';

class PlayerSurface extends StatelessWidget {
  const PlayerSurface({
    required this.controller,
    required this.title,
    required this.playUrl,
    super.key,
  });

  final PlayerControllerAdapter controller;
  final String title;
  final String playUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final controller = this.controller;
    if (controller is MediaKitPlayerAdapter) {
      return ColoredBox(
        color: Colors.black,
        child: Video(
          controller: controller.videoController,
          controls: null,
          fit: BoxFit.contain,
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                color: colors.primary,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                playUrl.isEmpty
                    ? context.l10n.playerNoPlayUrl
                    : context.l10n.playerMockReady,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
