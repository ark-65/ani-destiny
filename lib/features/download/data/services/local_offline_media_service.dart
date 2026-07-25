import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/offline_media_item.dart';
import '../../domain/repositories/offline_media_repository.dart';
import '../../domain/services/offline_media_integrity.dart';
import '../../domain/services/offline_media_service.dart';

typedef OfflineMediaDirectoryRemover = Future<void> Function(String path);

class LocalOfflineMediaService implements OfflineMediaService {
  const LocalOfflineMediaService({
    required OfflineMediaRepository repository,
    OfflineMediaDirectoryRemover directoryRemover = _removeDirectoryIfPresent,
  })  : _repository = repository,
        _directoryRemover = directoryRemover;

  final OfflineMediaRepository _repository;
  final OfflineMediaDirectoryRemover _directoryRemover;

  @override
  Future<OfflineMediaIntegrityStatus> verify(OfflineMediaItem item) async {
    return isPlayableOfflineMediaPath(item.manifestPath)
        ? OfflineMediaIntegrityStatus.playable
        : OfflineMediaIntegrityStatus.damaged;
  }

  @override
  Future<void> remove(OfflineMediaItem item) async {
    try {
      await _directoryRemover(p.dirname(item.manifestPath));
    } on FileSystemException catch (error) {
      throw AppException(
        'Offline media files could not be removed.',
        code: 'offline_media_cleanup_failed',
        cause: error,
      );
    }
    await _repository.delete(item.id);
  }

  @override
  Future<void> removeAll(Iterable<OfflineMediaItem> items) async {
    for (final item in items) {
      await remove(item);
    }
  }

  static Future<void> _removeDirectoryIfPresent(String path) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
