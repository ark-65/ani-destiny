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
    final task = await _repository.getTask(taskId);
    if (task == null) {
      throw const AppException(
        'Download task not found.',
        code: 'download_not_found',
      );
    }
    if (task.kind != DownloadKind.directFile) {
      final updated = task.copyWith(
        status: DownloadStatus.unsupported,
        failureReason: DownloadFailureReason.unsupportedType,
        failureMessage: _unsupportedMessage(task.kind),
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(updated);
      _emitTask(updated);
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _safeFileName(_fileNameFor(task));
      final localPath = p.join(directory.path, 'downloads', fileName);
      await Directory(p.dirname(localPath)).create(recursive: true);
      final token = CancelToken();
      _tokens[taskId] = token;
      var lastDownloadedBytes = task.downloadedBytes;
      int? lastTotalBytes = task.totalBytes;

      await _repository.upsertTask(
        task.copyWith(
          localPath: localPath,
          status: DownloadStatus.preparing,
          failureReason: DownloadFailureReason.none,
          failureMessage: null,
          updatedAt: DateTime.now(),
        ),
      );
      _emit(taskId, task.progress, DownloadStatus.preparing);

      await _dio.download(
        task.url,
        localPath,
        cancelToken: token,
        options: Options(headers: task.headers),
        onReceiveProgress: (received, total) {
          final totalBytes = total > 0 ? total : null;
          lastDownloadedBytes = received;
          lastTotalBytes = totalBytes ?? lastTotalBytes;
          final progress = totalBytes == null
              ? task.progress
              : (received / totalBytes).clamp(0.0, 1.0).toDouble();
          unawaited(
            _repository.upsertTask(
              task.copyWith(
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
      await _repository.upsertTask(
        task.copyWith(
          localPath: localPath,
          status: DownloadStatus.completed,
          progress: 1,
          totalBytes: lastTotalBytes,
          downloadedBytes: lastDownloadedBytes,
          failureReason: DownloadFailureReason.none,
          failureMessage: null,
          updatedAt: DateTime.now(),
        ),
      );
      _emit(
        taskId,
        1,
        DownloadStatus.completed,
        downloadedBytes: lastDownloadedBytes,
        totalBytes: lastTotalBytes,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      final failed = task.copyWith(
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
      final failed = task.copyWith(
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
      final latest = await _repository.getTask(taskId) ?? task;
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
    _tokens[taskId]?.cancel('paused');
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    final updated = task.copyWith(
      status: DownloadStatus.paused,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertTask(updated);
    _emitTask(updated);
  }

  @override
  Future<void> cancel(String taskId) async {
    _tokens[taskId]?.cancel('canceled');
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    final updated = task.copyWith(
      status: DownloadStatus.canceled,
      failureReason: DownloadFailureReason.canceled,
      failureMessage: null,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertTask(updated);
    _emitTask(updated);
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
}
