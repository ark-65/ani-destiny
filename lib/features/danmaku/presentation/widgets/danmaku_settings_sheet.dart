import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/danmaku_settings.dart';

class DanmakuSettingsSheet extends StatelessWidget {
  const DanmakuSettingsSheet({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final DanmakuSettings settings;
  final ValueChanged<DanmakuSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.danmaku,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              value: settings.enabled,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) =>
                  onChanged(settings.copyWith(enabled: value)),
              title: Text(context.l10n.enabled),
            ),
            Text(
              context.l10n.opacityPercent(
                (settings.opacity * 100).round(),
              ),
            ),
            Slider(
              value: settings.opacity,
              min: 0.2,
              max: 1,
              onChanged: (value) =>
                  onChanged(settings.copyWith(opacity: value)),
            ),
            Text(context.l10n.fontSize(settings.fontSize.round())),
            Slider(
              value: settings.fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              onChanged: (value) =>
                  onChanged(settings.copyWith(fontSize: value)),
            ),
            Text(context.l10n.speedValue(settings.speed.toStringAsFixed(1))),
            Slider(
              value: settings.speed,
              min: 0.6,
              max: 1.8,
              divisions: 12,
              onChanged: (value) => onChanged(settings.copyWith(speed: value)),
            ),
          ],
        ),
      ),
    );
  }
}
