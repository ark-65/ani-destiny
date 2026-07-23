import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/download_failure_reason.dart';
import '../../domain/entities/download_kind.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/hls_manifest.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/services/hls_manifest_loader.dart';
import '../../domain/services/download_service.dart';

const _downloadNetworkFailureMessage =
    'AniDestiny could not finish this download because the source could not be reached. Retry when the connection is stable.';

class HttpDownloadService implements DownloadService {
  HttpDownloadService({
    required Dio dio,
    required DownloadRepository repository,
    HlsManifestLoader? hlsManifestLoader,
  })  : _dio = dio,
        _repository = repository,
        _hlsManifestLoader = hlsManifestLoader;

  final Dio _dio;
  final DownloadRepository _repository;
  final HlsManifestLoader? _hlsManifestLoader;
  final Map<String, CancelToken> _tokens = {};
  final Map<String, StreamController<DownloadProgress>> _controllers = {};
  final Map<String, Completer<void>> _settleCompleters = {};

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
    final isUnsupported = _isUnsupportedKind(source.kind);
    final status =
        isUnsupported ? DownloadStatus.unsupported : DownloadStatus.pending;
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
        failureReason: isUnsupported
            ? DownloadFailureReason.unsupportedType
            : DownloadFailureReason.none,
        failureMessage: null,
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
    var existingTask = await _repository.getTask(taskId);
    if (existingTask == null) {
      throw const AppException(
        'Download task not found.',
        code: 'download_not_found',
      );
    }
    if (_shouldWaitForSettlement(existingTask)) {
      await _waitForTaskSettlement(taskId);
      existingTask = await _repository.getTask(taskId);
      if (existingTask == null) {
        throw const AppException(
          'Download task not found.',
          code: 'download_not_found',
        );
      }
    }
    if (existingTask.kind != DownloadKind.directFile) {
      if (existingTask.kind == DownloadKind.hls) {
        await _startHlsTask(existingTask);
        return;
      }
      final updated = existingTask.copyWith(
        status: DownloadStatus.unsupported,
        failureReason: DownloadFailureReason.unsupportedType,
        failureMessage: null,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(updated);
      _emitTask(updated);
      return;
    }

    String? activeLocalPath;
    final settleCompleter = Completer<void>();
    _settleCompleters[taskId] = settleCompleter;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _safeFileName(_fileNameFor(existingTask));
      final localPath = p.join(directory.path, 'downloads', fileName);
      activeLocalPath = localPath;
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
        await _finalizeCanceledDownload(
          taskId,
          originalLocalPath: activeLocalPath,
        );
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
        failureMessage: unexpectedDownloadFailureMessage,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      throw AppException(
        unexpectedDownloadFailureMessage,
        code: 'download_unexpected_error',
        cause: error,
      );
    } finally {
      _tokens.remove(taskId);
      if (identical(_settleCompleters[taskId], settleCompleter)) {
        _settleCompleters.remove(taskId);
      }
      if (!settleCompleter.isCompleted) {
        settleCompleter.complete();
      }
    }
  }

  Future<void> _startHlsTask(DownloadTask existingTask) async {
    final manifestLoader = _hlsManifestLoader;
    if (manifestLoader == null) {
      final failed = existingTask.copyWith(
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.unknown,
        failureMessage: 'HLS manifest loader unavailable.',
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      return;
    }

    final sourceUri = Uri.tryParse(existingTask.url);
    if (sourceUri == null || !sourceUri.hasAbsolutePath) {
      final failed = existingTask.copyWith(
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.invalidUrl,
        failureMessage: null,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      return;
    }

    final prepareLocalManifestPath = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'downloads',
      existingTask.id,
      'index.m3u8',
    );
    final settleCompleter = Completer<void>();
    _settleCompleters[existingTask.id] = settleCompleter;
    final token = CancelToken();
    _tokens[existingTask.id] = token;

    final preparingTask = existingTask.copyWith(
      localPath: prepareLocalManifestPath,
      status: DownloadStatus.preparing,
      failureReason: DownloadFailureReason.none,
      failureMessage: null,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: null,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertTask(preparingTask);
    _emitTask(preparingTask);

    try {
      final mediaManifest = await _loadHlsMediaManifest(
        manifestLoader: manifestLoader,
        sourceUri: sourceUri,
        headers: existingTask.headers,
      );
      if (mediaManifest.isLive) {
        final unsupported = preparingTask.copyWith(
          localPath: null,
          status: DownloadStatus.unsupported,
          failureReason: DownloadFailureReason.unsupportedType,
          failureMessage: null,
          updatedAt: DateTime.now(),
        );
        await _repository.upsertTask(unsupported);
        _emitTask(unsupported);
        return;
      }

      final segmentDownloadedBytes = await _downloadHlsSegments(
        task: preparingTask,
        mediaManifest: mediaManifest,
        headers: existingTask.headers,
        cancelToken: token,
      );
      await _writeHlsManifest(mediaManifest, segmentDownloadedBytes, prepareLocalManifestPath);
      final completed = preparingTask.copyWith(
        status: DownloadStatus.completed,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 1,
        downloadedBytes: segmentDownloadedBytes,
        totalBytes: segmentDownloadedBytes,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(completed);
      _emitTask(completed);
      return;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        await _finalizeCanceledDownload(
          existingTask.id,
          originalLocalPath: prepareLocalManifestPath,
        );
        return;
      }
      final failed = preparingTask.copyWith(
        localPath: null,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.networkError,
        failureMessage: _messageFromError(error),
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      return;
    } on FormatException catch (error) {
      final invalidManifest = preparingTask.copyWith(
        localPath: null,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.invalidManifest,
        failureMessage: error.message,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(invalidManifest);
      _emitTask(invalidManifest);
      return;
    } on Object {
      final failed = preparingTask.copyWith(
        localPath: null,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.unknown,
        failureMessage: unexpectedDownloadFailureMessage,
        updatedAt: DateTime.now(),
      );
      await _repository.upsertTask(failed);
      _emitTask(failed);
      return;
    } finally {
      _tokens.remove(existingTask.id);
      if (identical(_settleCompleters[existingTask.id], settleCompleter)) {
        _settleCompleters.remove(existingTask.id);
      }
      if (!settleCompleter.isCompleted) {
        settleCompleter.complete();
      }
    }
  }

  Future<int> _downloadHlsSegments({
    required DownloadTask task,
    required HlsManifest mediaManifest,
    required Map<String, String> headers,
    required CancelToken cancelToken,
  }) async {
    if (mediaManifest.segments.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }

    final segmentDirectory = Directory(
      p.join(
        p.dirname(task.localPath ?? ''),
        'segments',
      ),
    );
    await segmentDirectory.create(recursive: true);

    var downloadedBytes = 0;

    for (var index = 0; index < mediaManifest.segments.length; index++) {
      final segment = mediaManifest.segments[index];
      final safeSegmentName = _hlsSegmentFileName(segment.uri, index);
      final segmentPath = p.join(segmentDirectory.path, safeSegmentName);
      final segmentBytes = await _downloadHlsSegment(
        segmentUri: segment.uri,
        localPath: segmentPath,
        headers: headers,
        cancelToken: cancelToken,
      );

      downloadedBytes += segmentBytes;
      final progress = (index + 1) / mediaManifest.segments.length;
      _emit(
        task.id,
        progress,
        DownloadStatus.downloading,
        downloadedBytes: downloadedBytes,
      );
    }

    return downloadedBytes;
  }

  Future<int> _downloadHlsSegment({
    required Uri segmentUri,
    required String localPath,
    required Map<String, String> headers,
    required CancelToken cancelToken,
  }) async {
    var downloadedBytes = 0;

    await _dio.download(
      segmentUri.toString(),
      localPath,
      cancelToken: cancelToken,
      options: Options(headers: headers.isEmpty ? null : headers),
      onReceiveProgress: (received, total) {
        downloadedBytes = received;
      },
    );

    return downloadedBytes;
  }

  Future<void> _writeHlsManifest(
    HlsManifest manifest,
    int downloadedBytes,
    String manifestPath,
  ) async {
    final manifestLines = <String>[
      '#EXTM3U',
      if (manifest.targetDuration != null)
        '#EXT-X-TARGETDURATION:${manifest.targetDuration!.inSeconds}',
      '#EXT-X-VERSION:3',
      '#EXT-X-MEDIA-SEQUENCE:0',
      '#EXT-X-PLAYLIST-TYPE:VOD',
    ];

    for (var index = 0; index < manifest.segments.length; index++) {
      final segment = manifest.segments[index];
      final segmentName =
          _hlsSegmentFileName(segment.uri, index);
      final duration = segment.duration ?? const Duration(seconds: 1);
      final durationText = (duration.inMilliseconds / 1000).toStringAsFixed(3);
      manifestLines.add('#EXTINF:$durationText,${segment.title ?? ''}');
      manifestLines.add('segments/$segmentName');
    }

    manifestLines.add('#EXT-X-ENDLIST');
    manifestLines.add('# AniDestiny downloaded bytes: $downloadedBytes');

    await Directory(p.dirname(manifestPath)).create(recursive: true);
    final file = File(manifestPath);
    await file.writeAsString('${manifestLines.join('\n')}\n');
  }

  String _hlsSegmentFileName(Uri segmentUri, int index) {
    final extension = p.extension(segmentUri.path);
    return 'segment-${index.toString().padLeft(6, '0')} '
        '${extension.isEmpty ? '.ts' : extension}'.replaceAll(' ', '');
  }

  Future<HlsManifest> _loadHlsMediaManifest({
    required HlsManifestLoader manifestLoader,
    required Uri sourceUri,
    required Map<String, String> headers,
  }) async {
    HlsManifest manifest = await manifestLoader.load(
      sourceUri,
      headers: headers,
    );
    if (!manifest.isMasterPlaylist) {
      return manifest;
    }

    final selectedVariantUri = _selectMediaVariantUri(manifest.variants);
    manifest = await manifestLoader.load(
      selectedVariantUri,
      headers: headers,
    );
    if (manifest.isMasterPlaylist) {
      throw const FormatException('HLS manifest contains nested master playlist.');
    }
    return manifest;
  }

  Uri _selectMediaVariantUri(List<HlsVariant> variants) {
    if (variants.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }
    final mediaVariants = variants
        .whereType<HlsVariant>()
        .toList()
      ..sort((a, b) {
          final bandwidthA = a.bandwidth ?? 0;
          final bandwidthB = b.bandwidth ?? 0;
          return bandwidthB.compareTo(bandwidthA);
        });
    if (mediaVariants.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }
    return mediaVariants.first.uri;
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
    if (hadActiveDownload) {
      await _waitForTaskSettlement(taskId);
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    final hadActiveDownload = _tokens.containsKey(taskId);
    _tokens[taskId]?.cancel('canceled');
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    if (!_canCancel(task.status)) return;
    final cleanupTargetPath = task.localPath;
    final clearedLocalPath = await _clearDiscardedDownload(
      localPath: cleanupTargetPath,
      clearNow: !hadActiveDownload,
    );
    final updated = task.copyWith(
      localPath: hadActiveDownload ? null : clearedLocalPath,
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
    if (hadActiveDownload) {
      await _waitForTaskSettlement(taskId);
    }
  }

  @override
  Future<void> removeEndedTask(String taskId) async {
    var task = await _repository.getTask(taskId);
    if (task == null) return;
    if (_shouldWaitForSettlement(task)) {
      await _waitForTaskSettlement(taskId);
      task = await _repository.getTask(taskId);
      if (task == null) return;
    }
    if (!_canRemove(task.status)) {
      throw const AppException(
        'This download is still active.',
        code: 'download_remove_not_allowed',
      );
    }

    if (_requiresLocalCleanupBeforeRemoval(task)) {
      final clearedLocalPath = await _clearDiscardedDownload(
        localPath: task.localPath,
        clearNow: true,
      );
      if (clearedLocalPath != null) {
        final updated = _manualCleanupBlockedRemovalTask(
          task,
          clearedLocalPath,
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

  bool _requiresLocalCleanupBeforeRemoval(DownloadTask task) {
    final localPath = task.localPath;
    if (localPath == null || localPath.isEmpty) {
      return false;
    }
    return task.status == DownloadStatus.canceled ||
        (task.status == DownloadStatus.failed &&
            task.kind == DownloadKind.directFile);
  }

  DownloadTask _manualCleanupBlockedRemovalTask(
    DownloadTask task,
    String localPath,
  ) {
    final updatedAt = DateTime.now();
    if (task.status == DownloadStatus.failed &&
        task.kind == DownloadKind.directFile) {
      return task.copyWith(
        localPath: localPath,
        status: DownloadStatus.canceled,
        failureReason: DownloadFailureReason.canceled,
        failureMessage: null,
        progress: 0,
        totalBytes: null,
        downloadedBytes: 0,
        updatedAt: updatedAt,
      );
    }
    return task.copyWith(
      localPath: localPath,
      updatedAt: updatedAt,
    );
  }

  bool _shouldWaitForSettlement(DownloadTask task) {
    return _settleCompleters.containsKey(task.id) &&
        (task.status == DownloadStatus.paused ||
            task.status == DownloadStatus.canceled);
  }

  Future<void> _waitForTaskSettlement(String taskId) async {
    final completer = _settleCompleters[taskId];
    if (completer == null) {
      return;
    }
    await completer.future;
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  }

  bool _isUnsupportedKind(DownloadKind kind) {
    return switch (kind) {
      DownloadKind.directFile => false,
      DownloadKind.hls => false,
      DownloadKind.bt || DownloadKind.unknown => true,
    };
  }

  String _messageFromError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'AniDestiny could not finish this download because the source returned HTTP $statusCode.';
    }
    return _downloadNetworkFailureMessage;
  }

  Future<void> _finalizeCanceledDownload(
    String taskId, {
    String? originalLocalPath,
  }) async {
    final latest = await _repository.getTask(taskId);
    if (latest == null) return;
    if (latest.status != DownloadStatus.paused &&
        latest.status != DownloadStatus.canceled) {
      return;
    }

    final clearedLocalPath = await _clearDiscardedDownload(
      localPath: originalLocalPath ?? latest.localPath,
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
