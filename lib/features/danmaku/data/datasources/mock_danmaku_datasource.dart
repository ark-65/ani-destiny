import '../../domain/entities/danmaku_item.dart';

class MockDanmakuDataSource {
  Future<List<DanmakuItem>> getDanmaku({
    required String animeId,
    required String episodeId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const [
      DanmakuItem(
        id: 'mock-danmaku-1',
        text: 'AniDestiny first run!',
        time: Duration(seconds: 2),
        color: 0xFFFFFFFF,
        type: DanmakuType.scroll,
        sender: 'mock',
      ),
      DanmakuItem(
        id: 'mock-danmaku-2',
        text: '这集气氛很好',
        time: Duration(seconds: 5),
        color: 0xFFFFD166,
        type: DanmakuType.scroll,
        sender: 'mock',
      ),
      DanmakuItem(
        id: 'mock-danmaku-3',
        text: 'AniDestiny 起航',
        time: Duration(seconds: 8),
        color: 0xFF8BD3FF,
        type: DanmakuType.top,
        sender: 'mock',
      ),
      DanmakuItem(
        id: 'mock-danmaku-4',
        text: 'Mock flow is alive',
        time: Duration(seconds: 12),
        color: 0xFFFFFFFF,
        type: DanmakuType.bottom,
        sender: 'mock',
      ),
      DanmakuItem(
        id: 'mock-danmaku-5',
        text: '下一轮接真实数据源',
        time: Duration(seconds: 16),
        color: 0xFFB8F2C2,
        type: DanmakuType.scroll,
        sender: 'mock',
      ),
    ];
  }
}
