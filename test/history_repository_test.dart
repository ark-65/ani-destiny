import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/history/data/repositories/history_repository_impl.dart';
import 'package:ani_destiny/features/history/domain/entities/watch_history.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HistoryRepository preserves playback resume metadata', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    const headers = {
      'referer': 'https://example.test/vod-play/1/ep1.html',
      'user-agent': 'AniDestiny Test',
    };
    final repository = HistoryRepositoryImpl(database);
    final updatedAt = DateTime(2026, 5, 28, 12, 30);

    await repository.upsert(
      WatchHistory(
        id: 'sakura:1:1/ep1',
        animeId: '1',
        episodeId: '1/ep1',
        animeTitle: 'Sakura Test',
        episodeTitle: '第01集',
        coverUrl: 'https://example.test/cover.jpg',
        sourceId: 'sakura',
        playSourceId: '1/ep1-jyzy',
        playSourceTitle: 'jyzy',
        playUrl: 'https://cdn.example.test/index.m3u8',
        playHeaders: headers,
        position: const Duration(minutes: 3, seconds: 12),
        duration: const Duration(minutes: 24),
        updatedAt: updatedAt,
      ),
    );

    final restored = await repository.getByEpisode('1/ep1');

    expect(restored, isNotNull);
    expect(restored!.sourceId, 'sakura');
    expect(restored.playSourceId, '1/ep1-jyzy');
    expect(restored.playSourceTitle, 'jyzy');
    expect(restored.playUrl, 'https://cdn.example.test/index.m3u8');
    expect(restored.playHeaders, headers);
    expect(restored.position, const Duration(minutes: 3, seconds: 12));
    expect(restored.duration, const Duration(minutes: 24));
    expect(restored.updatedAt, updatedAt);
  });
}
