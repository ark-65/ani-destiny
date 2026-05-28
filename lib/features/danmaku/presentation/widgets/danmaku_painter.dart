import 'package:flutter/material.dart';

import '../../domain/entities/danmaku_item.dart';
import '../../domain/entities/danmaku_settings.dart';

class DanmakuPainter extends CustomPainter {
  DanmakuPainter({
    required this.items,
    required this.position,
    required this.settings,
  });

  final List<DanmakuItem> items;
  final Duration position;
  final DanmakuSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    if (!settings.enabled || items.isEmpty || size.isEmpty) return;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final elapsedMs = (position - item.time).inMilliseconds;
      final progress =
          (elapsedMs / (4200 / settings.speed)).clamp(0.0, 1.0).toDouble();
      final painter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            color: Color(item.color).withValues(alpha: settings.opacity),
            fontSize: settings.fontSize,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final lane = i % 6;
      final y = switch (item.type) {
        DanmakuType.top => 12.0 + lane * (settings.fontSize + 5),
        DanmakuType.bottom =>
          size.height - (lane + 1) * (settings.fontSize + 8) - 8,
        DanmakuType.scroll => 16.0 + lane * (settings.fontSize + 7),
      };
      final x = switch (item.type) {
        DanmakuType.top ||
        DanmakuType.bottom =>
          (size.width - painter.width) / 2,
        DanmakuType.scroll =>
          size.width - progress * (size.width + painter.width + 48),
      };

      painter.paint(canvas, Offset(x, y.clamp(0, size.height - 24).toDouble()));
    }
  }

  @override
  bool shouldRepaint(covariant DanmakuPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.position != position ||
        oldDelegate.settings != settings;
  }
}
