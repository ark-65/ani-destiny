import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/diagnostics/playback_diagnostic_snapshot_preview.dart';
import 'package:ani_destiny/core/diagnostics/playback_diagnostic_summary.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_settings.dart';
import 'package:ani_destiny/features/danmaku/presentation/providers/danmaku_providers.dart';
import 'package:ani_destiny/features/player/domain/services/playback_diagnostics.dart';
import 'package:ani_destiny/features/player/presentation/providers/player_providers.dart';
import 'package:ani_destiny/features/settings/presentation/pages/settings_page.dart';
import 'package:ani_destiny/features/settings/presentation/pages/runtime_diagnostics_page.dart';
import 'package:ani_destiny/features/settings/presentation/providers/settings_providers.dart';
import 'package:ani_destiny/features/source/domain/entities/anime_source.dart';
import 'package:ani_destiny/features/source/domain/entities/source_diagnostic.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_event.dart';
import 'package:ani_destiny/features/source/domain/entities/source_health.dart';
import 'package:ani_destiny/features/source/presentation/pages/source_settings_page.dart';
import 'package:ani_destiny/features/source/presentation/providers/source_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runtime diagnostics localize source names in user-visible rows',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        home: const RuntimeDiagnosticsPage(),
        overrides: _providerOverrides,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Selected app source'), findsOneWidget);
    expect(find.textContaining('Sakura Anime'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('Mock Anime Source'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Mock Anime Source'), findsWidgets);
    expect(find.textContaining('Details:'), findsOneWidget);
    expect(find.textContaining('Sakura Anime · Details'), findsOneWidget);
    expect(find.text('sakura'), findsNothing);
    expect(find.text('mock'), findsNothing);
    expect(find.text('detail'), findsNothing);
    expect(
      find.textContaining('Retry later or switch sources'),
      findsOneWidget,
    );
    expect(
      find.text(
        'No playback snapshot has been captured in this session yet. Start playback once and the latest playback moment will appear here.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Start playback once in this session to copy the latest playback diagnostics.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'A sanitized feedback summary will be copied. The playback section stays unavailable until playback runs once in this session.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('No playback diagnostics were captured in this session.'),
      findsOneWidget,
    );
  });

  testWidgets('source diagnostics sheet localizes source names',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        home: const SourceSettingsPage(),
        overrides: _providerOverrides,
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Source diagnostics'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Sakura Anime · Details'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sakura Anime'), findsWidgets);
    expect(find.textContaining('Mock Anime Source'), findsWidgets);
    expect(find.textContaining('Details:'), findsOneWidget);
    expect(find.textContaining('Sakura Anime · Details'), findsOneWidget);
    expect(find.text('sakura'), findsNothing);
    expect(find.text('mock'), findsNothing);
    expect(find.text('detail'), findsNothing);
  });

  testWidgets('settings page keeps runtime diagnostics visible for support',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        home: const SettingsPage(),
        overrides: _providerOverrides,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Runtime diagnostics'), findsOneWidget);
    expect(
      find.text('Feedback summary without sensitive values.'),
      findsOneWidget,
    );
    expect(find.text('Copy diagnostics'), findsOneWidget);
  });

  testWidgets('runtime diagnostics page can copy diagnostics in place', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
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
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      _buildApp(
        home: const RuntimeDiagnosticsPage(),
        overrides: [
          ..._providerOverrides,
          feedbackPackageMarkdownProvider.overrideWith(
            (ref) async => 'Runtime diagnostics summary',
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics copied'), findsOneWidget);
    expect(copiedText, 'Runtime diagnostics summary');
  });

  testWidgets(
      'runtime diagnostics can copy the latest playback snapshot in place', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
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
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final container = ProviderContainer(overrides: _providerOverrides);
    addTearDown(container.dispose);
    container.read(lastPlaybackDiagnosticsProvider.notifier).state =
        PlaybackDiagnostics(
      capturedAt: DateTime(2026, 6, 17, 1, 2, 3),
      animeTitle: 'Anime 1',
      episodeTitle: 'Episode 2',
      selectedAppSourceId: 'remote-proxy',
      sourceId: 'mock',
      requestedSourceId: 'sakura',
      playSourceTitle: 'Line 1',
      urlType: 'm3u8',
      sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
      headerKeys: const ['Referer', 'User-Agent'],
      state: PlaybackDiagnosticState.buffering,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: RuntimeDiagnosticsPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final copyPlaybackDiagnostics = find.text('Copy playback diagnostics');
    await tester.ensureVisible(copyPlaybackDiagnostics);
    await tester.tap(copyPlaybackDiagnostics);
    await tester.pumpAndSettle();

    const l10n = AppLocalizations(Locale('en'));
    final expected = buildPlaybackDiagnosticSummary(
      l10n: l10n,
      localeName: 'en',
      diagnostics: container.read(lastPlaybackDiagnosticsProvider)!,
    );

    expect(find.text('Playback diagnostics copied'), findsOneWidget);
    expect(copiedText, expected);
    expect(
      find.text(
        'Copies a sanitized summary of the latest playback without sensitive values.',
      ),
      findsOneWidget,
    );
    expect(
      copiedText,
      contains('Selected app source at playback: Remote Source Proxy'),
    );
    expect(
      copiedText,
      contains(
        'Playback source status: Sakura Anime is temporarily unavailable. AniDestiny is playing from Mock Anime Source instead.',
      ),
    );
  });

  testWidgets('source diagnostics sheet can copy diagnostics in place', (
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
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      _buildApp(
        home: const SourceSettingsPage(),
        overrides: [
          ..._providerOverrides,
          feedbackPackageMarkdownProvider.overrideWith(
            (ref) async => 'Source diagnostics summary',
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Source diagnostics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics copied'), findsOneWidget);
    expect(copiedText, 'Source diagnostics summary');
  });

  testWidgets('runtime diagnostics sanitizes inline support details', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        home: const RuntimeDiagnosticsPage(),
        overrides: [
          ..._providerOverrides,
          sourceHealthControllerProvider.overrideWith(
            () => _SensitiveSourceHealthController(),
          ),
          sourceFallbackEventsProvider.overrideWith(
            () => _SensitiveSourceFallbackEventsController(),
          ),
          sourceDiagnosticsControllerProvider.overrideWith(
            () => _SensitiveSourceDiagnosticsController(),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('HTML document omitted'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('[sensitive]=[hidden]'), findsWidgets);
    expect(find.textContaining('HTML document omitted'), findsOneWidget);
    expect(find.textContaining('token=secret'), findsNothing);
    expect(find.textContaining('session=abc123'), findsNothing);
  });

  testWidgets('runtime diagnostics shows the latest playback snapshot', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: _providerOverrides);
    addTearDown(container.dispose);
    container.read(lastPlaybackDiagnosticsProvider.notifier).state =
        PlaybackDiagnostics(
      capturedAt: DateTime(2026, 6, 17, 1, 2, 3),
      animeTitle: 'Anime 1',
      episodeTitle: 'Episode 2',
      selectedAppSourceId: null,
      sourceId: 'mock',
      requestedSourceId: 'sakura',
      playSourceTitle: 'Line 1',
      urlType: 'm3u8',
      sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
      headerKeys: ['Referer', 'User-Agent'],
      state: PlaybackDiagnosticState.buffering,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: RuntimeDiagnosticsPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final preview = buildPlaybackDiagnosticSnapshotPreview(
      l10n: const AppLocalizations(Locale('en')),
      localeName: 'en',
      diagnostics: container.read(lastPlaybackDiagnosticsProvider)!,
    );

    expect(preview, contains('State: Buffering'));
    expect(preview, contains('Anime 1'));
    expect(preview, contains('Episode 2'));
    expect(find.text('Playback diagnostics'), findsOneWidget);
    expect(find.text('Latest playback'), findsOneWidget);
    expect(
      find.textContaining(
        'This is the latest playback snapshot captured in this session.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(preview), findsOneWidget);
    expect(find.textContaining('Latest playback:'), findsNothing);
    expect(find.text('Anime'), findsNothing);
    expect(find.text('Episode'), findsNothing);
    expect(find.text('State'), findsNothing);
    expect(find.text('Captured at'), findsNothing);
    expect(
      find.textContaining(
        'Playback source status: Sakura Anime is temporarily unavailable. AniDestiny is playing from Mock Anime Source instead.',
      ),
      findsOneWidget,
    );
    expect(find.text('Selected playback source'), findsNothing);
    expect(find.text('Line 1'), findsNothing);
    expect(find.text('URL type'), findsOneWidget);
    expect(
      find.text('https://cdn.example.test/.../episode-2.m3u8'),
      findsOneWidget,
    );
    expect(find.text('Referer, User-Agent'), findsOneWidget);
    expect(find.text('Request header names'), findsOneWidget);
  });

  testWidgets(
      'runtime diagnostics playback snapshot adds app source only when it explains a mismatch',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        ..._providerOverrides,
        currentSourceIdProvider.overrideWith(
          () => _RemoteProxyCurrentSourceIdController(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(lastPlaybackDiagnosticsProvider.notifier).state =
        PlaybackDiagnostics(
      capturedAt: DateTime(2026, 6, 17, 1, 2, 3),
      animeTitle: 'Anime 1',
      episodeTitle: 'Episode 2',
      selectedAppSourceId: 'remote-proxy',
      sourceId: 'mock',
      requestedSourceId: 'sakura',
      playSourceTitle: 'Line 1',
      urlType: 'm3u8',
      sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
      headerKeys: const ['Referer'],
      state: PlaybackDiagnosticState.buffering,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: RuntimeDiagnosticsPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Selected app source'), findsOneWidget);
    expect(find.text('Selected app source at playback'), findsNothing);
    expect(find.text('Remote Source Proxy'), findsOneWidget);
    expect(
      find.textContaining(
        'This is the latest playback snapshot captured in this session.',
      ),
      findsOneWidget,
    );
    expect(find.text('Selected playback source'), findsNothing);
    expect(
      find.textContaining(
        'Playback source status: Sakura Anime is temporarily unavailable. AniDestiny is playing from Mock Anime Source instead.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Selected app source at playback: Remote Source Proxy',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'runtime diagnostics keeps the captured app source after the live source changes',
      (tester) async {
    final container = ProviderContainer(overrides: _providerOverrides);
    addTearDown(container.dispose);
    container.read(lastPlaybackDiagnosticsProvider.notifier).state =
        PlaybackDiagnostics(
      capturedAt: DateTime(2026, 6, 17, 1, 2, 3),
      animeTitle: 'Anime 1',
      episodeTitle: 'Episode 2',
      selectedAppSourceId: 'remote-proxy',
      sourceId: 'mock',
      requestedSourceId: 'sakura',
      playSourceTitle: 'Line 1',
      urlType: 'm3u8',
      sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
      headerKeys: const ['Referer'],
      state: PlaybackDiagnosticState.buffering,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: RuntimeDiagnosticsPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Selected app source at playback'), findsNothing);
    expect(find.text('Remote Source Proxy'), findsNothing);
    expect(
      find.textContaining(
        'Selected app source at playback: Remote Source Proxy',
      ),
      findsOneWidget,
    );
  });

  testWidgets('source diagnostics sheet sanitizes inline support details', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        home: const SourceSettingsPage(),
        overrides: [
          ..._providerOverrides,
          sourceHealthControllerProvider.overrideWith(
            () => _SensitiveSourceHealthController(),
          ),
          sourceFallbackEventsProvider.overrideWith(
            () => _SensitiveSourceFallbackEventsController(),
          ),
          sourceDiagnosticsControllerProvider.overrideWith(
            () => _SensitiveSourceDiagnosticsController(),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Source diagnostics'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('HTML document omitted'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('[sensitive]=[hidden]'), findsWidgets);
    expect(find.textContaining('HTML document omitted'), findsOneWidget);
    expect(find.textContaining('token=secret'), findsNothing);
    expect(find.textContaining('session=abc123'), findsNothing);
  });
}

Widget _buildApp({
  required Widget home,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: home),
    ),
  );
}

final _providerOverrides = <Override>[
  sourceListProvider.overrideWith(
    (ref) => const [
      AnimeSource(
        id: 'mock',
        name: 'Mock',
        description: 'Mock source description',
        enabled: false,
      ),
      AnimeSource(
        id: 'sakura',
        name: 'Sakura Anime',
        description: 'Sakura source description',
        enabled: true,
      ),
    ],
  ),
  currentSourceIdProvider.overrideWith(
    () => _FakeCurrentSourceIdController(),
  ),
  sourceHealthControllerProvider.overrideWith(
    () => _FakeSourceHealthController(),
  ),
  sourceFallbackEventsProvider.overrideWith(
    () => _FakeSourceFallbackEventsController(),
  ),
  sourceDiagnosticsControllerProvider.overrideWith(
    () => _FakeSourceDiagnosticsController(),
  ),
  danmakuSettingsProvider.overrideWith(
    (ref) => const DanmakuSettings.defaults(),
  ),
];

class _FakeCurrentSourceIdController extends CurrentSourceIdController {
  @override
  Future<String> build() async => 'sakura';
}

class _RemoteProxyCurrentSourceIdController extends CurrentSourceIdController {
  @override
  Future<String> build() async => 'remote-proxy';
}

class _FakeSourceHealthController extends SourceHealthController {
  @override
  List<SourceHealth> build() {
    return const [
      SourceHealth(
        sourceId: 'sakura',
        status: SourceHealthStatus.healthy,
        failureCount: 0,
      ),
      SourceHealth(
        sourceId: 'mock',
        status: SourceHealthStatus.degraded,
        failureCount: 2,
        lastErrorMessage: 'Connection failed',
      ),
    ];
  }
}

class _FakeSourceFallbackEventsController
    extends SourceFallbackEventsController {
  @override
  List<SourceFallbackEvent> build() {
    return [
      SourceFallbackEvent(
        fromSourceId: 'sakura',
        toSourceId: 'mock',
        operation: 'detail',
        reason: 'Fallback triggered',
        timestamp: DateTime(2026, 6, 7, 1, 2, 3),
      ),
    ];
  }
}

class _FakeSourceDiagnosticsController extends SourceDiagnosticsController {
  @override
  List<SourceDiagnostic> build() {
    return [
      SourceDiagnostic(
        sourceId: 'sakura',
        operation: 'detail',
        level: SourceDiagnosticLevel.warning,
        message: 'Detail request failed',
        fromSourceId: 'sakura',
        toSourceId: 'mock',
        usedFallback: true,
        reason: 'Fallback triggered',
        timestamp: DateTime(2026, 6, 7, 1, 2, 3),
      ),
    ];
  }
}

class _SensitiveSourceHealthController extends SourceHealthController {
  @override
  List<SourceHealth> build() {
    return const [
      SourceHealth(
        sourceId: 'sakura',
        status: SourceHealthStatus.degraded,
        failureCount: 1,
        lastErrorMessage: 'token=secret',
      ),
    ];
  }
}

class _SensitiveSourceFallbackEventsController
    extends SourceFallbackEventsController {
  @override
  List<SourceFallbackEvent> build() {
    return [
      SourceFallbackEvent(
        fromSourceId: 'sakura',
        toSourceId: 'mock',
        operation: 'detail',
        reason: 'session=abc123',
        timestamp: DateTime(2026, 6, 7, 1, 2, 3),
      ),
    ];
  }
}

class _SensitiveSourceDiagnosticsController
    extends SourceDiagnosticsController {
  @override
  List<SourceDiagnostic> build() {
    return [
      SourceDiagnostic(
        sourceId: 'sakura',
        operation: 'detail',
        level: SourceDiagnosticLevel.warning,
        message: '<html><body>token=secret</body></html>',
        fromSourceId: 'sakura',
        toSourceId: 'mock',
        usedFallback: true,
        reason: 'cookie=session=abc123',
        timestamp: DateTime(2026, 6, 7, 1, 2, 3),
      ),
    ];
  }
}
