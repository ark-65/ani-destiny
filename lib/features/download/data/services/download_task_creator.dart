import '../../domain/entities/download_source.dart';
import '../../domain/services/download_service.dart';
import '../../domain/services/download_type_detector.dart';

class DownloadTaskCreator {
  const DownloadTaskCreator(this._service);

  final DownloadService _service;

  Future<String> create({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required String url,
    required String title,
    required String episodeTitle,
    Map<String, String> headers = const {},
    String? fileName,
    String? mimeType,
  }) {
    return _service.createTask(
      animeId: animeId,
      episodeId: episodeId,
      sourceId: sourceId,
      source: DownloadSource(
        url: url,
        kind: detectDownloadKind(url, contentType: mimeType),
        headers: headers,
        fileName: fileName,
        mimeType: mimeType,
      ),
      title: title,
      episodeTitle: episodeTitle,
    );
  }
}
