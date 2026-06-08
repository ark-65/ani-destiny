import '../../../../core/constants/app_constants.dart';

class WatchHistory {
  const WatchHistory({
    required this.id,
    required this.animeId,
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.position,
    required this.updatedAt,
    this.coverUrl,
    this.duration,
    this.sourceId = AppConstants.defaultSourceId,
    this.playSourceId,
    this.playSourceTitle,
    this.playUrl,
    this.playHeaders = const {},
  });

  final String id;
  final String animeId;
  final String episodeId;
  final String animeTitle;
  final String episodeTitle;
  final String? coverUrl;
  final Duration position;
  final Duration? duration;
  final DateTime updatedAt;
  final String sourceId;
  final String? playSourceId;
  final String? playSourceTitle;
  final String? playUrl;
  final Map<String, String> playHeaders;
}
