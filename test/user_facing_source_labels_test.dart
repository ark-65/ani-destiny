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
  test('unknown source ids fall back to neutral localized labels', () {
    const l10n = AppLocalizations(Locale('en'));

    expect(
      l10n.sourceDisplayName('beta-source', 'beta-source'),
      'Unknown source',
    );
    expect(
      l10n.sourceDisplayName('beta-source', 'Beta Source'),
      'Beta Source',
    );
    expect(
      l10n.sourceDisplayDescription('beta-source', 'beta-source'),
      'No description is available for this source yet.',
    );
  });

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

    expect(find.text('Sakura Anime'), findsOneWidget);
    expect(find.text('sakura'), findsNothing);
  });

  testWidgets('schedule fallback notice avoids fallback-data jargon', (
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
              usedFallback: true,
              fromSourceId: 'mock',
            ),
          ),
        ],
        child: _buildLocalizedApp(home: const SchedulePage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'The current source is temporarily unavailable. AniDestiny is showing content from another source instead.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'The current source is temporarily unavailable. Showing fallback data.',
      ),
      findsNothing,
    );
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
    home: Scaffold(body: home),
  );
}

void _noop() {}
