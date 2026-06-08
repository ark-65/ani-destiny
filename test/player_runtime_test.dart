import 'package:ani_destiny/app/router.dart';
import 'package:ani_destiny/core/constants/app_constants.dart';
import 'package:ani_destiny/features/player/data/adapters/mock_player_adapter.dart';
import 'package:ani_destiny/features/player/domain/entities/player_route_args.dart';
import 'package:ani_destiny/features/player/domain/services/playback_diagnostics.dart';
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
