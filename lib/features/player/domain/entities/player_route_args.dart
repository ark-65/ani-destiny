import 'package:flutter/foundation.dart';

@immutable
class PlayerRouteArgs {
  static const _initialPositionUnset = Object();
  static const _requestedSourceIdUnset = Object();

  const PlayerRouteArgs({
    required this.animeId,
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.playUrl,
    required this.sourceId,
    this.coverUrl,
    this.requestedSourceId,
    this.playSourceId,
    this.playSourceTitle,
    this.playHeaders = const {},
    this.episodeIndex,
    this.initialPosition,
  });

  final String animeId;
  final String episodeId;
  final String animeTitle;
  final String episodeTitle;
  final String playUrl;
  final String sourceId;
  final String? coverUrl;
  final String? requestedSourceId;
  final String? playSourceId;
  final String? playSourceTitle;
  final Map<String, String> playHeaders;
  final int? episodeIndex;
  final Duration? initialPosition;

  PlayerRouteArgs copyWith({
    String? animeId,
    String? episodeId,
    String? animeTitle,
    String? episodeTitle,
    String? playUrl,
    String? sourceId,
    String? coverUrl,
    Object? requestedSourceId = _requestedSourceIdUnset,
    String? playSourceId,
    String? playSourceTitle,
    Map<String, String>? playHeaders,
    int? episodeIndex,
    Object? initialPosition = _initialPositionUnset,
  }) {
    return PlayerRouteArgs(
      animeId: animeId ?? this.animeId,
      episodeId: episodeId ?? this.episodeId,
      animeTitle: animeTitle ?? this.animeTitle,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      playUrl: playUrl ?? this.playUrl,
      sourceId: sourceId ?? this.sourceId,
      coverUrl: coverUrl ?? this.coverUrl,
      requestedSourceId: identical(requestedSourceId, _requestedSourceIdUnset)
          ? this.requestedSourceId
          : requestedSourceId as String?,
      playSourceId: playSourceId ?? this.playSourceId,
      playSourceTitle: playSourceTitle ?? this.playSourceTitle,
      playHeaders: playHeaders ?? this.playHeaders,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      initialPosition: identical(initialPosition, _initialPositionUnset)
          ? this.initialPosition
          : initialPosition as Duration?,
    );
  }
}
