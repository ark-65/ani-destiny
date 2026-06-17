import 'dart:async';

import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime_detail.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/anime/domain/entities/episode.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:ani_destiny/features/anime/domain/repositories/anime_repository.dart';
import 'package:ani_destiny/features/anime/presentation/providers/anime_providers.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_item.dart';
import 'package:ani_destiny/features/danmaku/domain/repositories/danmaku_repository.dart';
import 'package:ani_destiny/features/danmaku/presentation/providers/danmaku_providers.dart';
import 'package:ani_destiny/features/danmaku/presentation/widgets/danmaku_overlay.dart';
import 'package:ani_destiny/features/download/data/services/download_task_creator.dart';
import 'package:ani_destiny/features/download/domain/entities/download_progress.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/services/download_service.dart';
import 'package:ani_destiny/features/download/presentation/providers/download_providers.dart';
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
import 'package:ani_destiny/features/source/domain/entities/source_fallback_result.dart';
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

    await tester.tap(find.byTooltip('Enter fullscreen'));
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

  testWidgets('playback controls stay disabled until the player is ready', (
    tester,
  ) async {
    final repository = _PendingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pump();

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Preparing playback...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Preparing playback...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    repository.completeLoad();
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(find.byType(IconButton).first).onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.speed))
          .onPressed,
      isNotNull,
    );
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);
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
    expect(find.text('Anime: Anime 1'), findsOneWidget);
    expect(find.text('Episode: Episode 2'), findsOneWidget);
    expect(find.text('Source: Sakura Anime'), findsOneWidget);
    expect(find.text('Line: Broken Line'), findsOneWidget);
    expect(find.text('Playback diagnostics'), findsOneWidget);

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(
      playButton.tooltip,
      'Playback temporarily failed. Retry later or try another playback line.',
    );

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(
      speedButton.tooltip,
      'Playback temporarily failed. Retry later or try another playback line.',
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    await tester.tap(find.byTooltip('Playback diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('Anime 1'), findsAtLeastNWidgets(1));
    expect(find.text('Episode'), findsWidgets);
    expect(find.text('Episode 2'), findsAtLeastNWidgets(1));
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('error'), findsNothing);
  });

  testWidgets(
      'player shows requested source context when playback is on fallback data',
      (tester) async {
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
        child: _buildPlayerApp(_fallbackFailingArgs),
      ),
    );
    await tester.pumpAndSettle();

    final diagnostics = container.read(lastPlaybackDiagnosticsProvider);
    expect(diagnostics, isNotNull);
    expect(diagnostics?.sourceId, 'sakura');
    expect(diagnostics?.requestedSourceId, 'mock');
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
    expect(find.text('Anime: Anime 1'), findsOneWidget);
    expect(find.text('Episode: Episode 2'), findsOneWidget);
    expect(
      find.text(
        'Source: Sakura Anime (Requested source: Mock Anime Source)',
      ),
      findsOneWidget,
    );
    expect(find.text('Line: Broken Line'), findsOneWidget);
    expect(find.text('Playback diagnostics'), findsOneWidget);

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(
      playButton.tooltip,
      'Playback temporarily failed. Retry later or try another playback line.',
    );

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(
      speedButton.tooltip,
      'Playback temporarily failed. Retry later or try another playback line.',
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    await tester.tap(find.byTooltip('Playback diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('Anime 1'), findsAtLeastNWidgets(1));
    expect(find.text('Episode'), findsWidgets);
    expect(find.text('Episode 2'), findsAtLeastNWidgets(1));
    expect(find.text('Requested source'), findsOneWidget);
    expect(find.text('Mock Anime Source'), findsAtLeastNWidgets(1));
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('error'), findsNothing);
  });

  testWidgets('playback failure card can copy a sanitized diagnostics summary',
      (
    tester,
  ) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_fallbackFailingArgs),
      ),
    );
    await tester.pumpAndSettle();

    final copyDiagnosticsButton = find.text('Copy diagnostics');
    await tester.ensureVisible(copyDiagnosticsButton);
    await tester.tap(copyDiagnosticsButton);
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics copied'), findsOneWidget);
    expect(copiedText, startsWith('Playback diagnostics summary\n'));
    expect(copiedText, contains('Captured at: '));
    expect(copiedText, contains('Anime: Anime 1'));
    expect(copiedText, contains('Episode: Episode 2'));
    expect(copiedText, contains('Requested source: Mock Anime Source'));
    expect(copiedText, contains('Source: Sakura Anime'));
    expect(copiedText, contains('Line: Broken Line'));
    expect(copiedText, contains('URL type: m3u8'));
    expect(
      copiedText,
      contains('URL: https://cdn.example.test/.../broken.m3u8'),
    );
    expect(copiedText, contains('Request headers: Referer'));
    expect(copiedText, contains('State: Failed'));
  });

  testWidgets(
      'playback failure card explains when external player handoff is blocked by headers',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_fallbackFailingArgs),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This stream needs request headers, so it cannot be opened in an external player yet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('playback failure UI stays usable on narrow screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_failingArgs),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final copyButton = find.byIcon(Icons.content_copy_outlined).first;
    await tester.ensureVisible(copyButton);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics copied'), findsOneWidget);
    expect(copiedText, isNotNull);
    expect(find.text('Playback diagnostics'), findsOneWidget);
  });

  testWidgets('player keeps active fallback source context visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_fallbackArgs),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The selected source Mock Anime Source is temporarily unavailable, so playback is using fallback data from Sakura Anime.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('next episode transition hides stale fallback context', (
    tester,
  ) async {
    final animeRepository = _PendingNextEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_fallbackArgs),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The selected source Mock Anime Source is temporarily unavailable, so playback is using fallback data from Sakura Anime.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    expect(
      find.text(
        'The selected source Mock Anime Source is temporarily unavailable, so playback is using fallback data from Sakura Anime.',
      ),
      findsNothing,
    );
  });

  testWidgets('playback failure card can retry the current source',
      (tester) async {
    final repository = _RetryablePlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(repository.adapter.loadCalls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(repository.adapter.loadCalls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Retrying playback...'), findsOneWidget);
    expect(find.byTooltip('Retrying playback...'), findsWidgets);

    final nextEpisodeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.skip_next),
    );
    expect(nextEpisodeButton.onPressed, isNull);
    expect(nextEpisodeButton.tooltip, 'Retrying playback...');

    final externalPlayerButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.open_in_new),
    );
    expect(externalPlayerButton.onPressed, isNull);
    expect(externalPlayerButton.tooltip, 'Retrying playback...');

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Retrying playback...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Retrying playback...');

    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(downloadButton.onPressed, isNull);
    expect(downloadButton.tooltip, 'Retrying playback...');

    final danmakuButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.subtitles),
    );
    expect(danmakuButton.onPressed, isNull);
    expect(danmakuButton.tooltip, 'Retrying playback...');

    final fullscreenButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.fullscreen),
    );
    expect(fullscreenButton.onPressed, isNull);
    expect(fullscreenButton.tooltip, 'Retrying playback...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    repository.completeRetry();
    await tester.pumpAndSettle();

    final restoredPlayButton = tester.widget<IconButton>(
      find.byType(IconButton).first,
    );
    expect(restoredPlayButton.onPressed, isNotNull);
    expect(find.text('Retry'), findsNothing);
    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsNothing,
    );
  });

  testWidgets('retry keeps the current playback position after an interruption',
      (tester) async {
    final repository = _InterruptedPlayerRepository();
    const interruptedPosition = Duration(minutes: 7, seconds: 24);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    repository.emitPlaybackFailure(position: interruptedPosition);
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.adapter.loadCalls, 2);
    expect(repository.adapter.lastSeekPosition, interruptedPosition);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets(
      'playback failure card offers external player recovery for handoffable streams',
      (tester) async {
    final repository = _RetryablePlayerRepository();
    Uri? launchedUri;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
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

    expect(find.text('External player'), findsOneWidget);

    await tester.tap(find.text('External player'));
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), 'https://cdn.example.test/video.m3u8');
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

  testWidgets('fullscreen controls keep the external player action available', (
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

    await tester.tap(find.byTooltip('Enter fullscreen'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('External player'), findsOneWidget);

    await tester.tap(find.byTooltip('External player'));
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), 'https://cdn.example.test/video.m3u8');
  });

  testWidgets(
      'successful external handoff exits fullscreen and pauses in-app playback',
      (tester) async {
    Uri? launchedUri;
    final repository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
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

    await tester.tap(find.byTooltip('Enter fullscreen'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);

    await tester.tap(find.byTooltip('External player'));
    await tester.pumpAndSettle();

    expect(launchedUri?.toString(), 'https://cdn.example.test/video.m3u8');
    expect(repository.adapter.pauseCalls, 1);
    expect(find.byType(AppBar), findsOneWidget);
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

  testWidgets('external player action stays busy until handoff completes', (
    tester,
  ) async {
    final launchCompleter = Completer<bool>();
    var launchCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          externalPlayerLauncherProvider.overrideWithValue((_) {
            launchCalls += 1;
            return launchCompleter.future;
          }),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('External player'));
    await tester.pump();

    expect(launchCalls, 1);
    expect(find.byTooltip('Opening external player...'), findsWidgets);
    final openingButton =
        tester.widgetList<IconButton>(find.byType(IconButton)).singleWhere(
              (button) =>
                  button.tooltip == 'Opening external player...' &&
                  button.icon is SizedBox,
            );
    expect(openingButton.onPressed, isNull);
    expect(openingButton.tooltip, 'Opening external player...');

    final nextEpisodeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.skip_next),
    );
    expect(nextEpisodeButton.onPressed, isNull);
    expect(nextEpisodeButton.tooltip, 'Opening external player...');

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Opening external player...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Opening external player...');

    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(downloadButton.onPressed, isNull);
    expect(downloadButton.tooltip, 'Opening external player...');

    final fullscreenButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.fullscreen),
    );
    expect(fullscreenButton.onPressed, isNull);
    expect(fullscreenButton.tooltip, 'Opening external player...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    expect(launchCalls, 1);

    launchCompleter.complete(true);
    await tester.pumpAndSettle();

    expect(launchCalls, 1);
    expect(find.byTooltip('External player'), findsOneWidget);
  });

  testWidgets(
      'external player action is disabled when the stream depends on request headers',
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

    expect(
      find.byTooltip(
        'This stream needs request headers, so it cannot be opened in an external player yet.',
      ),
      findsOneWidget,
    );
    final externalPlayerButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.open_in_new),
    );
    expect(externalPlayerButton.onPressed, isNull);

    expect(launchedUri, isNull);
  });

  testWidgets('external player action is disabled while next episode loads', (
    tester,
  ) async {
    Uri? launchedUri;
    final pendingRepository = _PendingNextEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(pendingRepository),
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

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    expect(find.text('Loading next episode...'), findsNWidgets(2));
    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Loading next episode...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Loading next episode...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    final externalPlayerButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.open_in_new),
    );
    expect(externalPlayerButton.onPressed, isNull);

    final danmakuButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.subtitles),
    );
    expect(danmakuButton.onPressed, isNull);
    expect(danmakuButton.tooltip, 'Loading next episode...');

    final fullscreenButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.fullscreen),
    );
    expect(fullscreenButton.onPressed, isNull);
    expect(fullscreenButton.tooltip, 'Loading next episode...');

    expect(find.byTooltip('Loading next episode...'), findsWidgets);
    await tester.tap(find.byTooltip('Loading next episode...').first);
    await tester.pump();

    expect(launchedUri, isNull);
  });

  testWidgets('next episode transition pauses the current playback first', (
    tester,
  ) async {
    final pendingRepository = _PendingNextEpisodeAnimeRepository();
    final playerRepository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(pendingRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    expect(playerRepository.adapter.pauseCalls, 0);

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    expect(playerRepository.adapter.pauseCalls, 1);
    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Loading next episode...');
  });

  testWidgets('next episode loading overlay names the upcoming episode', (
    tester,
  ) async {
    final animeRepository = _PendingPlayableNextEpisodeAnimeRepository();
    final playerRepository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Loading next episode...'), findsOneWidget);
    expect(find.text('Episode 2'), findsNWidgets(2));
  });

  testWidgets(
      'app bar title shows loading state while the next episode is still unresolved',
      (tester) async {
    final animeRepository = _PendingNextEpisodeAnimeRepository();
    final playerRepository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    final initialAppBar = tester.widget<AppBar>(find.byType(AppBar));
    expect((initialAppBar.title as Text).data, 'Episode 1');

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    final loadingAppBar = tester.widget<AppBar>(find.byType(AppBar));
    expect((loadingAppBar.title as Text).data, 'Loading next episode...');
  });

  testWidgets('app bar title switches to the upcoming episode once it is known',
      (tester) async {
    final animeRepository = _PendingPlayableNextEpisodeAnimeRepository();
    final playerRepository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();
    await tester.pump();

    final resolvedAppBar = tester.widget<AppBar>(find.byType(AppBar));
    expect((resolvedAppBar.title as Text).data, 'Episode 2');
  });

  testWidgets(
      'failed playback clears stale error UI before next episode finishes loading',
      (tester) async {
    final animeRepository = _PendingPlayableNextEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(
          _failingArgs.copyWith(
            episodeId: 'episode-1',
            episodeTitle: 'Episode 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Loading next episode...'), findsOneWidget);
    expect(find.text('Episode 2'), findsNWidgets(2));
    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsNothing,
    );
  });

  testWidgets('next episode transition hides stale danmaku chrome', (
    tester,
  ) async {
    final animeRepository = _PendingNextEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(
            _PopulatedDanmakuRepository(),
          ),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DanmakuOverlay), findsOneWidget);
    expect(find.text('Danmaku: Dandanplay'), findsOneWidget);

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    expect(find.text('Loading next episode...'), findsNWidgets(2));
    expect(find.byType(DanmakuOverlay), findsNothing);
    expect(find.text('Danmaku: Dandanplay'), findsNothing);
  });

  testWidgets(
      'current playback resumes if next episode is unavailable before switching',
      (tester) async {
    final animeRepository = _LastEpisodeAnimeRepository();
    final playerRepository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pumpAndSettle();

    expect(playerRepository.adapter.pauseCalls, 1);
    expect(playerRepository.adapter.playCalls, 1);
    expect(
      find.text('You are already on the latest available episode.'),
      findsOneWidget,
    );

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNotNull);
    expect(playButton.tooltip, 'Pause');
  });

  testWidgets(
      'failed playback restores the current error card if no next episode exists',
      (tester) async {
    final animeRepository = _LastEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(
          _failingArgs.copyWith(
            episodeId: 'episode-1',
            episodeTitle: 'Episode 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pumpAndSettle();

    expect(
      find.text('You are already on the latest available episode.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
      'failed playback restores the current error card if the next episode has no playable source',
      (tester) async {
    final animeRepository = _NoPlayableNextEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(
          _failingArgs.copyWith(
            episodeId: 'episode-1',
            episodeTitle: 'Episode 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No playable source found. Try another source or retry later.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
      'current playback resumes if next episode has no playable sources',
      (tester) async {
    final animeRepository = _NoPlayableNextEpisodeAnimeRepository();
    final playerRepository = _TrackingPlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pumpAndSettle();

    expect(playerRepository.adapter.pauseCalls, 1);
    expect(playerRepository.adapter.playCalls, 1);
    expect(
      find.text(
        'No playable source found. Try another source or retry later.',
      ),
      findsOneWidget,
    );

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNotNull);
    expect(playButton.tooltip, 'Pause');
  });

  testWidgets('current playback is restored if the next episode fails to start',
      (tester) async {
    final animeRepository = _PlayableNextEpisodeAnimeRepository();
    final playerRepository = _NextEpisodeLoadFailurePlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(animeRepository),
          playerRepositoryProvider.overrideWithValue(playerRepository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pumpAndSettle();

    expect(playerRepository.adapter.pauseCalls, 1);
    expect(playerRepository.adapter.playCalls, 1);
    expect(playerRepository.adapter.loadCalls, 3);
    expect(find.text('Episode 1'), findsOneWidget);
    expect(
      find.text('Source temporarily unavailable'),
      findsOneWidget,
    );

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNotNull);
    expect(playButton.tooltip, 'Pause');
  });

  testWidgets('system back stays on the player while next episode loads', (
    tester,
  ) async {
    final pendingRepository = _PendingNextEpisodeAnimeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(pendingRepository),
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    await tester.pageBack();
    await tester.pump();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(find.text('Open player'), findsNothing);
    expect(
      find.text(
        'Please wait for the current playback action to finish before leaving.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('system back stays on the player while external handoff opens', (
    tester,
  ) async {
    final launchCompleter = Completer<bool>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          externalPlayerLauncherProvider.overrideWithValue(
            (_) => launchCompleter.future,
          ),
        ],
        child: _buildApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('External player'));
    await tester.pump();

    await tester.pageBack();
    await tester.pump();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(find.text('Open player'), findsNothing);
    expect(
      find.text(
        'Please wait for the current playback action to finish before leaving.',
      ),
      findsOneWidget,
    );

    launchCompleter.complete(true);
    await tester.pumpAndSettle();
  });

  testWidgets('system back stays on the player while playback retries', (
    tester,
  ) async {
    final repository = _RetryablePlayerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(repository),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pump();

    await tester.pageBack();
    await tester.pump();

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(find.text('Open player'), findsNothing);
    expect(
      find.text(
        'Please wait for the current playback action to finish before leaving.',
      ),
      findsOneWidget,
    );

    repository.completeRetry();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'download action is disabled and explained while next episode loads',
      (tester) async {
    final pendingRepository = _PendingNextEpisodeAnimeRepository();
    var createdDownloads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(pendingRepository),
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          downloadTaskCreatorProvider.overrideWithValue(
            _FakeDownloadTaskCreator(onCreate: () => createdDownloads++),
          ),
        ],
        child: _buildPlayerApp(_args),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next episode'));
    await tester.pump();

    expect(find.byTooltip('Loading next episode...'), findsWidgets);
    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(downloadButton.onPressed, isNull);

    await tester.tap(find.byTooltip('Loading next episode...').last);
    await tester.pump();

    expect(createdDownloads, 0);
  });

  testWidgets('download action is disabled when no playable url is available',
      (tester) async {
    var createdDownloads = 0;
    var launchedUriCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(const _FakePlayerRepository()),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
          externalPlayerLauncherProvider.overrideWithValue((uri) async {
            launchedUriCount++;
            return true;
          }),
          downloadTaskCreatorProvider.overrideWithValue(
            _FakeDownloadTaskCreator(onCreate: () => createdDownloads++),
          ),
        ],
        child: _buildPlayerApp(_missingPlayUrlArgs),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No playable source found'), findsOneWidget);
    expect(find.text('Anime: Anime 1'), findsOneWidget);
    expect(find.text('Episode: Episode 3'), findsOneWidget);
    expect(find.text('Source: Sakura Anime'), findsOneWidget);
    expect(find.text('Line: Missing Line'), findsOneWidget);
    expect(find.text('Playback diagnostics'), findsOneWidget);
    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(
      downloadButton.tooltip,
      'No playable source found. Try another source or retry later.',
    );
    expect(downloadButton.onPressed, isNull);

    final playButton = tester.widget<IconButton>(
      find.byType(IconButton).first,
    );
    expect(playButton.onPressed, isNull);
    expect(
      playButton.tooltip,
      'No playable source found. Try another source or retry later.',
    );

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(
      speedButton.tooltip,
      'No playable source found. Try another source or retry later.',
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);

    expect(createdDownloads, 0);
    expect(launchedUriCount, 0);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('invalid playback urls are treated as unavailable before load',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(
            const _ThrowingPlayerRepository(),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
          danmakuRepositoryProvider.overrideWithValue(_FakeDanmakuRepository()),
        ],
        child: _buildPlayerApp(_invalidPlayUrlArgs),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No playable source found'), findsOneWidget);
    expect(
      find.text(
        'Playback temporarily failed. Retry later or try another playback line.',
      ),
      findsNothing,
    );

    final playButton = tester.widget<IconButton>(
      find.byType(IconButton).first,
    );
    expect(playButton.onPressed, isNull);
    expect(
      playButton.tooltip,
      'No playable source found. Try another source or retry later.',
    );
  });
}

Widget _buildApp([PlayerRouteArgs args = _args]) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: _HostPage(args: args),
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
  const _HostPage({required this.args});

  final PlayerRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayerPage(args: args),
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

class _PopulatedDanmakuRepository implements DanmakuRepository {
  @override
  Future<List<DanmakuItem>> getDanmaku({
    required String animeId,
    required String episodeId,
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  }) async {
    return const [
      DanmakuItem(
        id: 'comment-1',
        text: 'Visible danmaku',
        time: Duration(seconds: 2),
        color: 0xFFFFFFFF,
        type: DanmakuType.scroll,
        source: 'dandanplay',
      ),
    ];
  }
}

class _PendingNextEpisodeAnimeRepository implements AnimeRepository {
  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) {
    return Completer<SourceFallbackResult<AnimeDetail>>().future;
  }

  @override
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(
    String episodeId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  }) {
    throw UnimplementedError();
  }
}

class _LastEpisodeAnimeRepository implements AnimeRepository {
  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) async {
    return SourceFallbackResult(
      value: AnimeDetail(
        id: animeId,
        title: 'Anime 1',
        sourceId: sourceId,
        episodes: const [
          Episode(
            id: 'episode-1',
            animeId: 'anime-1',
            title: 'Episode 1',
            index: 1,
          ),
        ],
      ),
      sourceId: sourceId,
      usedFallback: false,
    );
  }

  @override
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(
    String episodeId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  }) {
    throw UnimplementedError();
  }
}

class _NoPlayableNextEpisodeAnimeRepository implements AnimeRepository {
  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) async {
    return SourceFallbackResult(
      value: AnimeDetail(
        id: animeId,
        title: 'Anime 1',
        sourceId: sourceId,
        episodes: const [
          Episode(
            id: 'episode-1',
            animeId: 'anime-1',
            title: 'Episode 1',
            index: 1,
          ),
          Episode(
            id: 'episode-2',
            animeId: 'anime-1',
            title: 'Episode 2',
            index: 2,
          ),
        ],
      ),
      sourceId: sourceId,
      usedFallback: false,
    );
  }

  @override
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(
    String episodeId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) async {
    return SourceFallbackResult(
      value: const [],
      sourceId: sourceId,
      usedFallback: false,
    );
  }

  @override
  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  }) {
    throw UnimplementedError();
  }
}

