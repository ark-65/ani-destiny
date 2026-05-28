import 'package:ani_destiny/features/danmaku/data/datasources/dandanplay_danmaku_datasource.dart';
import 'package:ani_destiny/features/danmaku/data/datasources/mock_danmaku_datasource.dart';
import 'package:ani_destiny/features/danmaku/data/repositories/danmaku_repository_impl.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_item.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DanmakuRepository returns Dandanplay comments when available',
      () async {
    final repository = DanmakuRepositoryImpl(
      dandanplayDataSource: const _FakeDandanplayDataSource(
        matches: [
          DanmakuMatch(
            id: 'low',
            animeTitle: '火影忍者',
            episodeTitle: '第2话',
            score: 1,
          ),
          DanmakuMatch(
            id: 'best',
            animeTitle: '火影忍者',
            episodeTitle: '第1话',
            score: 2,
          ),
        ],
        commentsByMatchId: {
          'best': [
            DanmakuItem(
              id: 'real-1',
              text: '真实弹幕',
              time: Duration(seconds: 1),
              color: 0xFFFFFFFF,
              type: DanmakuType.scroll,
              source: 'dandanplay',
            ),
          ],
        },
      ),
      mockDataSource: MockDanmakuDataSource(),
    );

    final items = await repository.getDanmaku(
      animeId: 'anime',
      episodeId: 'episode',
      animeTitle: '火影忍者',
      episodeTitle: '第01集',
      episodeIndex: 1,
    );

    expect(items.single.source, 'dandanplay');
    expect(items.single.text, '真实弹幕');
  });

  test('DanmakuRepository falls back to mock when match fails', () async {
    final repository = DanmakuRepositoryImpl(
      dandanplayDataSource: const _FakeDandanplayDataSource(
        throwOnMatch: true,
      ),
      mockDataSource: MockDanmakuDataSource(),
    );

    final items = await repository.getDanmaku(
      animeId: 'anime',
      episodeId: 'episode',
      animeTitle: '火影忍者',
      episodeTitle: '第01集',
    );

    expect(items, isNotEmpty);
    expect(items.every((item) => item.source == 'mock'), isTrue);
  });

  test('DanmakuRepository falls back to mock when comments are empty',
      () async {
    final repository = DanmakuRepositoryImpl(
      dandanplayDataSource: const _FakeDandanplayDataSource(
        matches: [
          DanmakuMatch(
            id: 'empty',
            animeTitle: '火影忍者',
            episodeTitle: '第1话',
            score: 1,
          ),
        ],
      ),
      mockDataSource: MockDanmakuDataSource(),
    );

    final items = await repository.getDanmaku(
      animeId: 'anime',
      episodeId: 'episode',
      animeTitle: '火影忍者',
      episodeTitle: '第01集',
    );

    expect(items, isNotEmpty);
    expect(items.first.source, 'mock');
  });
}

class _FakeDandanplayDataSource implements DandanplayDanmakuDataSource {
  const _FakeDandanplayDataSource({
    this.matches = const [],
    this.commentsByMatchId = const {},
    this.throwOnMatch = false,
  });

  final List<DanmakuMatch> matches;
  final Map<String, List<DanmakuItem>> commentsByMatchId;
  final bool throwOnMatch;

  @override
  Future<List<DanmakuMatch>> match({
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  }) async {
    if (throwOnMatch) throw StateError('match failed');
    return matches;
  }

  @override
  Future<List<DanmakuItem>> getComments({required String matchId}) async {
    return commentsByMatchId[matchId] ?? const [];
  }
}
