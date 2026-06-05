import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/constants/app_constants.dart';
import 'package:ani_destiny/features/anime/domain/entities/episode.dart';
import 'package:ani_destiny/features/anime/presentation/widgets/episode_list.dart';
import 'package:ani_destiny/features/history/domain/entities/watch_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'episode list shows the production default source when sourceId is missing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EpisodeList(
              episodes: const [
                Episode(
                  id: 'ep-1',
                  animeId: 'anime-1',
                  title: 'Episode 1',
                  index: 1,
                ),
              ],
              onPlay: (_) {},
              onDownload: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Sakura Anime'), findsOneWidget);
      expect(find.text('Mock 动漫数据源'), findsNothing);
    },
  );

  test('watch history defaults to the production source id', () {
    final history = WatchHistory(
      id: 'history-1',
      animeId: 'anime-1',
      episodeId: 'ep-1',
      animeTitle: 'Anime',
      episodeTitle: 'Episode 1',
      position: Duration.zero,
      updatedAt: DateTime(2026, 6, 6),
    );

    expect(history.sourceId, AppConstants.defaultSourceId);
  });
}
