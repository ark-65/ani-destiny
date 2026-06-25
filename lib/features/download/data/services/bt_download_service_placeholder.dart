import '../../domain/entities/download_progress.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/services/download_service.dart';

class BtDownloadServicePlaceholder implements DownloadService {
  const BtDownloadServicePlaceholder();

  @override
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  }) {
    // TODO(ark65): Choose a real BT engine and platform permission model before
    // exposing BT tasks in production.
    throw UnimplementedError('BT download is not implemented yet.');
  }

  @override
  Future<void> start(String taskId) {
    throw UnimplementedError('BT download is not implemented yet.');
  }

  @override
  Future<void> pause(String taskId) {
    throw UnimplementedError('BT download is not implemented yet.');
  }

  @override
  Future<void> cancel(String taskId) {
    throw UnimplementedError('BT download is not implemented yet.');
  }

  @override
  Future<void> removeEndedTask(String taskId) {
    throw UnimplementedError('BT download is not implemented yet.');
  }

  @override
  Stream<DownloadProgress> watchProgress(String taskId) {
    throw UnimplementedError('BT download is not implemented yet.');
  }
}
