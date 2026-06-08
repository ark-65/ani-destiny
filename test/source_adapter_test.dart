import 'package:ani_destiny/features/source/data/adapters/mock_anime_source_adapter.dart';
import 'package:ani_destiny/features/source/data/registry/source_registry.dart';
import 'package:ani_destiny/features/source/data/repositories/source_repository_impl.dart';
import 'package:ani_destiny/features/source/domain/adapters/anime_source_adapter.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime_detail.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('MockAnimeSourceAdapter supports the first-version flow', () async {
    final adapter = MockAnimeSourceAdapter();

    final home = await adapter.getHomeRecommendations();
    expect(home, isNotEmpty);

    final search = await adapter.search('star');
    expect(search, isNotEmpty);

    final detail = await adapter.getAnimeDetail(home.first.id);
    expect(detail.episodes, isNotEmpty);

    final playSources = await adapter.getPlaySources(detail.episodes.first.id);
    expect(playSources.first.url, isNotEmpty);

    final schedule = await adapter.getSchedule();
    expect(schedule, isNotEmpty);
  });

  test('SourceRegistry defaults to the real Sakura source', () {
    final registry = SourceRegistry(
      adapters: [
        MockAnimeSourceAdapter(),
        const _FakeSourceAdapter(id: 'sakura'),
      ],
    );

    expect(registry.defaultAdapter.id, 'sakura');
  });

  test('SourceRepository migrates the old mock default to Sakura', () async {
    SharedPreferences.setMockInitialValues({
      'current_source_id': 'mock',
    });
    final registry = SourceRegistry(
      adapters: [
        MockAnimeSourceAdapter(),
        const _FakeSourceAdapter(id: 'sakura'),
      ],
    );
    final repository = SourceRepositoryImpl(
      registry: registry,
      preferences: SharedPreferences.getInstance,
      allowDebugSources: false,
    );

    expect(await repository.getCurrentSourceId(), 'sakura');
  });

  test('SourceRepository hides mock from release source listings', () {
    final registry = SourceRegistry(
      adapters: [
        MockAnimeSourceAdapter(),
        const _FakeSourceAdapter(id: 'sakura'),
      ],
    );
    final repository = SourceRepositoryImpl(
      registry: registry,
      preferences: SharedPreferences.getInstance,
      allowDebugSources: false,
    );

    expect(
      repository.getSources().map((source) => source.id),
      ['sakura'],
    );
  });

  test('SourceRepository migrates stored mock selection in release mode',
      () async {
    SharedPreferences.setMockInitialValues({
      'current_source_id': 'mock',
      'source_default_version': 3,
    });
    final registry = SourceRegistry(
      adapters: [
        MockAnimeSourceAdapter(),
        const _FakeSourceAdapter(id: 'sakura'),
      ],
    );
    final repository = SourceRepositoryImpl(
      registry: registry,
      preferences: SharedPreferences.getInstance,
      allowDebugSources: false,
    );

    expect(await repository.getCurrentSourceId(), 'sakura');
  });

  test('SourceRepository preserves an explicit source selection', () async {
    SharedPreferences.setMockInitialValues({});
    final registry = SourceRegistry(
      adapters: [
        MockAnimeSourceAdapter(),
        const _FakeSourceAdapter(id: 'sakura'),
      ],
    );
    final repository = SourceRepositoryImpl(
      registry: registry,
      preferences: SharedPreferences.getInstance,
    );

    await repository.setCurrentSourceId('mock');

    expect(await repository.getCurrentSourceId(), 'mock');
  });

  test('SourceRepository rejects selecting mock in release mode', () async {
    SharedPreferences.setMockInitialValues({});
    final registry = SourceRegistry(
      adapters: [
        MockAnimeSourceAdapter(),
        const _FakeSourceAdapter(id: 'sakura'),
      ],
    );
    final repository = SourceRepositoryImpl(
      registry: registry,
      preferences: SharedPreferences.getInstance,
      allowDebugSources: false,
    );

    await expectLater(
      () => repository.setCurrentSourceId('mock'),
      throwsArgumentError,
    );
  });
}

class _FakeSourceAdapter implements AnimeSourceAdapter {
  const _FakeSourceAdapter({required this.id});

  @override
  final String id;

  @override
  String get name => id;

  @override
  String? get description => id;

  @override
  Future<List<Anime>> getHomeRecommendations() async => const [];

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async =>
      throw StateError('Not used in this test');

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) async => const [];

  @override
  Future<List<ScheduleItem>> getSchedule() async => const [];

  @override
  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  }) async =>
      const [];
}