class _PlayableNextEpisodeAnimeRepository implements AnimeRepository {
  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) async {
    return SourceFallbackResult(
      value: AnimeDetail(
        id: animeId,
        title: 'Anime 1',
        sourceId: sourceId,
        episodes: const [
          Episode(
            id: 'episode-1',
            animeId: 'anime-1',
            title: 'Episode 1',
            index: 1,
          ),
          Episode(
            id: 'episode-2',
            animeId: 'anime-1',
            title: 'Episode 2',
            index: 2,
          ),
        ],
      ),
      sourceId: sourceId,
      usedFallback: false,
    );
  }

  @override
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(
    String episodeId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) async {
    return SourceFallbackResult(
      value: const [
        PlaySource(
          id: 'line-1',
          episodeId: 'episode-2',
          title: 'Line 1',
          url: 'https://cdn.example.test/episode-2.m3u8',
        ),
      ],
      sourceId: sourceId,
      usedFallback: false,
    );
  }

  @override
  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  }) {
    throw UnimplementedError();
  }
}

class _PendingPlayableNextEpisodeAnimeRepository
    extends _PlayableNextEpisodeAnimeRepository {
  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) {
    return Completer<SourceFallbackResult<List<PlaySource>>>().future;
  }
}

class _FakeDownloadTaskCreator extends DownloadTaskCreator {
  _FakeDownloadTaskCreator({required this.onCreate})
      : super(_FakeDownloadService());

