enum OfflineMediaIntegrityStatus { unknown, playable, damaged }

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
    this.integrityStatus = OfflineMediaIntegrityStatus.unknown,
    this.verifiedAt,
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
  final OfflineMediaIntegrityStatus integrityStatus;
  final DateTime? verifiedAt;

  OfflineMediaItem copyWith({
    OfflineMediaIntegrityStatus? integrityStatus,
    DateTime? verifiedAt,
  }) {
    return OfflineMediaItem(
      id: id,
      downloadTaskId: downloadTaskId,
      animeId: animeId,
      episodeId: episodeId,
      title: title,
      episodeTitle: episodeTitle,
      manifestPath: manifestPath,
      downloadedBytes: downloadedBytes,
      createdAt: createdAt,
      integrityStatus: integrityStatus ?? this.integrityStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
