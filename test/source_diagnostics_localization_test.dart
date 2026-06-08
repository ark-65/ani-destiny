import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_settings.dart';
import 'package:ani_destiny/features/danmaku/presentation/providers/danmaku_providers.dart';
import 'package:ani_destiny/features/settings/presentation/pages/runtime_diagnostics_page.dart';
import 'package:ani_destiny/features/source/domain/entities/anime_source.dart';
import 'package:ani_destiny/features/source/domain/entities/source_diagnostic.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_event.dart';
import 'package:ani_destiny/features/source/domain/entities/source_health.dart';
import 'package:ani_destiny/features/source/presentation/pages/source_settings_page.dart';
import 'package:ani_destiny/features/source/presentation/providers/source_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

    expect(find.text('Current source'), findsOneWidget);
    expect(find.textContaining('Sakura Anime'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('Mock Anime Source'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Mock Anime Source'), findsWidgets);
    expect(find.text('sakura'), findsNothing);
    expect(find.text('mock'), findsNothing);
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

    expect(find.textContaining('Sakura Anime'), findsWidgets);
    expect(find.textContaining('Mock Anime Source'), findsWidgets);
    expect(find.text('sakura'), findsNothing);
    expect(find.text('mock'), findsNothing);
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
