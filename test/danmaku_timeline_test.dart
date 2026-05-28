import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_item.dart';
import 'package:ani_destiny/features/danmaku/domain/services/danmaku_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DanmakuTimeline visibleAt returns items inside the time window', () {
    final timeline = DanmakuTimeline(
      const [
        DanmakuItem(
          id: '1',
          text: 'one',
          time: Duration(seconds: 1),
          color: 0xFFFFFFFF,
          type: DanmakuType.scroll,
        ),
        DanmakuItem(
          id: '2',
          text: 'two',
          time: Duration(seconds: 4),
          color: 0xFFFFFFFF,
          type: DanmakuType.top,
        ),
        DanmakuItem(
          id: '3',
          text: 'three',
          time: Duration(seconds: 9),
          color: 0xFFFFFFFF,
          type: DanmakuType.bottom,
        ),
      ],
    );

    final visible = timeline.visibleAt(const Duration(seconds: 5));

    expect(visible.map((item) => item.id), ['1', '2']);
  });
}