  final void Function() onCreate;

  @override
  Future<String> create({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required String url,
    required String title,
    required String episodeTitle,
    Map<String, String> headers = const {},
    String? fileName,
    String? mimeType,
  }) async {
    onCreate();
    return 'task-1';
  }
}

class _FakeDownloadService implements DownloadService {
  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  }) async {
    return 'task-1';
  }

  @override
  Future<void> pause(String taskId) async {}

  @override
  Future<void> start(String taskId) async {}

  @override
  Stream<DownloadProgress> watchProgress(String taskId) => const Stream.empty();
}

class _ThrowingPlayerRepository implements PlayerRepository {
  const _ThrowingPlayerRepository();

  @override
  PlayerControllerAdapter createController() => _ThrowingPlayerAdapter();
}

class _PendingPlayerRepository implements PlayerRepository {
  _PendingPlayerRepository();

  final _adapter = _PendingPlayerAdapter();

  @override
  PlayerControllerAdapter createController() => _adapter;

  void completeLoad() {
    _adapter.completeLoad();
  }
}

class _RetryablePlayerRepository implements PlayerRepository {
  _RetryablePlayerRepository();

  final adapter = _RetryablePlayerAdapter();

  @override
  PlayerControllerAdapter createController() => adapter;

  void completeRetry() {
    adapter.completeRetry();
  }
}

