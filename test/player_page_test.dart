import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_item.dart';
import 'package:ani_destiny/features/danmaku/domain/repositories/danmaku_repository.dart';
import 'package:ani_destiny/features/danmaku/presentation/providers/danmaku_providers.dart';
import 'package:ani_destiny/features/history/domain/entities/watch_history.dart';
import 'package:ani_destiny/features/history/domain/repositories/history_repository.dart';
import 'package:ani_destiny/features/history/presentation/providers/history_providers.dart';
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
