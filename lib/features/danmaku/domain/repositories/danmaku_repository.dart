import '../entities/danmaku_item.dart';

abstract class DanmakuRepository {
  Future<List<DanmakuItem>> getDanmaku({
    required String animeId,
    required String episodeId,
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  });
}
