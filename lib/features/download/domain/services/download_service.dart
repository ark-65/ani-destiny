import '../entities/download_progress.dart';
import '../entities/download_source.dart';

abstract class DownloadService {
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  });

  Future<void> start(String taskId);

  Future<void> pause(String taskId);

  Future<void> cancel(String taskId);

  Stream<DownloadProgress> watchProgress(String taskId);
}
