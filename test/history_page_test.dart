import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime_detail.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_result.dart';
import 'package:ani_destiny/features/anime/domain/repositories/anime_repository.dart';
import 'package:ani_destiny/features/anime/presentation/providers/anime_providers.dart';
import 'package:ani_destiny/features/history/domain/entities/watch_history.dart';
import 'package:ani_destiny/features/history/domain/repositories/history_repository.dart';
import 'package:ani_destiny/features/history/presentation/pages/history_page.dart';
import 'package:ani_destiny/features/history/presentation/providers/history_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('history continue shows fallback reason in snackbar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(
            const _FakeHistoryRepository(),
          ),
          animeRepositoryProvider.overrideWithValue(
            const _FakeAnimeRepository(
              usedFallback: true,
              fromSourceId: 'mock',
              fallbackMessage: 'Mock source temporarily returned DNS error.',
            ),
          ),
        ],
        child: _buildApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Episode 1'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Mock source temporarily returned DNS error.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'history continue strips fallback boilerplate from service message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(
            const _FakeHistoryRepository(),
          ),
          animeRepositoryProvider.overrideWithValue(
            const _FakeAnimeRepository(
              usedFallback: true,
              fromSourceId: 'mock',
              fallbackMessage:
                  'Selected source is temporarily unavailable. AniDestiny is showing another source instead. Fallback reason: Mock source temporarily returned DNS error.',
            ),
          ),
        ],
        child: _buildApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Episode 1'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Mock source temporarily returned DNS error.'),
      findsOneWidget,
    );
    expect(find.textContaining('Fallback reason:'), findsNothing);
  });
}

Widget _buildApp() {
  final router = GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (context, state) => const Scaffold(body: HistoryPage()),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('history fallback test player target')),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );
}

class _FakeHistoryRepository implements HistoryRepository {
  const _FakeHistoryRepository();

  @override
  Future<void> clear() async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> upsert(WatchHistory history) async {}

  @override
  Stream<List<WatchHistory>> watchHistory() {
    return Stream.value([
      WatchHistory(
        id: 'history-1',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        animeTitle: 'Nebula Drift',
        episodeTitle: 'Episode 1',
        position: Duration.zero,
        updatedAt: DateTime(2026, 7, 1),
        sourceId: 'sakura',
      ),
    ]);
  }

  @override
  Future<WatchHistory?> getByEpisode(String episodeId) async => null;
}

class _FakeAnimeRepository implements AnimeRepository {
  const _FakeAnimeRepository({
    this.usedFallback = false,
    this.fromSourceId,
    this.fallbackMessage,
  });

  final bool usedFallback;
  final String? fromSourceId;
  final String? fallbackMessage;

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) async {
    return SourceFallbackResult<List<PlaySource>>(
      value: const [
        PlaySource(
          id: 'source-1',
          episodeId: 'episode-1',
          title: 'Direct line',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
      ],
      sourceId: sourceId,
      usedFallback: usedFallback,
      fromSourceId: fromSourceId,
      message: fallbackMessage,
    );
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(String episodeId) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations() {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule() {
    throw UnimplementedError();
  }
}
