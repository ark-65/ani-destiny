import 'package:ani_destiny/app/router.dart';
import 'package:ani_destiny/core/constants/app_constants.dart';
import 'package:ani_destiny/features/player/data/adapters/mock_player_adapter.dart';
import 'package:ani_destiny/features/player/domain/entities/player_route_args.dart';
import 'package:ani_destiny/features/player/domain/services/next_episode_navigation.dart';
import 'package:ani_destiny/features/player/domain/services/playback_diagnostics.dart';
import 'package:ani_destiny/features/anime/domain/entities/episode.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlayerRouteArgs carries playback headers and source metadata', () {
    const args = PlayerRouteArgs(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      animeTitle: 'Anime',
      episodeTitle: 'Episode 1',
      playUrl: 'https://cdn.example.test/video.m3u8?token=secret',
      sourceId: 'sakura',
      playSourceId: 'line-1',
      playSourceTitle: 'Line 1',
      playHeaders: {
        'Referer': 'https://example.test/player',
        'User-Agent': 'AniDestinyTest',
      },
      episodeIndex: 1,
    );

    expect(args.sourceId, 'sakura');
    expect(args.playSourceId, 'line-1');
    expect(args.playHeaders['Referer'], contains('example.test'));
    expect(args.episodeIndex, 1);
  });

  test('player route falls back to the app default source', () {
    final args = playerRouteArgsFromUri(
      Uri.parse(
        'https://anidestiny.test/player?animeId=anime-1&episodeId=episode-1&playUrl=https%3A%2F%2Fcdn.example.test%2Fvideo.m3u8',
      ),
    );

    expect(args.sourceId, AppConstants.defaultSourceId);
    expect(args.animeId, 'anime-1');
    expect(args.episodeId, 'episode-1');
  });

  test('MockPlayerAdapter load stores URL and headers for verification',
      () async {
    final adapter = MockPlayerAdapter();

    await adapter.load(
      'https://cdn.example.test/video.m3u8',
      headers: const {
        'Referer': 'https://example.test/player',
      },
    );

    expect(adapter.lastLoadedUrl, 'https://cdn.example.test/video.m3u8');
    expect(adapter.lastLoadedHeaders['Referer'], 'https://example.test/player');
    await adapter.dispose();
  });

  test('PlayerRouteArgs copyWith updates episode playback fields', () {
    const args = PlayerRouteArgs(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      animeTitle: 'Anime',
      episodeTitle: 'Episode 1',
      playUrl: 'https://cdn.example.test/1.m3u8',
      sourceId: 'sakura',
      playSourceId: 'line-1',
      playSourceTitle: 'Line 1',
      playHeaders: {'Referer': 'https://example.test/1'},
      episodeIndex: 1,
      initialPosition: Duration(minutes: 3),
    );

    final next = args.copyWith(
      episodeId: 'episode-2',
      episodeTitle: 'Episode 2',
      playUrl: 'https://cdn.example.test/2.m3u8',
      playSourceId: 'line-2',
      playSourceTitle: 'Line 2',
      playHeaders: const {'Referer': 'https://example.test/2'},
      episodeIndex: 2,
      initialPosition: null,
    );

    expect(next.animeId, 'anime-1');
    expect(next.episodeId, 'episode-2');
    expect(next.episodeTitle, 'Episode 2');
    expect(next.playSourceId, 'line-2');
    expect(next.initialPosition, isNull);
  });

  test(
      'resolveNextEpisode prefers the current episode id and returns null at the end',
      () {
    const episodes = [
      Episode(id: 'ep-1', animeId: 'anime-1', title: 'Episode 1', index: 1),
      Episode(id: 'ep-2', animeId: 'anime-1', title: 'Episode 2', index: 2),
      Episode(id: 'ep-3', animeId: 'anime-1', title: 'Episode 3', index: 3),
    ];

    expect(
      resolveNextEpisode(
        episodes: episodes,
        currentEpisodeId: 'ep-2',
        currentEpisodeIndex: 2,
      )?.id,
      'ep-3',
    );
    expect(
      resolveNextEpisode(
        episodes: episodes,
        currentEpisodeId: 'ep-3',
        currentEpisodeIndex: 3,
      ),
      isNull,
    );
  });

  test('resolveNextEpisode falls back to the episode index when the id changes',
      () {
    const episodes = [
      Episode(id: 'ep-1-new', animeId: 'anime-1', title: 'Episode 1', index: 1),
      Episode(id: 'ep-2-new', animeId: 'anime-1', title: 'Episode 2', index: 2),
    ];

    expect(
      resolveNextEpisode(
        episodes: episodes,
        currentEpisodeId: 'legacy-ep-1',
        currentEpisodeIndex: 1,
      )?.id,
      'ep-2-new',
    );
  });

  test(
      'resolveNextEpisode falls back to the normalized title when ids and indexes change',
      () {
    const episodes = [
      Episode(
        id: 'ep-1-remux',
        animeId: 'anime-1',
        title: '  Episode   1 ',
        index: 101,
      ),
      Episode(
        id: 'ep-2-remux',
        animeId: 'anime-1',
        title: 'Episode 2',
        index: 102,
      ),
    ];

    expect(
      resolveNextEpisode(
        episodes: episodes,
        currentEpisodeId: 'legacy-ep-1',
        currentEpisodeIndex: 1,
        currentEpisodeTitle: 'episode 1',
      )?.id,
      'ep-2-remux',
    );
  });

  test('selectPreferredPlaySource keeps the current line when possible', () {
    const sources = [
      PlaySource(
        id: 'line-1',
        episodeId: 'ep-2',
        title: 'Line 1',
        url: 'https://cdn.example.test/1.m3u8',
      ),
      PlaySource(
        id: 'line-2',
        episodeId: 'ep-2',
        title: 'Line 2',
        url: 'https://cdn.example.test/2.m3u8',
      ),
    ];

    expect(
      selectPreferredPlaySource(
        sources,
        preferredSourceId: 'line-2',
        preferredSourceTitle: 'Line 1',
      ).id,
      'line-2',
    );
    expect(
      selectPreferredPlaySource(
        sources,
        preferredSourceTitle: 'Line 2',
      ).id,
      'line-2',
    );
    expect(selectPreferredPlaySource(sources).id, 'line-1');
  });

  test(
      'selectPreferredPlaySource matches the current line by normalized title when ids change',
      () {
    const sources = [
      PlaySource(
        id: 'line-1-next',
        episodeId: 'ep-2',
        title: ' line 1 ',
        url: 'https://cdn.example.test/1.m3u8',
      ),
      PlaySource(
        id: 'line-2-next',
        episodeId: 'ep-2',
        title: 'Line 2',
        url: 'https://cdn.example.test/2.m3u8',
      ),
    ];

    expect(
      selectPreferredPlaySource(
        sources,
        preferredSourceId: 'legacy-line-1',
        preferredSourceTitle: 'LINE   1',
      ).id,
      'line-1-next',
    );
  });

  test('PlaybackDiagnosticsBuilder hides query tokens and keeps header keys',
      () {
    final diagnostics = const PlaybackDiagnosticsBuilder().build(
      sourceId: 'sakura',
      playSourceTitle: 'Line 1',
      playUrl: 'https://cdn.example.test/path/video.m3u8?token=secret&x=1',
      headers: const {
        'User-Agent': 'AniDestinyTest',
        'Referer': 'https://example.test/player?token=secret',
      },
    );

    expect(diagnostics.urlType, 'm3u8');
    expect(
      diagnostics.sanitizedUrl,
      'https://cdn.example.test/.../video.m3u8',
    );
    expect(diagnostics.sanitizedUrl, isNot(contains('token')));
    expect(diagnostics.headerKeys, ['Referer', 'User-Agent']);
  });
}
