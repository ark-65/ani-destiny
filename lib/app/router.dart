import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import '../features/anime/presentation/pages/anime_detail_page.dart';
import '../features/anime/presentation/pages/schedule_page.dart';
import '../features/anime/presentation/pages/search_page.dart';
import '../features/download/presentation/pages/download_page.dart';
import '../features/favorite/presentation/pages/favorite_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/player/presentation/pages/player_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/source/presentation/pages/source_settings_page.dart';
import '../shared/widgets/app_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchPage(),
          ),
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) => const SchedulePage(),
        ),
        GoRoute(
          path: '/anime/:animeId',
          builder: (context, state) => AnimeDetailPage(
            animeId: state.pathParameters['animeId'] ?? '',
            sourceId: state.uri.queryParameters['sourceId'],
          ),
        ),
        GoRoute(
          path: '/favorites',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FavoritePage(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryPage(),
          ),
        ),
        GoRoute(
          path: '/downloads',
          builder: (context, state) => const DownloadPage(),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/settings/sources',
          builder: (context, state) => const SourceSettingsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => PlayerPage(
        animeId: state.uri.queryParameters['animeId'] ?? '',
        episodeId: state.uri.queryParameters['episodeId'] ?? '',
        title: state.uri.queryParameters['title'] ?? 'AniDestiny',
        episodeTitle: state.uri.queryParameters['episodeTitle'],
        coverUrl: state.uri.queryParameters['coverUrl'],
        sourceId: state.uri.queryParameters['sourceId'] ?? 'mock',
        playUrl: state.uri.queryParameters['playUrl'] ?? '',
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.appName)),
    body: Center(
      child: Text('404: ${state.uri}'),
    ),
  ),
);