class _InterruptedPlayerRepository implements PlayerRepository {
  _InterruptedPlayerRepository();

  final adapter = _InterruptedPlayerAdapter();

  @override
  PlayerControllerAdapter createController() => adapter;

  void emitPlaybackFailure({
    required Duration position,
  }) {
    adapter.emitPlaybackFailure(position: position);
  }
}

class _FakePlayerRepository implements PlayerRepository {
  const _FakePlayerRepository();

  @override
  PlayerControllerAdapter createController() => _FakePlayerControllerAdapter();
}

class _TrackingPlayerRepository implements PlayerRepository {
  _TrackingPlayerRepository();

  final adapter = _TrackingPlayerControllerAdapter();

  @override
  PlayerControllerAdapter createController() => adapter;
}

class _NextEpisodeLoadFailurePlayerRepository implements PlayerRepository {
  _NextEpisodeLoadFailurePlayerRepository();

  final adapter = _NextEpisodeLoadFailurePlayerAdapter();

  @override
  PlayerControllerAdapter createController() => adapter;
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

class _TrackingPlayerControllerAdapter implements PlayerControllerAdapter {
  _TrackingPlayerControllerAdapter();

  final _controller = StreamController<PlayerState>.broadcast();
  int pauseCalls = 0;
  int playCalls = 0;
  PlayerState _state = PlayerState.initial();

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    _state = PlayerState.initial().copyWith(
      isInitialized: true,
      isPlaying: true,
      duration: const Duration(minutes: 24, seconds: 12),
    );
    _controller.add(_state);
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    _state = _state.copyWith(isPlaying: false);
    _controller.add(_state);
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    _state = _state.copyWith(isPlaying: true);
    _controller.add(_state);
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}
}

