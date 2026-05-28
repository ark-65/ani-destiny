import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/download_progress.dart';
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
    required String url,
    required String title,
    required String episodeTitle,
  }) async {
    final now = DateTime.now();
    final taskId = 'http-${now.microsecondsSinceEpoch}';
    await _repository.upsertTask(
      DownloadTask(
        id: taskId,
        animeId: animeId,
        episodeId: episodeId,
        title: title,
        episodeTitle: episodeTitle,
        url: url,
        status: DownloadStatus.queued,
        progress: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emit(taskId, 0, DownloadStatus.queued);
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

    // TODO(anidestiny): Add Android/iOS storage permission handling before enabling
    // production downloads outside the app documents directory.
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _safeFileName('${task.title}-${task.episodeTitle}.mp4');
    final localPath = p.join(directory.path, 'downloads', fileName);
    await Directory(p.dirname(localPath)).create(recursive: true);
    final token = CancelToken();
    _tokens[taskId] = token;

    await _repository.upsertTask(
      task.copyWith(
        localPath: localPath,
        status: DownloadStatus.running,
        updatedAt: DateTime.now(),
      ),
    );
    _emit(taskId, task.progress, DownloadStatus.running);

    try {
      await _dio.download(
        task.url,
        localPath,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final progress = (received / total).clamp(0.0, 1.0).toDouble();
          _repository.upsertTask(
            task.copyWith(
              localPath: localPath,
              status: DownloadStatus.running,
              progress: progress,
              updatedAt: DateTime.now(),
            ),
          );
          _emit(taskId, progress, DownloadStatus.running);
        },
      );
      await _repository.upsertTask(
        task.copyWith(
          localPath: localPath,
          status: DownloadStatus.completed,
          progress: 1,
          updatedAt: DateTime.now(),
        ),
      );
      _emit(taskId, 1, DownloadStatus.completed);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      await _repository.upsertTask(
        task.copyWith(
          status: DownloadStatus.failed,
          updatedAt: DateTime.now(),
        ),
      );
      _emit(taskId, task.progress, DownloadStatus.failed);
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
    await _repository.upsertTask(
      task.copyWith(
        status: DownloadStatus.paused,
        updatedAt: DateTime.now(),
      ),
    );
    _emit(taskId, task.progress, DownloadStatus.paused);
  }

  @override
  Future<void> cancel(String taskId) async {
    _tokens[taskId]?.cancel('canceled');
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    await _repository.upsertTask(
      task.copyWith(
        status: DownloadStatus.canceled,
        updatedAt: DateTime.now(),
      ),
    );
    _emit(taskId, task.progress, DownloadStatus.canceled);
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

  void _emit(String taskId, double progress, DownloadStatus status) {
    final controller = _controllerFor(taskId);
    if (!controller.isClosed) {
      controller.add(
        DownloadProgress(
          taskId: taskId,
          progress: progress,
          status: status,
        ),
      );
    }
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  }
}
