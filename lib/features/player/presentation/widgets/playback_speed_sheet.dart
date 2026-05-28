import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/playback_speed.dart';

class PlaybackSpeedSheet extends StatelessWidget {
  const PlaybackSpeedSheet({
    required this.currentSpeed,
    required this.onSelected,
    super.key,
  });

  final double currentSpeed;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            context.l10n.playbackSpeed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioGroup<double>(
            groupValue: currentSpeed,
            onChanged: (value) {
              if (value == null) return;
              Navigator.of(context).pop();
              onSelected(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final speed in PlaybackSpeed.all)
                  RadioListTile<double>(
                    value: speed.value,
                    title: Text(speed.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
