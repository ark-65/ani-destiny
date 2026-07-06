import '../../../../core/error/app_exception.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/services/download_service.dart';

const _unsupportedBtDownloadMessage =
    'AniDestiny cannot save BT or magnet downloads offline yet.';

class UnsupportedBtDownloadService implements DownloadService {
  const UnsupportedBtDownloadService();

  @override
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  }) async {
    throw const AppException(
      _unsupportedBtDownloadMessage,
      code: 'download_unsupported_type',
    );
  }

  @override
  Future<void> start(String taskId) async {
    throw const AppException(
      _unsupportedBtDownloadMessage,
      code: 'download_unsupported_type',
    );
  }

  @override
  Future<void> pause(String taskId) async {
    throw const AppException(
      _unsupportedBtDownloadMessage,
      code: 'download_unsupported_type',
    );
  }

  @override
  Future<void> cancel(String taskId) async {
    throw const AppException(
      _unsupportedBtDownloadMessage,
      code: 'download_unsupported_type',
    );
  }

  @override
  Future<void> removeEndedTask(String taskId) async {
    throw const AppException(
      _unsupportedBtDownloadMessage,
      code: 'download_unsupported_type',
    );
  }

  @override
  Stream<DownloadProgress> watchProgress(String taskId) => const Stream.empty();
}
