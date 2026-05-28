import 'package:collection/collection.dart';

import '../../../../core/error/app_exception.dart';
import '../../../anime/domain/entities/anime.dart';
import '../../../anime/domain/entities/anime_detail.dart';
import '../../../anime/domain/entities/episode.dart';
import '../../../anime/domain/entities/play_source.dart';
import '../../../anime/domain/entities/schedule_item.dart';
import '../../../anime/domain/entities/search_result.dart';
import '../../domain/adapters/anime_source_adapter.dart';

class MockAnimeSourceAdapter implements AnimeSourceAdapter {
  @override
  String get id => 'mock';

  @override
  String get name => 'Mock Anime Source';

  @override
  String? get description =>
      'Local mock source used to keep AniDestiny runnable.';

  static const _animes = [
    Anime(
      id: 'mock-starlight-voyage',
      title: 'Starlight Voyage',
      originalTitle: '星光航路',
      coverUrl: 'https://picsum.photos/seed/starlight-voyage/480/680',
      description:
          'A drifting academy ship crosses a quiet galaxy while its crew solves weekly mysteries.',
      tags: ['Adventure', 'Sci-Fi', 'School'],
      sourceId: 'mock',
      rating: 8.7,
      year: 2026,
      status: 'Updating',
    ),
    Anime(
      id: 'mock-moonlit-courier',
      title: 'Moonlit Courier',
      originalTitle: '月下信使',
      coverUrl: 'https://picsum.photos/seed/moonlit-courier/480/680',
      description:
          'A night courier carries letters between parallel cities and learns what each world forgot.',
      tags: ['Fantasy', 'Drama'],
      sourceId: 'mock',
      rating: 8.3,
      year: 2025,
      status: 'Completed',
    ),
    Anime(
      id: 'mock-neon-onmyoji',
      title: 'Neon Onmyoji',
      originalTitle: '霓虹阴阳师',
      coverUrl: 'https://picsum.photos/seed/neon-onmyoji/480/680',
      description:
          'Old spells and new circuits collide in a city where spirits ride the subway after midnight.',
      tags: ['Action', 'Urban Fantasy'],
      sourceId: 'mock',
      rating: 8.9,
      year: 2026,
      status: 'Updating',
    ),
    Anime(
      id: 'mock-summer-cache',
      title: 'Summer Cache',
      originalTitle: '夏日缓存',
      coverUrl: 'https://picsum.photos/seed/summer-cache/480/680',
      description:
          'A group of friends discover that their seaside town stores yesterday in an abandoned server.',
      tags: ['Slice of Life', 'Mystery'],
      sourceId: 'mock',
      rating: 8.1,
      year: 2024,
      status: 'Completed',
    ),
  ];

  static const _episodeTitles = [
    'Episode 1 - Departure Signal',
    'Episode 2 - The Quiet Orbit',
    'Episode 3 - Unsent Promise',
    'Episode 4 - Blue Hour',
    'Episode 5 - Tomorrow Cache',
    'Episode 6 - Destiny Rewrites',
  ];

  @override
  Future<List<Anime>> getHomeRecommendations() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _animes;
  }

  @override
  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    return _animes
        .where((anime) {
          final haystack = [
            anime.title,
            anime.originalTitle,
            anime.description,
            ...anime.tags,
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .map(
          (anime) => SearchResult(
            animeId: anime.id,
            title: anime.title,
            coverUrl: anime.coverUrl,
            description: anime.description,
            sourceId: id,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final anime = _animes.where((item) => item.id == animeId).firstOrNull;
    if (anime == null) {
      throw const AppException(
        'Mock anime not found.',
        code: 'mock_anime_not_found',
      );
    }

    return AnimeDetail(
      id: anime.id,
      title: anime.title,
      coverUrl: anime.coverUrl,
      description: anime.description,
      aliases: [
        if (anime.originalTitle != null) anime.originalTitle!,
      ],
      tags: anime.tags,
      sourceId: id,
      episodes: List.generate(
        _episodeTitles.length,
        (index) => Episode(
          id: '${anime.id}-ep-${index + 1}',
          animeId: anime.id,
          title: _episodeTitles[index],
          index: index + 1,
          sourceId: id,
          rawUrl: '/mock/${anime.id}/${index + 1}',
        ),
      ),
    );
  }

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return [
      PlaySource(
        id: '$episodeId-hd',
        episodeId: episodeId,
        title: 'Mock HD',
        url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        quality: 'HD',
      ),
      PlaySource(
        id: '$episodeId-sd',
        episodeId: episodeId,
        title: 'Mock SD',
        url: 'https://test-streams.mux.dev/test_001/stream.m3u8',
        quality: 'SD',
      ),
    ];
  }

  @override
  Future<List<ScheduleItem>> getSchedule() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return [
      for (var i = 0; i < _animes.length; i++)
        ScheduleItem(
          id: 'mock-schedule-$i',
          animeId: _animes[i].id,
          title: _animes[i].title,
          coverUrl: _animes[i].coverUrl,
          weekday: (i % 7) + 1,
          updateTime: '${18 + i}:30',
          sourceId: id,
        ),
    ];
  }
}