class _NextEpisodeLoadFailurePlayerAdapter implements PlayerControllerAdapter {
  _NextEpisodeLoadFailurePlayerAdapter();

  final _controller = StreamController<PlayerState>.broadcast();
  PlayerState _state = PlayerState.initial();
  int loadCalls = 0;
  int pauseCalls = 0;
  int playCalls = 0;

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    loadCalls += 1;
    if (loadCalls == 2) {
      throw StateError('next episode failed');
    }
    _state = PlayerState.initial().copyWith(
      isInitialized: true,
      isPlaying: loadCalls == 1,
      duration: const Duration(minutes: 24, seconds: 12),
    );
    _controller.add(_state);
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    _state = _state.copyWith(isPlaying: false);
    _controller.add(_state);
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    _state = _state.copyWith(isPlaying: true);
    _controller.add(_state);
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}
}

class _PendingPlayerAdapter implements PlayerControllerAdapter {
  final _controller = StreamController<PlayerState>.broadcast();
  final _loadCompleter = Completer<void>();

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) {
    return _loadCompleter.future;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  void completeLoad() {
    if (_loadCompleter.isCompleted) return;
    _loadCompleter.complete();
    _controller.add(
      PlayerState.initial().copyWith(
        isInitialized: true,
        duration: const Duration(minutes: 24, seconds: 12),
      ),
    );
  }
}

