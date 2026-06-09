import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_item.dart';
import 'package:ani_destiny/features/danmaku/domain/repositories/danmaku_repository.dart';
import 'package:ani_destiny/features/danmaku/presentation/providers/danmaku_providers.dart';
import 'package:ani_destiny/features/history/domain/entities/watch_history.dart';
import 'package:ani_destiny/features/history/domain/repositories/history_repository.dart';
import 'package:ani_destiny/features/history/presentation/providers/history_providers.dart';
import 'package:ani_destiny/features/player/domain/adapters/player_controller_adapter.dart';
import 'package:ani_destiny/features/player/domain/entities/player_state.dart';
import 'package:ani_destiny/features/player/domain/repositories/player_repository.dart';
import 'package:ani_destiny/features/player/data/repositories/player_repository_impl.dart';
import 'package:ani_destiny/features/player/domain/entities/player_route_args.dart';
import 'package:ani_destiny/features/player/presentation/pages/player_page.dart';
import 'package:ani_destiny/features/player/presentation/providers/player_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('system back exits fullscreen before popping the player page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const PlayerRepositoryImpl()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open player'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Open player'), findsNothing);

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byType(AppBar), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Open player'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Open player'), findsOneWidget);
    expect(find.byType(PlayerPage), findsNothing);
  });

  testWidgets('playback diagnostics keep the attempted source after load fails',
      (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(
          const _ThrowingPlayerRepository(),
        ),
        historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
        danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _buildPlayerApp(_failingArgs),
      ),
    );
    await tester.pumpAndSettle();

    final diagnostics = container.read(lastPlaybackDiagnosticsProvider);
    expect(diagnostics, isNotNull);
    expect(diagnostics?.sourceId, 'sakura');
    expect(diagnostics?.playSourceTitle, 'Broken Line');
    expect(
      diagnostics?.sanitizedUrl,
      'https://cdn.example.test/.../broken.m3u8',
    );
    expect(diagnostics?.headerKeys, ['Referer']);
    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Playback diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('State'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('error'), findsNothing);
  });

  testWidgets('external player action launches the current playback url', (
    tester,
  ) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          externalPlayerLauncherProvider.overrideWithValue((uri) async {
            launchedUri = uri;
            return true;
          }),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('External player'));
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), 'https://cdn.example.test/video.m3u8');
  });

  testWidgets('external player action shows feedback when launch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          externalPlayerLauncherProvider.overrideWithValue((_) async => false),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('External player'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not open in an external player. Try again later.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'external player action explains when the stream depends on request headers',
      (tester) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          externalPlayerLauncherProvider.overrideWithValue((uri) async {
            launchedUri = uri;
            return true;
          }),
        ],
        child: _buildPlayerApp(_failingArgs),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('External player'));
    await tester.pumpAndSettle();

    expect(launchedUri, isNull);
    expect(
      find.text(
        'This stream needs request headers, so it cannot be opened in an external player yet.',
      ),
      findsOneWidget,
    );
  });
}

Widget _buildApp() {
  return const MaterialApp(
    locale: Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: _HostPage(),
  );
}

Widget _buildPlayerApp(PlayerRouteArgs args) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: PlayerPage(args: args),
  );
}

class _HostPage extends StatelessWidget {
  const _HostPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlayerPage(args: _args),
              ),
            );
          },
          child: const Text('Open player'),
        ),
      ),
    );
  }
}

class _FakeHistoryRepository implements HistoryRepository {
  final List<WatchHistory> _items = [];

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<WatchHistory?> getByEpisode(String episodeId) async {
    for (final item in _items) {
      if (item.episodeId == episodeId) return item;
    }
    return null;
  }

  @override
  Future<void> upsert(WatchHistory history) async {
    _items.removeWhere((item) => item.id == history.id);
    _items.add(history);
  }

  @override
  Stream<List<WatchHistory>> watchHistory() async* {
    yield List.unmodifiable(_items);
  }
}

class _FakeDanmakuRepository implements DanmakuRepository {
  @override
  Future<List<DanmakuItem>> getDanmaku({
    required String animeId,
    required String episodeId,
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  }) async {
    return const [];
  }
}

class _ThrowingPlayerRepository implements PlayerRepository {
  const _ThrowingPlayerRepository();

  @override
  PlayerControllerAdapter createController() => _ThrowingPlayerAdapter();
}

class _FakePlayerRepository implements PlayerRepository {
  const _FakePlayerRepository();

  @override
  PlayerControllerAdapter createController() => _FakePlayerControllerAdapter();
}

class _ThrowingPlayerAdapter implements PlayerControllerAdapter {
  @override
  Stream<PlayerState> get stateStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    throw StateError('load failed');
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}
}

class _FakePlayerControllerAdapter implements PlayerControllerAdapter {
  @override
  Stream<PlayerState> get stateStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}
}

const _args = PlayerRouteArgs(
  animeId: 'anime-1',
  episodeId: 'episode-1',
  animeTitle: 'Anime 1',
  episodeTitle: 'Episode 1',
  playUrl: 'https://cdn.example.test/video.m3u8',
  sourceId: 'sakura',
  playSourceId: 'line-1',
  playSourceTitle: 'Line 1',
);

const _failingArgs = PlayerRouteArgs(
  animeId: 'anime-1',
  episodeId: 'episode-2',
  animeTitle: 'Anime 1',
  episodeTitle: 'Episode 2',
  playUrl: 'https://cdn.example.test/path/broken.m3u8?token=secret',
  sourceId: 'sakura',
  playSourceId: 'line-broken',
  playSourceTitle: 'Broken Line',
  playHeaders: {'Referer': 'https://example.test/player?token=secret'},
);
