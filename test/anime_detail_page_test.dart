import 'dart:async';

import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime_detail.dart';
import 'package:ani_destiny/features/anime/domain/entities/episode.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:ani_destiny/features/anime/domain/repositories/anime_repository.dart';
import 'package:ani_destiny/features/anime/presentation/pages/anime_detail_page.dart';
import 'package:ani_destiny/features/anime/presentation/providers/anime_providers.dart';
import 'package:ani_destiny/features/download/domain/entities/download_progress.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/services/download_service.dart';
import 'package:ani_destiny/features/download/data/services/download_task_creator.dart';
import 'package:ani_destiny/features/download/presentation/providers/download_providers.dart';
import 'package:ani_destiny/features/favorite/domain/entities/favorite_anime.dart';
import 'package:ani_destiny/features/favorite/domain/repositories/favorite_repository.dart';
import 'package:ani_destiny/features/favorite/presentation/providers/favorite_providers.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'anime detail shows active fallback source notice in play chooser', (
    tester,
  ) async {
    const repository = _FakeAnimeRepository(
      detail: _detail,
      playSources: [
        PlaySource(
          id: 'source-0',
          episodeId: 'episode-1',
          title: 'Direct line',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
        PlaySource(
          id: 'source-1',
          episodeId: 'episode-1',
          title: 'HLS line',
          url: 'https://cdn.example.com/episode-1.m3u8',
        ),
      ],
      playSourcesUsedFallback: true,
      playSourcesFromSourceId: 'mock',
    );

    await _pumpPage(
      tester,
      animeRepository: repository,
      downloadService: const _FakeDownloadService(),
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(find.textContaining('Select playback'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('temporarily unavailable') ?? false) &&
            (widget.data?.contains('Mock') ?? false) &&
            (widget.data?.contains('Sakura Anime') ?? false),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'anime detail shows explicit fallback source notice on detail page', (
    tester,
  ) async {
    const repository = _FakeAnimeRepository(
      detail: _detail,
      playSources: [
        PlaySource(
          id: 'source-0',
          episodeId: 'episode-1',
          title: 'Direct line',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
      ],
      detailUsedFallback: true,
      detailFromSourceId: 'mock',
    );

    await _pumpPage(
      tester,
      animeRepository: repository,
      downloadService: const _FakeDownloadService(),
    );

    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(find.textContaining('Mock'), findsOneWidget);
  });

  testWidgets('anime detail shows fallback reason in notices', (tester) async {
    const repository = _FakeAnimeRepository(
      detail: _detail,
      playSources: [
        PlaySource(
          id: 'source-0',
          episodeId: 'episode-1',
          title: 'Direct line',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
      ],
      detailUsedFallback: true,
      detailFromSourceId: 'mock',
      playSourcesUsedFallback: true,
      playSourcesFromSourceId: 'mock',
      fallbackMessage: 'Mock source temporarily returned DNS error.',
    );

    await _pumpPage(
      tester,
      animeRepository: repository,
      downloadService: const _FakeDownloadService(),
    );

    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(
      find.textContaining('Mock source temporarily returned DNS error.'),
      findsAtLeastNWidgets(1),
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Mock source temporarily returned DNS error.'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('anime detail strips fallback boilerplate from service message', (
    tester,
  ) async {
    const repository = _FakeAnimeRepository(
      detail: _detail,
      playSources: [
        PlaySource(
          id: 'source-0',
          episodeId: 'episode-1',
          title: 'Direct line',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
      ],
      detailUsedFallback: true,
      detailFromSourceId: 'mock',
      playSourcesUsedFallback: true,
      playSourcesFromSourceId: 'mock',
      fallbackMessage:
          'Selected source is temporarily unavailable. AniDestiny is showing another source instead. Fallback reason: Mock source temporarily returned DNS error.',
    );

    await _pumpPage(
      tester,
      animeRepository: repository,
      downloadService: const _FakeDownloadService(),
    );

    expect(
      find.textContaining('Mock source temporarily returned DNS error.'),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('Fallback reason:'), findsNothing);
  });
  testWidgets('anime detail download keeps unsupported feedback honest', (
    tester,
  ) async {
    const repository = _FakeAnimeRepository(
      detail: _detail,
      playSources: [
        PlaySource(
          id: 'source-0',
          episodeId: 'episode-1',
          title: 'Direct line',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
        PlaySource(
          id: 'source-1',
          episodeId: 'episode-1',
          title: 'HLS line',
          url: 'https://cdn.example.com/episode-1.m3u8',
        ),
      ],
    );

    await _pumpPage(
      tester,
      animeRepository: repository,
      downloadService: const _FakeDownloadService(),
    );

    await tester.tap(find.byTooltip('Check download lines'));
    await tester.pumpAndSettle();

    expect(find.text('Direct line'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains(
                  'Choosing this line adds it to Downloads first.',
                ) ??
                false),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Added to Downloads. Open Downloads to start it.'),
      findsNothing,
    );
    expect(find.text('HLS line'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains(
                  'AniDestiny cannot save that type offline yet',
                ) ??
                false),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('HLS line'));
    await tester.pump();

    expect(
      find.text(
        'This download currently uses an HLS / m3u8 stream, and AniDestiny cannot save that type offline yet. This entry stays in Downloads so you can review it, try another download source, and decide whether to keep or remove it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Review in Downloads'), findsOneWidget);
  });

  testWidgets(
    'anime detail still confirms a single unsupported download line before adding it',
    (tester) async {
      var createdDownloads = 0;
      const repository = _FakeAnimeRepository(
        detail: _detail,
        playSources: [
          PlaySource(
            id: 'source-1',
            episodeId: 'episode-1',
            title: 'HLS line',
            url: 'https://cdn.example.com/episode-1.m3u8',
          ),
        ],
      );

      await _pumpPage(
        tester,
        animeRepository: repository,
        downloadService: _FakeDownloadService(
          onCreate: () => createdDownloads++,
        ),
      );

      await tester.tap(find.byTooltip('Check download lines'));
      await tester.pumpAndSettle();

      expect(createdDownloads, 0);
      expect(find.text('Select download line'), findsOneWidget);
      expect(find.text('HLS line'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains(
                    'AniDestiny cannot save that type offline yet',
                  ) ??
                  false),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('HLS line'));
      await tester.pump();

      expect(createdDownloads, 1);
      expect(
        find.text(
          'This download currently uses an HLS / m3u8 stream, and AniDestiny cannot save that type offline yet. This entry stays in Downloads so you can review it, try another download source, and decide whether to keep or remove it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Review in Downloads'), findsOneWidget);
    },
  );

  testWidgets(
    'anime detail confirms fallback download lines before adding a single direct download',
    (tester) async {
      var createdDownloads = 0;
      const repository = _FakeAnimeRepository(
        detail: _detail,
        playSources: [
          PlaySource(
            id: 'source-1',
            episodeId: 'episode-1',
            title: 'Direct line',
            url: 'https://cdn.example.com/episode-1.mp4',
          ),
        ],
        playSourcesUsedFallback: true,
        playSourcesFromSourceId: 'mock',
      );

      await _pumpPage(
        tester,
        animeRepository: repository,
        downloadService: _FakeDownloadService(
          onCreate: () => createdDownloads++,
        ),
      );

      await tester.tap(find.byTooltip('Check download lines'));
      await tester.pumpAndSettle();

      expect(createdDownloads, 0);
      expect(find.text('Select download line'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('temporarily unavailable') ?? false) &&
              (widget.data?.contains('Mock') ?? false) &&
              (widget.data?.contains('Sakura Anime') ?? false),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Direct line'));
      await tester.pumpAndSettle();

      expect(createdDownloads, 1);
      expect(find.text('Select download line'), findsNothing);
    },
  );

  testWidgets('anime detail download surfaces creation errors calmly', (
    tester,
  ) async {
    const failureMessage = 'Downloads are temporarily unavailable.';
    const repository = _FakeAnimeRepository(
      detail: _detail,
      playSources: [
        PlaySource(
          id: 'source-1',
          episodeId: 'episode-1',
          title: 'Direct file',
          url: 'https://cdn.example.com/episode-1.mp4',
        ),
      ],
    );

    await _pumpPage(
      tester,
      animeRepository: repository,
      downloadService: const _FakeDownloadService(
        createError: AppException(failureMessage, code: 'download_busy'),
      ),
    );

    await tester.tap(find.byTooltip('Check download lines'));
    await tester.pump();

    expect(
      find.text(
        'This download action is still in progress. Please try again in a moment.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('AppException'), findsNothing);
    expect(find.text('Open Downloads'), findsNothing);
  });

  testWidgets(
    'anime detail download hides raw non-app creation errors behind calm fallback copy',
    (tester) async {
      const repository = _FakeAnimeRepository(
        detail: _detail,
        playSources: [
          PlaySource(
            id: 'source-1',
            episodeId: 'episode-1',
            title: 'Direct file',
            url: 'https://cdn.example.com/episode-1.mp4',
          ),
        ],
      );

      await _pumpPage(
        tester,
        animeRepository: repository,
        downloadService: _FakeDownloadService(
          createError: StateError('database handshake failed'),
        ),
      );

      await tester.tap(find.byTooltip('Check download lines'));
      await tester.pump();

      expect(
        find.text(
          'AniDestiny could not finish that download action right now. Try again in a moment.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('database handshake failed'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.text('Open Downloads'), findsNothing);
    },
  );
}

const _detail = AnimeDetail(
  id: 'anime-1',
  title: 'Starlight Voyage',
  description: 'An interstellar test detail page.',
  sourceId: 'sakura',
  episodes: [
    Episode(
      id: 'episode-1',
      animeId: 'anime-1',
      title: 'Episode 1',
      index: 1,
      sourceId: 'sakura',
    ),
  ],
);

Future<void> _pumpPage(
  WidgetTester tester, {
  required AnimeRepository animeRepository,
  required DownloadService downloadService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        animeRepositoryProvider.overrideWithValue(animeRepository),
        favoriteRepositoryProvider.overrideWithValue(
          const _FakeFavoriteRepository(),
        ),
        downloadTaskCreatorProvider.overrideWith(
          (ref) => DownloadTaskCreator(downloadService),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: AnimeDetailPage(
            animeId: 'anime-1',
            sourceId: 'sakura',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAnimeRepository implements AnimeRepository {
  const _FakeAnimeRepository({
    required this.detail,
    required this.playSources,
    this.playSourcesUsedFallback = false,
    this.playSourcesFromSourceId,
    this.detailUsedFallback = false,
    this.detailFromSourceId,
    this.fallbackMessage,
  });

  final AnimeDetail detail;
  final List<PlaySource> playSources;
  final bool playSourcesUsedFallback;
  final String? playSourcesFromSourceId;
  final bool detailUsedFallback;
  final String? detailFromSourceId;
  final String? fallbackMessage;

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    return Future.value(
      SourceFallbackResult<AnimeDetail>(
        value: detail,
        sourceId: detail.sourceId,
        usedFallback: detailUsedFallback,
        fromSourceId: detailFromSourceId,
        message: fallbackMessage,
      ),
    );
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) async {
    return SourceFallbackResult<AnimeDetail>(
      value: detail,
      sourceId: sourceId,
      usedFallback: detailUsedFallback,
      fromSourceId: detailFromSourceId,
      message: fallbackMessage,
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
    return SourceFallbackResult<List<PlaySource>>(
      value: playSources,
      sourceId: sourceId,
      usedFallback: playSourcesUsedFallback,
      fromSourceId: playSourcesFromSourceId,
      message: fallbackMessage,
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

class _FakeDownloadService implements DownloadService {
  const _FakeDownloadService({
    this.createError,
    this.onCreate,
  });

  final Object? createError;
  final void Function()? onCreate;

  @override
  Future<void> cancel(String taskId) {
    throw UnimplementedError();
  }

  @override
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  }) async {
    if (createError != null) {
      throw createError!;
    }
    onCreate?.call();
    return 'task-1';
  }

  @override
  Future<void> pause(String taskId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeEndedTask(String taskId) {
    throw UnimplementedError();
  }

  @override
  Future<void> start(String taskId) {
    throw UnimplementedError();
  }

  @override
  Stream<DownloadProgress> watchProgress(String taskId) {
    return const Stream<DownloadProgress>.empty();
  }
}

class _FakeFavoriteRepository implements FavoriteRepository {
  const _FakeFavoriteRepository();

  @override
  Future<void> add(FavoriteAnime anime) async {}

  @override
  Stream<bool> isFavorite({
    required String sourceId,
    required String animeId,
  }) {
    return Stream<bool>.value(false);
  }

  @override
  Future<void> remove({
    required String sourceId,
    required String animeId,
  }) async {}

  @override
  Future<void> toggle(FavoriteAnime anime) async {}

  @override
  Stream<List<FavoriteAnime>> watchFavorites() {
    return const Stream<List<FavoriteAnime>>.empty();
  }
}
