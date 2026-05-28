import 'package:flutter/material.dart';

import '../../domain/entities/danmaku_item.dart';
import '../../domain/entities/danmaku_settings.dart';
import '../../domain/services/danmaku_timeline.dart';
import 'danmaku_painter.dart';

class DanmakuOverlay extends StatelessWidget {
  const DanmakuOverlay({
    required this.items,
    required this.position,
    required this.settings,
    super.key,
  });

  final List<DanmakuItem> items;
  final Duration position;
  final DanmakuSettings settings;

  @override
  Widget build(BuildContext context) {
    if (!settings.enabled) return const SizedBox.shrink();
    final visible = DanmakuTimeline(items).visibleAt(position);

    return IgnorePointer(
      child: CustomPaint(
        painter: DanmakuPainter(
          items: visible,
          position: position,
          settings: settings,
        ),
        size: Size.infinite,
      ),
    );
  }
}
