import 'package:collection/collection.dart';

import '../../domain/entities/danmaku_item.dart';
import '../../domain/entities/danmaku_match.dart';
import '../../domain/repositories/danmaku_repository.dart';
import '../datasources/dandanplay_danmaku_datasource.dart';
import '../datasources/mock_danmaku_datasource.dart';

class DanmakuRepositoryImpl implements DanmakuRepository {
  const DanmakuRepositoryImpl({
    required DandanplayDanmakuDataSource dandanplayDataSource,
    required MockDanmakuDataSource mockDataSource,
  })  : _dandanplayDataSource = dandanplayDataSource,
        _mockDataSource = mockDataSource;

  final DandanplayDanmakuDataSource _dandanplayDataSource;
  final MockDanmakuDataSource _mockDataSource;

  @override
  Future<List<DanmakuItem>> getDanmaku({
    required String animeId,
    required String episodeId,
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  }) async {
    try {
      final matches = await _dandanplayDataSource.match(
        animeTitle: animeTitle,
        episodeTitle: episodeTitle,
        episodeIndex: episodeIndex,
      );
      final bestMatch = _bestMatch(matches);
      if (bestMatch != null) {
        final comments = await _dandanplayDataSource.getComments(
          matchId: bestMatch.id,
        );
        if (comments.isNotEmpty) return comments;
      }
    } on Object {
      // Playback must not fail when the external danmaku service is unavailable.
    }

    return _mockDataSource.getDanmaku(
      animeId: animeId,
      episodeId: episodeId,
    );
  }

  DanmakuMatch? _bestMatch(List<DanmakuMatch> matches) {
    return matches.sortedBy<num>((match) => -(match.score ?? 0)).firstOrNull;
  }
}
