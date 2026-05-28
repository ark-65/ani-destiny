enum DanmakuType {
  scroll,
  top,
  bottom,
}

class DanmakuItem {
  const DanmakuItem({
    required this.id,
    required this.text,
    required this.time,
    required this.color,
    required this.type,
    this.sender,
    this.source,
  });

  final String id;
  final String text;
  final Duration time;
  final int color;
  final DanmakuType type;
  final String? sender;
  final String? source;
}
