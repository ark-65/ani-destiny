import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import 'l10n/app_localizations.dart';
import '../features/anime/presentation/pages/anime_detail_page.dart';
import '../features/anime/presentation/pages/schedule_page.dart';
import '../features/anime/presentation/pages/search_page.dart';
import '../features/download/presentation/pages/download_page.dart';
import '../features/favorite/presentation/pages/favorite_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/player/domain/entities/player_route_args.dart';
import '../features/player/presentation/pages/player_page.dart';
import '../features/settings/presentation/pages/runtime_diagnostics_page.dart';
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
        if (kDebugMode)
          GoRoute(
            path: '/settings/diagnostics',
            builder: (context, state) => const RuntimeDiagnosticsPage(),
          ),
      ],
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => PlayerPage(
        args: playerRouteArgsFromUri(state.uri, extra: state.extra),
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

@visibleForTesting
PlayerRouteArgs playerRouteArgsFromUri(Uri uri, {Object? extra}) {
  if (extra is PlayerRouteArgs) return extra;

  final query = uri.queryParameters;
  final title = query['title'] ?? 'AniDestiny';
  return PlayerRouteArgs(
    animeId: query['animeId'] ?? '',
    episodeId: query['episodeId'] ?? '',
    animeTitle: title,
    episodeTitle: query['episodeTitle'] ?? title,
    coverUrl: query['coverUrl'],
    sourceId: query['sourceId'] ?? AppConstants.defaultSourceId,
    playUrl: query['playUrl'] ?? '',
    playSourceId: query['playSourceId'],
    playSourceTitle: query['playSourceTitle'],
    playHeaders: _decodePlayHeaders(query['playHeaders']),
    episodeIndex: int.tryParse(query['episodeIndex'] ?? ''),
    initialPosition: _decodePosition(query['initialPositionMs']),
  );
}

Map<String, String> _decodePlayHeaders(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(utf8.decode(base64Url.decode(raw)));
    if (decoded is! Map) return const {};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  } on Object {
    return const {};
  }
}

Duration? _decodePosition(String? raw) {
  final milliseconds = int.tryParse(raw ?? '');
  if (milliseconds == null || milliseconds <= 0) return null;
  return Duration(milliseconds: milliseconds);
}
