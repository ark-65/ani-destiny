import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:ani_destiny/features/anime/presentation/pages/schedule_page.dart';
import 'package:ani_destiny/features/anime/presentation/providers/anime_providers.dart';
import 'package:ani_destiny/features/anime/presentation/widgets/search_result_tile.dart';
import 'package:ani_destiny/features/favorite/domain/entities/favorite_anime.dart';
import 'package:ani_destiny/features/favorite/presentation/widgets/favorite_tile.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('favorite tiles show localized source names', (tester) async {
    await tester.pumpWidget(
      _buildLocalizedApp(
        home: Material(
          child: FavoriteTile(
            favorite: FavoriteAnime(
              animeId: 'anime-1',
              title: 'Favorite Title',
              sourceId: 'sakura',
              createdAt: DateTime(2026, 6, 7),
            ),
            onOpen: _noop,
            onRemove: _noop,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sakura Anime'), findsOneWidget);
    expect(find.text('sakura'), findsNothing);
  });

  testWidgets(
    'search result tiles use localized source names as the fallback subtitle',
    (tester) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          home: const Material(
            child: SearchResultTile(
              result: SearchResult(
                animeId: 'anime-1',
                title: 'Search Title',
                sourceId: 'mock',
              ),
              onTap: _noop,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mock Anime Source'), findsOneWidget);
      expect(find.text('mock'), findsNothing);
    },
  );

  testWidgets('schedule rows show localized source names when time is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleProvider.overrideWith(
            (ref) async => const SourceFallbackResult<List<ScheduleItem>>(
              value: [
                ScheduleItem(
                  id: 'schedule-1',
                  animeId: 'anime-1',
                  title: 'Schedule Title',
                  weekday: 1,
                  sourceId: 'sakura',
                ),
              ],
              sourceId: 'sakura',
              usedFallback: false,
            ),
          ),
        ],
        child: _buildLocalizedApp(home: const SchedulePage()),
      ),
    );

    await tester.pumpAndSettle();

    final sourceLabel = find.text('Sakura Anime');
    if (sourceLabel.evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('schedule-weekday-1')));
      await tester.pumpAndSettle();
    }

    expect(sourceLabel, findsOneWidget);
    expect(find.text('sakura'), findsNothing);
  });
}

Widget _buildLocalizedApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void _noop() {}
