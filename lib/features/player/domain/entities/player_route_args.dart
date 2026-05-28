import 'package:flutter/foundation.dart';

@immutable
class PlayerRouteArgs {
  const PlayerRouteArgs({
    required this.animeId,
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.playUrl,
    required this.sourceId,
    this.coverUrl,
    this.playSourceId,
    this.playSourceTitle,
    this.playHeaders = const {},
    this.initialPosition,
  });

  final String animeId;
  final String episodeId;
  final String animeTitle;
  final String episodeTitle;
  final String playUrl;
  final String sourceId;
  final String? coverUrl;
  final String? playSourceId;
  final String? playSourceTitle;
  final Map<String, String> playHeaders;
  final Duration? initialPosition;
}
