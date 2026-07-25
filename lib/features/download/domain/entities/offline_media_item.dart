class OfflineMediaItem {
  const OfflineMediaItem({
    required this.id,
    required this.downloadTaskId,
    required this.animeId,
    required this.episodeId,
    required this.title,
    required this.episodeTitle,
    required this.manifestPath,
    required this.downloadedBytes,
    required this.createdAt,
  });

  final String id;
  final String downloadTaskId;
  final String animeId;
  final String episodeId;
  final String title;
  final String episodeTitle;
  final String manifestPath;
  final int downloadedBytes;
  final DateTime createdAt;
}
