enum DownloadStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  canceled,
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.animeId,
    required this.episodeId,
    required this.sourceId,
    required this.title,
    required this.episodeTitle,
    required this.url,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.localPath,
  });

  final String id;
  final String animeId;
  final String episodeId;
  final String sourceId;
  final String title;
  final String episodeTitle;
  final String url;
  final String? localPath;
  final DownloadStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  DownloadTask copyWith({
    String? localPath,
    DownloadStatus? status,
    double? progress,
    DateTime? updatedAt,
  }) {
    return DownloadTask(
      id: id,
      animeId: animeId,
      episodeId: episodeId,
      sourceId: sourceId,
      title: title,
      episodeTitle: episodeTitle,
      url: url,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
