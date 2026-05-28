import '../entities/danmaku_item.dart';

class DanmakuTimeline {
  DanmakuTimeline(
    List<DanmakuItem> items, {
    this.window = const Duration(seconds: 4),
  }) : _items = [...items]..sort((a, b) => a.time.compareTo(b.time));

  final List<DanmakuItem> _items;
  final Duration window;

  List<DanmakuItem> visibleAt(Duration position) {
    final start = position - window;
    return _items.where((item) {
      return item.time >= start && item.time <= position;
    }).toList(growable: false);
  }
}
