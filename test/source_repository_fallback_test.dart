import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/anime/data/repositories/anime_repository_impl.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime_detail.dart';
import 'package:ani_destiny/features/anime/domain/entities/episode.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:ani_destiny/features/source/domain/adapters/anime_source_adapter.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_result.dart';
import 'package:ani_destiny/features/source/domain/services/source_fallback_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home recommendations use fallback service and mark fallback result',
      () async {
    final service = _PolicyProbeFallbackService(
      adapter: const _FakeAdapter(id: 'mock'),
    );
    final repository = AnimeRepositoryImpl(fallbackService: service);

    final result = await repository.getHomeRecommendations();

    expect(service.operations, ['home']);
    expect(result.usedFallback, isTrue);
    expect(result.sourceId, 'mock');
    expect(result.value.single.sourceId, 'mock');
  });

  test('search empty result is not treated as failure by repository policy',
      () async {
    final service = _PolicyProbeFallbackService(
      adapter: const _FakeAdapter(id: 'sakura', searchResults: []),
    );
    final repository = AnimeRepositoryImpl(fallbackService: service);

    final result = await repository.search('missing');

    expect(result.value, isEmpty);
    expect(service.failurePolicies.single, isNull);
  });

  test('detail with empty episodes is treated as failure', () async {
    final service = _PolicyProbeFallbackService(
      adapter: const _FakeAdapter(
        id: 'sakura',
        detailEpisodes: [],
      ),
    );
    final repository = AnimeRepositoryImpl(fallbackService: service);

    await expectLater(
      repository.getAnimeDetail('anime-1'),
      throwsA(isA<AppException>()),
    );
  });

  test('play sources empty is treated as failure', () async {
    final service = _PolicyProbeFallbackService(
      adapter: const _FakeAdapter(id: 'sakura', playSources: []),
    );
    final repository = AnimeRepositoryImpl(fallbackService: service);

    await expectLater(
      repository.getPlaySources('episode-1'),
      throwsA(isA<AppException>()),
    );
  });
}

class _PolicyProbeFallbackService implements SourceFallbackService {
  _PolicyProbeFallbackService({required this.adapter});

  final AnimeSourceAdapter adapter;
  final operations = <String>[];
  final failurePolicies = <bool Function(Object value)?>[];

  @override
  Future<SourceFallbackResult<T>> run<T>({
    required String operation,
    required Future<T> Function(AnimeSourceAdapter adapter) action,
    String? preferredSourceId,
    bool allowMockFallback = true,
    bool Function(T value)? isFailureValue,
  }) async {
    operations.add(operation);
    failurePolicies.add(
      isFailureValue == null ? null : (value) => isFailureValue(value as T),
    );
    final value = await action(adapter);
    if (isFailureValue?.call(value) ?? false) {
      throw const AppException(
        'No usable data',
        code: 'source_empty_result',
      );
    }
    return SourceFallbackResult<T>(
      value: value,
      sourceId: adapter.id,
      usedFallback: adapter.id == 'mock',
      fromSourceId: adapter.id == 'mock' ? 'sakura' : null,
    );
  }
}

class _FakeAdapter implements AnimeSourceAdapter {
  const _FakeAdapter({
    required this.id,
    this.searchResults = const [
      SearchResult(animeId: 'anime-1', title: 'Result', sourceId: 'sakura'),
    ],
    this.detailEpisodes = const [
      Episode(id: 'episode-1', animeId: 'anime-1', title: 'Episode 1'),
    ],
    this.playSources = const [
      PlaySource(
        id: 'line-1',
        episodeId: 'episode-1',
        title: 'Line 1',
        url: 'https://example.test/video.mp4',
      ),
    ],
  });

  @override
  final String id;

  final List<SearchResult> searchResults;
  final List<Episode> detailEpisodes;
  final List<PlaySource> playSources;

  @override
  String? get description => id;

  @override
  String get name => id;

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async => AnimeDetail(
        id: animeId,
        title: 'Detail',
        episodes: detailEpisodes,
        sourceId: id,
      );

  @override
  Future<List<Anime>> getHomeRecommendations() async => [
        Anime(id: 'anime-1', title: 'Home', sourceId: id),
      ];

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) async =>
      playSources;

  @override
  Future<List<ScheduleItem>> getSchedule() async => [
        ScheduleItem(
          id: 'schedule-1',
          animeId: 'anime-1',
          title: 'Schedule',
          weekday: 1,
          sourceId: id,
        ),
      ];

  @override
  Future<List<SearchResult>> search(String keyword, {int page = 1}) async =>
      searchResults;
}