class _RetryablePlayerAdapter implements PlayerControllerAdapter {
  _RetryablePlayerAdapter();

  final _controller = StreamController<PlayerState>.broadcast();
  final _retryCompleter = Completer<void>();
  int loadCalls = 0;

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    loadCalls += 1;
    if (loadCalls == 1) {
      await Future<void>.delayed(Duration.zero);
      throw StateError('load failed');
    }
    return _retryCompleter.future;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  void completeRetry() {
    if (_retryCompleter.isCompleted) return;
    _retryCompleter.complete();
    _controller.add(
      PlayerState.initial().copyWith(
        isInitialized: true,
        duration: const Duration(minutes: 24, seconds: 12),
      ),
    );
  }
}

class _InterruptedPlayerAdapter implements PlayerControllerAdapter {
  _InterruptedPlayerAdapter();

  final _controller = StreamController<PlayerState>.broadcast();
  PlayerState _state = PlayerState.initial();
  int loadCalls = 0;
  Duration? lastSeekPosition;

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    loadCalls += 1;
    _state = PlayerState.initial().copyWith(
      isInitialized: true,
      duration: const Duration(minutes: 24, seconds: 12),
      speed: 1.25,
      clearErrorMessage: true,
    );
    _controller.add(_state);
  }

  @override
  Future<void> pause() async {
    _state = _state.copyWith(isPlaying: false);
    _controller.add(_state);
  }

  @override
  Future<void> play() async {
    _state = _state.copyWith(isPlaying: true);
    _controller.add(_state);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
    _state = _state.copyWith(position: position);
    _controller.add(_state);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _state = _state.copyWith(speed: speed);
    _controller.add(_state);
  }

  void emitPlaybackFailure({
    required Duration position,
  }) {
    _state = _state.copyWith(
      isInitialized: true,
      isPlaying: false,
      position: position,
      errorMessage: 'stream interrupted',
    );
    _controller.add(_state);
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

const _fallbackFailingArgs = PlayerRouteArgs(
  animeId: 'anime-1',
  episodeId: 'episode-2',
  animeTitle: 'Anime 1',
  episodeTitle: 'Episode 2',
  playUrl: 'https://cdn.example.test/path/broken.m3u8?token=secret',
  sourceId: 'sakura',
  requestedSourceId: 'mock',
  playSourceId: 'line-broken',
  playSourceTitle: 'Broken Line',
  playHeaders: {'Referer': 'https://example.test/player?token=secret'},
);

const _fallbackArgs = PlayerRouteArgs(
  animeId: 'anime-1',
  episodeId: 'episode-1',
  animeTitle: 'Anime 1',
  episodeTitle: 'Episode 1',
  playUrl: 'https://cdn.example.test/video.m3u8',
  sourceId: 'sakura',
  requestedSourceId: 'mock',
  playSourceId: 'line-1',
  playSourceTitle: 'Line 1',
);

const _missingPlayUrlArgs = PlayerRouteArgs(
  animeId: 'anime-1',
  episodeId: 'episode-3',
  animeTitle: 'Anime 1',
  episodeTitle: 'Episode 3',
  playUrl: '',
  sourceId: 'sakura',
  playSourceId: 'line-missing',
  playSourceTitle: 'Missing Line',
);

const _invalidPlayUrlArgs = PlayerRouteArgs(
  animeId: 'anime-1',
  episodeId: 'episode-4',
  animeTitle: 'Anime 1',
  episodeTitle: 'Episode 4',
  playUrl: 'not-a-playable-url',
  sourceId: 'sakura',
  playSourceId: 'line-invalid',
  playSourceTitle: 'Invalid Line',
);
