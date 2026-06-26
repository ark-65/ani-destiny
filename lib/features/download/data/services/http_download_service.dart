import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/download_failure_reason.dart';
import '../../domain/entities/download_kind.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/services/download_service.dart';

class HttpDownloadService implements DownloadService {
  HttpDownloadService({
    required Dio dio,
    required DownloadRepository repository,
  })  : _dio = dio,
        _repository = repository;

  final Dio _dio;
  final DownloadRepository _repository;
  final Map<String, CancelToken> _tokens = {};
  final Map<String, StreamController<DownloadProgress>> _controllers = {};

  @override
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  }) async {
    final now = DateTime.now();
    final taskId = 'download-${now.microsecondsSinceEpoch}';
    final unsupportedMessage = _unsupportedMessage(source.kind);
    final status = unsupportedMessage == null
        ? DownloadStatus.pending
        : DownloadStatus.unsupported;
    await _repository.upsertTask(
      DownloadTask(
        id: taskId,
        animeId: animeId,
        episodeId: episodeId,
        sourceId: sourceId,
        title: title,
        episodeTitle: episodeTitle,
        url: source.url,
        kind: source.kind,
        headers: source.headers,
        status: status,
        failureReason: unsupportedMessage == null
            ? DownloadFailureReason.none
            : DownloadFailureReason.unsupportedType,
        failureMessage: unsupportedMessage,
        progress: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emit(taskId, 0, status);
    return taskId;
  }

  @override
  Future<void> start(String taskId) async {
    final existingTask = await _repository.getTask(taskId);
    if (existingTask == null) {
      throw const AppException(
        'Download task not found.',
        code: 'download_not_found',
      );
    }
    if (existingTask.kind != DownloadKind.directFile) {
      final updated = existingTask.copyWith(
        status: DownloadStatus.unsupported,
        failureReason: DownloadFailureReason.unsupportedType,
        failureMessage: _unsupportedMessage(existingTask.kind),
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(updated);
      _emitTask(updated);
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _safeFileName(_fileNameFor(existingTask));
      final localPath = p.join(directory.path, 'downloads', fileName);
      await Directory(p.dirname(localPath)).create(recursive: true);
      final token = CancelToken();
      _tokens[taskId] = token;
      var lastDownloadedBytes = 0;
      int? lastTotalBytes;

      final preparingTask = existingTask.copyWith(
        localPath: localPath,
        status: DownloadStatus.preparing,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 0,
        totalBytes: null,
        downloadedBytes: 0,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(preparingTask);
      _emit(taskId, preparingTask.progress, DownloadStatus.preparing);

      await _dio.download(
        existingTask.url,
        localPath,
        cancelToken: token,
        options: Options(headers: existingTask.headers),
        onReceiveProgress: (received, total) {
          final totalBytes = total > 0 ? total : null;
          lastDownloadedBytes = received;
          lastTotalBytes = totalBytes ?? lastTotalBytes;
          final progress = totalBytes == null
              ? 0.0
              : (received / totalBytes).clamp(0.0, 1.0).toDouble();
          unawaited(
            _repository.upsertTask(
              preparingTask.copyWith(
                localPath: localPath,
                status: DownloadStatus.downloading,
                progress: progress,
                totalBytes: totalBytes,
                downloadedBytes: received,
                failureReason: DownloadFailureReason.none,
                updatedAt: DateTime.now(),
              ),
            ),
          );
          _emit(
            taskId,
            progress,
            DownloadStatus.downloading,
            downloadedBytes: received,
            totalBytes: totalBytes,
          );
        },
      );
      final completedTask = preparingTask.copyWith(
        localPath: localPath,
        status: DownloadStatus.completed,
        progress: 1,
        totalBytes: lastTotalBytes,
        downloadedBytes: lastDownloadedBytes,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(completedTask);
      _emit(
        taskId,
        1,
        DownloadStatus.completed,
        downloadedBytes: lastDownloadedBytes,
        totalBytes: lastTotalBytes,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        await _finalizeCanceledDownload(taskId);
        return;
      }
      final latest = await _repository.getTask(taskId) ?? existingTask;
      final failed = latest.copyWith(
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.networkError,
        failureMessage: _messageFromError(error),
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      throw AppException(
        failed.failureMessage ?? 'Download failed.',
        code: 'download_network_error',
        cause: error,
      );
    } on FileSystemException catch (error) {
      final latest = await _repository.getTask(taskId) ?? existingTask;
      final failed = latest.copyWith(
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.storageUnavailable,
        failureMessage: error.message,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      throw AppException(
        failed.failureMessage ?? 'Storage is unavailable.',
        code: 'download_storage_unavailable',
        cause: error,
      );
    } on Object catch (error) {
      final latest = await _repository.getTask(taskId) ?? existingTask;
      final failed = latest.copyWith(
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.unknown,
        failureMessage: error.toString(),
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      rethrow;
    } finally {
      _tokens.remove(taskId);
    }
  }

  @override
  Future<void> pause(String taskId) async {
    final hadActiveDownload = _tokens.containsKey(taskId);
    _tokens[taskId]?.cancel('paused');
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    if (!_canPause(task.status)) return;
    final clearedLocalPath = await _clearDiscardedDownload(
      localPath: task.localPath,
      clearNow: !hadActiveDownload,
    );
    final updated = task.copyWith(
      localPath: clearedLocalPath,
      status: DownloadStatus.paused,
      failureReason: DownloadFailureReason.none,
      failureMessage: null,
      progress: 0,
      totalBytes: null,
      downloadedBytes: 0,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertTask(updated);
    _emitTask(updated);
  }

  @override
  Future<void> cancel(String taskId) async {
    final hadActiveDownload = _tokens.containsKey(taskId);
    _tokens[taskId]?.cancel('canceled');
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    if (!_canCancel(task.status)) return;
    final clearedLocalPath = await _clearDiscardedDownload(
      localPath: task.localPath,
      clearNow: !hadActiveDownload,
    );
    final updated = task.copyWith(
      localPath: clearedLocalPath,
      status: DownloadStatus.canceled,
      failureReason: DownloadFailureReason.canceled,
      failureMessage: null,
      progress: 0,
      totalBytes: null,
      downloadedBytes: 0,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertTask(updated);
    _emitTask(updated);
  }

  @override
  Future<void> removeEndedTask(String taskId) async {
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    if (!_canRemove(task.status)) {
      throw const AppException(
        'This download is still active.',
        code: 'download_remove_not_allowed',
      );
    }

    if (_requiresManualCleanupBeforeRemoval(task)) {
      final clearedLocalPath = await _clearDiscardedDownload(
        localPath: task.localPath,
        clearNow: true,
      );
      if (clearedLocalPath != null) {
        final updated = task.copyWith(
          localPath: clearedLocalPath,
          updatedAt: DateTime.now(),
        );
        await _repository.upsertTask(updated);
        _emitTask(updated);
        throw const AppException(
          'The leftover partial file still needs manual cleanup.',
          code: 'download_manual_cleanup_required',
        );
      }
    }

    await _repository.deleteTask(taskId);
    _tokens.remove(taskId);
    final controller = _controllers.remove(taskId);
    if (controller != null) {
      unawaited(controller.close());
    }
  }

  @override
  Stream<DownloadProgress> watchProgress(String taskId) {
    return _controllerFor(taskId).stream;
  }

  StreamController<DownloadProgress> _controllerFor(String taskId) {
    return _controllers.putIfAbsent(
      taskId,
      () => StreamController<DownloadProgress>.broadcast(),
    );
  }

  void _emitTask(DownloadTask task) {
    _emit(
      task.id,
      task.progress,
      task.status,
      downloadedBytes: task.downloadedBytes,
      totalBytes: task.totalBytes,
    );
  }

  void _emit(
    String taskId,
    double progress,
    DownloadStatus status, {
    int downloadedBytes = 0,
    int? totalBytes,
  }) {
    final controller = _controllerFor(taskId);
    if (!controller.isClosed) {
      controller.add(
        DownloadProgress(
          taskId: taskId,
          progress: progress,
          status: status,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        ),
      );
    }
  }

  String _fileNameFor(DownloadTask task) {
    final path = Uri.tryParse(task.url)?.path ?? '';
    final extension = p.extension(path).isEmpty ? '.mp4' : p.extension(path);
    return '${task.title}-${task.episodeTitle}$extension';
  }

  bool _canPause(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.preparing || DownloadStatus.downloading => true,
      DownloadStatus.pending ||
      DownloadStatus.paused ||
      DownloadStatus.completed ||
      DownloadStatus.failed ||
      DownloadStatus.canceled ||
      DownloadStatus.unsupported =>
        false,
    };
  }

  bool _canCancel(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.downloading ||
      DownloadStatus.paused =>
        true,
      DownloadStatus.completed ||
      DownloadStatus.failed ||
      DownloadStatus.canceled ||
      DownloadStatus.unsupported =>
        false,
    };
  }

  bool _canRemove(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.completed ||
      DownloadStatus.failed ||
      DownloadStatus.canceled ||
      DownloadStatus.unsupported =>
        true,
      DownloadStatus.pending ||
      DownloadStatus.preparing ||
      DownloadStatus.downloading ||
      DownloadStatus.paused =>
        false,
    };
  }

  bool _requiresManualCleanupBeforeRemoval(DownloadTask task) {
    return task.status == DownloadStatus.canceled && task.localPath != null;
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  }

  String? _unsupportedMessage(DownloadKind kind) {
    return switch (kind) {
      DownloadKind.directFile => null,
      DownloadKind.hls => 'HLS offline download is not implemented yet.',
      DownloadKind.bt => 'BT download is not implemented yet.',
      DownloadKind.unknown => 'This download URL type is not supported yet.',
    };
  }

  String _messageFromError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'Download failed with HTTP $statusCode.';
    }
    return error.message ?? 'Network request could not be completed.';
  }

  Future<void> _finalizeCanceledDownload(String taskId) async {
    final latest = await _repository.getTask(taskId);
    if (latest == null) return;
    if (latest.status != DownloadStatus.paused &&
        latest.status != DownloadStatus.canceled) {
      return;
    }

    final clearedLocalPath = await _clearDiscardedDownload(
      localPath: latest.localPath,
      clearNow: true,
    );
    if (clearedLocalPath == latest.localPath) return;

    final updated = latest.copyWith(
      localPath: clearedLocalPath,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertTask(updated);
    _emitTask(updated);
  }

  Future<String?> _clearDiscardedDownload({
    required String? localPath,
    required bool clearNow,
  }) async {
    if (localPath == null) return null;
    if (!clearNow) return localPath;
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      return null;
    } on FileSystemException {
      return localPath;
    }
  }
}
