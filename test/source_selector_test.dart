import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/source/domain/entities/anime_source.dart';
import 'package:ani_destiny/features/source/domain/entities/source_health.dart';
import 'package:ani_destiny/features/source/presentation/widgets/source_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('source selector hides raw source ids from settings users', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Material(
          child: SourceSelector(
            sources: [
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
            currentSourceId: 'sakura',
            healthBySourceId: {
              'mock': SourceHealth.initial('mock'),
              'sakura': SourceHealth.initial('sakura'),
            },
            onSelected: _noop,
            onResetHealth: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('id:'), findsNothing);
    expect(find.text('Mock Anime Source'), findsOneWidget);
    expect(find.text('Sakura Anime'), findsOneWidget);
  });
}

void _noop(String _) {}
