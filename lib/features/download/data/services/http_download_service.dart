import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
import '../../domain/entities/offline_media_item.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/offline_media_repository.dart';
import '../../domain/services/hls_manifest_loader.dart';
import '../../domain/services/download_service.dart';

const _downloadNetworkFailureMessage =
    'AniDestiny could not finish this download because the source could not be reached. Retry when the connection is stable.';

class HttpDownloadService implements DownloadService {
  static const _aes128KeyLength = 16;
  HttpDownloadService({
    required Dio dio,
    required DownloadRepository repository,
    HlsManifestLoader? hlsManifestLoader,
    OfflineMediaRepository? offlineMediaRepository,
    Future<Directory> Function()? applicationDocumentsDirectory,
    int hlsSegmentMaxAttempts = 3,
    Duration hlsSegmentRetryDelay = const Duration(milliseconds: 300),
  })  : _dio = dio,
        _repository = repository,
        _hlsManifestLoader = hlsManifestLoader,
        _offlineMediaRepository = offlineMediaRepository,
        _applicationDocumentsDirectory =
            applicationDocumentsDirectory ?? getApplicationDocumentsDirectory,
        _hlsSegmentMaxAttempts = hlsSegmentMaxAttempts,
        _hlsSegmentRetryDelay = hlsSegmentRetryDelay;

  final Dio _dio;
  final DownloadRepository _repository;
  final HlsManifestLoader? _hlsManifestLoader;
  final OfflineMediaRepository? _offlineMediaRepository;
  final Future<Directory> Function() _applicationDocumentsDirectory;
  final int _hlsSegmentMaxAttempts;
  final Duration _hlsSegmentRetryDelay;
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
      final directory = await _applicationDocumentsDirectory();
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
          taskKind: existingTask.kind,
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
      (await _applicationDocumentsDirectory()).path,
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
      final mediaBundle = await _loadHlsMediaBundle(
        manifestLoader: manifestLoader,
        sourceUri: sourceUri,
        headers: existingTask.headers,
      );
      if (mediaBundle.manifests.any((manifest) => manifest.isLive)) {
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

      var segmentDownloadedBytes = await _downloadHlsSegments(
        task: preparingTask,
        mediaManifest: mediaBundle.video,
        headers: existingTask.headers,
        cancelToken: token,
        manifestPath: mediaBundle.audio == null
            ? prepareLocalManifestPath
            : p.join(
                p.dirname(prepareLocalManifestPath),
                'video',
                'index.m3u8',
              ),
      );
      if (mediaBundle.audio case final audioManifest?) {
        segmentDownloadedBytes += await _downloadHlsSegments(
          task: preparingTask,
          mediaManifest: audioManifest,
          headers: existingTask.headers,
          cancelToken: token,
          manifestPath: p.join(
            p.dirname(prepareLocalManifestPath),
            'audio',
            'index.m3u8',
          ),
        );
      }
      await _validateHlsManifestAssets(
        mediaManifest: mediaBundle.video,
        manifestPath: mediaBundle.audio == null
            ? prepareLocalManifestPath
            : p.join(
                p.dirname(prepareLocalManifestPath),
                'video',
                'index.m3u8',
              ),
      );
      if (mediaBundle.audio case final audioManifest?) {
        await _validateHlsManifestAssets(
          mediaManifest: audioManifest,
          manifestPath: p.join(
            p.dirname(prepareLocalManifestPath),
            'audio',
            'index.m3u8',
          ),
        );
      }
      await _writeHlsManifest(
        mediaBundle.video,
        segmentDownloadedBytes,
        mediaBundle.audio == null
            ? prepareLocalManifestPath
            : p.join(
                p.dirname(prepareLocalManifestPath),
                'video',
                'index.m3u8',
              ),
      );
      if (mediaBundle.audio case final audioManifest?) {
        await _writeHlsManifest(
          audioManifest,
          segmentDownloadedBytes,
          p.join(p.dirname(prepareLocalManifestPath), 'audio', 'index.m3u8'),
        );
        await _writeHlsMasterManifest(
          mediaBundle,
          prepareLocalManifestPath,
        );
      }
      final completed = preparingTask.copyWith(
        status: DownloadStatus.completed,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 1,
        downloadedBytes: segmentDownloadedBytes,
        totalBytes: segmentDownloadedBytes,
        updatedAt: DateTime.now(),
      );
      await _offlineMediaRepository?.upsert(
        OfflineMediaItem(
          id: 'offline-${existingTask.id}',
          downloadTaskId: existingTask.id,
          animeId: existingTask.animeId,
          episodeId: existingTask.episodeId,
          title: existingTask.title,
          episodeTitle: existingTask.episodeTitle,
          manifestPath: prepareLocalManifestPath,
          downloadedBytes: segmentDownloadedBytes,
          createdAt: completed.updatedAt,
        ),
      );
      await _repository.upsertTask(completed);
      _emitTask(completed);
      return;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        await _finalizeCanceledDownload(
          existingTask.id,
          taskKind: existingTask.kind,
          originalLocalPath: prepareLocalManifestPath,
        );
        return;
      }
      final failed = preparingTask.copyWith(
        localPath: prepareLocalManifestPath,
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
        localPath: prepareLocalManifestPath,
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
        localPath: prepareLocalManifestPath,
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
    required String manifestPath,
  }) async {
    if (mediaManifest.segments.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }

    final segmentDirectory = Directory(
      p.join(
        p.dirname(manifestPath),
        'segments',
      ),
    );
    await segmentDirectory.create(recursive: true);

    var downloadedBytes = 0;

    for (final keyEntry in _hlsEncryptionKeys(mediaManifest).entries) {
      final keyFile = File(
        p.join(
          segmentDirectory.path,
          _hlsEncryptionKeyFileName(keyEntry.value),
        ),
      );
      if (await keyFile.exists() &&
          await keyFile.length() == _aes128KeyLength) {
        downloadedBytes += await keyFile.length();
      } else {
        downloadedBytes += await _downloadHlsSegment(
          segmentUri: keyEntry.key.uri,
          localPath: keyFile.path,
          headers: headers,
          cancelToken: cancelToken,
        );
      }
    }

    for (final initializationEntry
        in _hlsInitializationSegments(mediaManifest).entries) {
      final initializationSegment = initializationEntry.key;
      final initializationPath = p.join(
        segmentDirectory.path,
        _hlsInitializationSegmentFileName(
          initializationSegment.uri,
          initializationEntry.value,
        ),
      );
      final initializationFile = File(initializationPath);
      final initializationLength = await initializationFile.exists()
          ? await initializationFile.length()
          : 0;
      if (initializationLength > 0 &&
          (initializationSegment.byteRange == null ||
              initializationLength ==
                  initializationSegment.byteRange!.length)) {
        downloadedBytes += await initializationFile.length();
      } else {
        downloadedBytes += await _downloadHlsSegment(
          segmentUri: initializationSegment.uri,
          localPath: initializationPath,
          headers: headers,
          byteRange: initializationSegment.byteRange,
          cancelToken: cancelToken,
        );
      }
    }

    for (var index = 0; index < mediaManifest.segments.length; index++) {
      final segment = mediaManifest.segments[index];
      if (segment.isGap) {
        final progress = (index + 1) / mediaManifest.segments.length;
        _emit(
          task.id,
          progress,
          DownloadStatus.downloading,
          downloadedBytes: downloadedBytes,
        );
        continue;
      }
      final safeSegmentName = _hlsSegmentFileName(segment.uri, index);
      final segmentPath = p.join(segmentDirectory.path, safeSegmentName);
      final existingSegmentFile = File(segmentPath);
      if (await existingSegmentFile.exists()) {
        final existingBytes = await existingSegmentFile.length();
        if (existingBytes > 0 &&
            (segment.byteRange == null ||
                existingBytes == segment.byteRange!.length)) {
          downloadedBytes += existingBytes;
          final progress = (index + 1) / mediaManifest.segments.length;
          _emit(
            task.id,
            progress,
            DownloadStatus.downloading,
            downloadedBytes: downloadedBytes,
          );
          continue;
        }
      }
      final segmentBytes = await _downloadHlsSegment(
        segmentUri: segment.uri,
        localPath: segmentPath,
        headers: headers,
        byteRange: segment.byteRange,
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

  Future<void> _validateHlsManifestAssets({
    required HlsManifest mediaManifest,
    required String manifestPath,
  }) async {
    final segmentDirectory = Directory(
      p.join(
        p.dirname(manifestPath),
        'segments',
      ),
    );

    for (final initializationEntry
        in _hlsInitializationSegments(mediaManifest).entries) {
      final initializationSegment = initializationEntry.key;
      final initializationName = _hlsInitializationSegmentFileName(
        initializationSegment.uri,
        initializationEntry.value,
      );
      final initializationFile = File(
        p.join(segmentDirectory.path, initializationName),
      );
      if (!await initializationFile.exists()) {
        throw FormatException(
          'HLS manifest integrity check failed: missing initialization file $initializationName',
        );
      }
      if (await initializationFile.length() == 0) {
        throw FormatException(
          'HLS manifest integrity check failed: empty initialization file $initializationName',
        );
      }
      if (initializationSegment.byteRange != null &&
          await initializationFile.length() !=
              initializationSegment.byteRange!.length) {
        throw FormatException(
          'HLS manifest integrity check failed: invalid initialization file $initializationName',
        );
      }
    }

    for (final keyEntry in _hlsEncryptionKeys(mediaManifest).entries) {
      final keyName = _hlsEncryptionKeyFileName(keyEntry.value);
      final keyFile = File(p.join(segmentDirectory.path, keyName));
      if (!await keyFile.exists()) {
        throw FormatException(
          'HLS manifest integrity check failed: missing encryption key file $keyName',
        );
      }
      if (await keyFile.length() != _aes128KeyLength) {
        throw FormatException(
          'HLS manifest integrity check failed: invalid AES-128 key file $keyName',
        );
      }
    }

    for (var index = 0; index < mediaManifest.segments.length; index++) {
      final segment = mediaManifest.segments[index];
      if (segment.isGap) continue;
      final segmentName = _hlsSegmentFileName(segment.uri, index);
      final segmentPath = p.join(segmentDirectory.path, segmentName);
      final segmentFile = File(segmentPath);

      if (!await segmentFile.exists()) {
        throw FormatException(
          'HLS manifest integrity check failed: missing segment file $segmentName',
        );
      }

      if (await segmentFile.length() == 0) {
        throw FormatException(
          'HLS manifest integrity check failed: empty segment file $segmentName',
        );
      }
      if (segment.byteRange != null &&
          await segmentFile.length() != segment.byteRange!.length) {
        throw FormatException(
          'HLS manifest integrity check failed: invalid segment file $segmentName',
        );
      }
    }
  }

  Future<int> _downloadHlsSegment({
    required Uri segmentUri,
    required String localPath,
    required Map<String, String> headers,
    HlsByteRange? byteRange,
    required CancelToken cancelToken,
  }) async {
    final maxAttempts = _hlsSegmentMaxAttempts < 1 ? 1 : _hlsSegmentMaxAttempts;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      var downloadedBytes = 0;
      try {
        final response = await _dio.download(
          segmentUri.toString(),
          localPath,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              ...headers,
              if (byteRange != null) 'Range': byteRange.requestHeader,
            },
          ),
          onReceiveProgress: (received, total) {
            downloadedBytes = received;
          },
        );
        if (byteRange != null) {
          _validateHlsByteRangeResponse(response, byteRange);
          final actualLength = await File(localPath).length();
          if (actualLength != byteRange.length) {
            throw FormatException(
              'HLS byte-range response length mismatch: expected '
              '${byteRange.length} bytes.',
            );
          }
        }
        return downloadedBytes;
      } on DioException catch (error) {
        if (CancelToken.isCancel(error) ||
            attempt == maxAttempts ||
            !_isRetryableHlsSegmentFailure(error)) {
          rethrow;
        }
        if (_hlsSegmentRetryDelay > Duration.zero) {
          await Future.any<void>([
            Future<void>.delayed(_hlsSegmentRetryDelay),
            cancelToken.whenCancel.then<void>((error) => throw error),
          ]);
        }
        if (cancelToken.isCancelled) {
          throw cancelToken.cancelError!;
        }
      }
    }
    throw StateError('HLS segment retry loop exited unexpectedly.');
  }

  void _validateHlsByteRangeResponse(
    Response<dynamic> response,
    HlsByteRange byteRange,
  ) {
    final contentRange = response.headers.value('content-range');
    final match = RegExp(
      r'^bytes (\d+)-(\d+)/(\d+|\*)$',
      caseSensitive: false,
    ).firstMatch(contentRange?.trim() ?? '');
    final expectedEnd = byteRange.offset + byteRange.length - 1;
    if (response.statusCode != HttpStatus.partialContent ||
        match == null ||
        int.tryParse(match.group(1)!) != byteRange.offset ||
        int.tryParse(match.group(2)!) != expectedEnd) {
      throw const FormatException(
        'HLS byte-range response did not match the requested range.',
      );
    }
  }

  bool _isRetryableHlsSegmentFailure(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    final statusCode = error.response?.statusCode;
    return statusCode == 408 ||
        statusCode == 429 ||
        (statusCode != null && statusCode >= 500 && statusCode <= 599);
  }

  Future<void> _writeHlsManifest(
    HlsManifest manifest,
    int downloadedBytes,
    String manifestPath,
  ) async {
    final hasInitializationSegment = manifest.initializationSegment != null ||
        manifest.segments.any(
          (segment) => segment.initializationSegment != null,
        );
    final localProtocolVersion = math.max(
      manifest.protocolVersion,
      manifest.segments.any((segment) => segment.isGap)
          ? 6
          : hasInitializationSegment
              ? 5
              : 3,
    );
    final manifestLines = <String>[
      '#EXTM3U',
      if (manifest.targetDuration != null)
        '#EXT-X-TARGETDURATION:${manifest.targetDuration!.inSeconds}',
      '#EXT-X-VERSION:$localProtocolVersion',
      '#EXT-X-MEDIA-SEQUENCE:${manifest.mediaSequence}',
      '#EXT-X-PLAYLIST-TYPE:VOD',
    ];

    HlsEncryptionKey? activeEncryptionKey;
    HlsInitializationSegment? activeInitializationSegment;
    final encryptionKeys = _hlsEncryptionKeys(manifest);
    final initializationSegments = _hlsInitializationSegments(manifest);
    for (var index = 0; index < manifest.segments.length; index++) {
      final segment = manifest.segments[index];
      if (segment.hasDiscontinuity) {
        manifestLines.add('#EXT-X-DISCONTINUITY');
      }
      if (segment.isGap) {
        final duration = segment.duration ?? const Duration(seconds: 1);
        final durationText =
            (duration.inMilliseconds / 1000).toStringAsFixed(3);
        manifestLines.add('#EXTINF:$durationText,${segment.title ?? ''}');
        manifestLines.add('#EXT-X-GAP');
        manifestLines.add(
          'segments/${_hlsSegmentFileName(segment.uri, index)}',
        );
        continue;
      }
      final initializationSegment =
          segment.initializationSegment ?? manifest.initializationSegment;
      if (!_sameHlsInitializationSegment(
        activeInitializationSegment,
        initializationSegment,
      )) {
        if (initializationSegment != null) {
          activeEncryptionKey = _appendHlsEncryptionKeyIfChanged(
            manifestLines,
            activeEncryptionKey: activeEncryptionKey,
            encryptionKey: initializationSegment.encryptionKey,
            encryptionKeys: encryptionKeys,
          );
          final initializationIndex =
              initializationSegments.keys.toList().indexWhere(
                    (candidate) => _sameHlsInitializationSegment(
                      candidate,
                      initializationSegment,
                    ),
                  );
          manifestLines.add(
            '#EXT-X-MAP:URI="segments/${_hlsInitializationSegmentFileName(initializationSegment.uri, initializationIndex)}"',
          );
        }
        activeInitializationSegment = initializationSegment;
      }
      activeEncryptionKey = _appendHlsEncryptionKeyIfChanged(
        manifestLines,
        activeEncryptionKey: activeEncryptionKey,
        encryptionKey: segment.encryptionKey,
        encryptionKeys: encryptionKeys,
      );
      final segmentName = _hlsSegmentFileName(segment.uri, index);
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
            '${extension.isEmpty ? '.ts' : extension}'
        .replaceAll(' ', '');
  }

  String _hlsInitializationSegmentFileName(Uri segmentUri, int index) {
    final extension = p.extension(segmentUri.path);
    final suffix = index == 0 ? '' : '-${index.toString().padLeft(6, '0')}';
    return 'initialization$suffix${extension.isEmpty ? '.mp4' : extension}';
  }

  Map<HlsInitializationSegment, int> _hlsInitializationSegments(
    HlsManifest manifest,
  ) {
    final initializationSegments = <HlsInitializationSegment, int>{};
    for (final segment in manifest.segments) {
      if (segment.isGap) continue;
      final initializationSegment =
          segment.initializationSegment ?? manifest.initializationSegment;
      if (initializationSegment == null) continue;
      final existing = initializationSegments.keys.where(
        (candidate) => _sameHlsInitializationSegment(
          candidate,
          initializationSegment,
        ),
      );
      if (existing.isEmpty) {
        initializationSegments[initializationSegment] =
            initializationSegments.length;
      }
    }
    return initializationSegments;
  }

  bool _sameHlsInitializationSegment(
    HlsInitializationSegment? first,
    HlsInitializationSegment? second,
  ) {
    return first?.uri == second?.uri &&
        first?.byteRange?.length == second?.byteRange?.length &&
        first?.byteRange?.offset == second?.byteRange?.offset &&
        _sameHlsEncryptionKey(first?.encryptionKey, second?.encryptionKey);
  }

  Map<HlsEncryptionKey, int> _hlsEncryptionKeys(HlsManifest manifest) {
    final keys = <HlsEncryptionKey, int>{};
    for (final segment in manifest.segments) {
      if (segment.isGap) continue;
      final initializationSegment =
          segment.initializationSegment ?? manifest.initializationSegment;
      for (final key in [
        initializationSegment?.encryptionKey,
        segment.encryptionKey,
      ]) {
        if (key == null) continue;
        final existingKey = keys.keys.where(
          (candidate) => _sameHlsEncryptionKey(candidate, key),
        );
        if (existingKey.isEmpty) {
          keys[key] = keys.length;
        }
      }
    }
    return keys;
  }

  HlsEncryptionKey? _appendHlsEncryptionKeyIfChanged(
    List<String> manifestLines, {
    required HlsEncryptionKey? activeEncryptionKey,
    required HlsEncryptionKey? encryptionKey,
    required Map<HlsEncryptionKey, int> encryptionKeys,
  }) {
    if (_sameHlsEncryptionKey(activeEncryptionKey, encryptionKey)) {
      return activeEncryptionKey;
    }
    if (encryptionKey == null) {
      manifestLines.add('#EXT-X-KEY:METHOD=NONE');
    } else {
      final keyIndex = encryptionKeys.keys.toList().indexWhere(
            (key) => _sameHlsEncryptionKey(key, encryptionKey),
          );
      final attributes = <String>[
        'METHOD=${encryptionKey.method}',
        'URI="segments/${_hlsEncryptionKeyFileName(keyIndex)}"',
        if (encryptionKey.iv != null) 'IV=${encryptionKey.iv}',
      ];
      manifestLines.add('#EXT-X-KEY:${attributes.join(',')}');
    }
    return encryptionKey;
  }

  bool _sameHlsEncryptionKey(
    HlsEncryptionKey? first,
    HlsEncryptionKey? second,
  ) {
    return first?.method == second?.method &&
        first?.uri == second?.uri &&
        first?.iv == second?.iv;
  }

  String _hlsEncryptionKeyFileName(int index) {
    return 'key-${index.toString().padLeft(6, '0')}.key';
  }

  Future<_HlsMediaBundle> _loadHlsMediaBundle({
    required HlsManifestLoader manifestLoader,
    required Uri sourceUri,
    required Map<String, String> headers,
  }) async {
    HlsManifest manifest = await manifestLoader.load(
      sourceUri,
      headers: headers,
    );
    if (!manifest.isMasterPlaylist) {
      return _HlsMediaBundle(video: manifest);
    }

    final selectedVariant = _selectMediaVariant(manifest.variants);
    final videoManifest = await manifestLoader.load(
      selectedVariant.uri,
      headers: headers,
      importedVariables: manifest.variables,
    );
    if (videoManifest.isMasterPlaylist) {
      throw const FormatException(
        'HLS manifest contains nested master playlist.',
      );
    }
    final audioGroupId = selectedVariant.audioGroupId;
    if (audioGroupId == null) {
      return _HlsMediaBundle(video: videoManifest);
    }
    final groupRenditions = manifest.renditions
        .where(
          (rendition) =>
              rendition.type == 'AUDIO' && rendition.groupId == audioGroupId,
        )
        .toList(growable: false);
    if (groupRenditions.isEmpty) {
      throw const FormatException('HLS alternate audio group is missing.');
    }
    final selectedAudio = groupRenditions.firstWhere(
      (rendition) => rendition.isDefault,
      orElse: () => groupRenditions.firstWhere(
        (rendition) => rendition.autoselect,
        orElse: () => groupRenditions.first,
      ),
    );
    if (selectedAudio.uri == null) {
      return _HlsMediaBundle(video: videoManifest);
    }
    final audioManifest = await manifestLoader.load(
      selectedAudio.uri!,
      headers: headers,
      importedVariables: manifest.variables,
    );
    if (audioManifest.isMasterPlaylist) {
      throw const FormatException(
        'HLS audio rendition contains nested master playlist.',
      );
    }
    return _HlsMediaBundle(
      video: videoManifest,
      audio: audioManifest,
      variant: selectedVariant,
      audioRendition: selectedAudio,
    );
  }

  Future<void> _writeHlsMasterManifest(
    _HlsMediaBundle bundle,
    String manifestPath,
  ) async {
    final rendition = bundle.audioRendition!;
    final variant = bundle.variant!;
    final escapedName = rendition.name.replaceAll('"', '');
    final escapedLanguage = rendition.language?.replaceAll('"', '');
    final escapedCodecs = variant.codecs?.replaceAll('"', '');
    final mediaAttributes = <String>[
      'TYPE=AUDIO',
      'GROUP-ID="offline-audio"',
      'NAME="$escapedName"',
      'DEFAULT=YES',
      'AUTOSELECT=YES',
      if (escapedLanguage != null) 'LANGUAGE="$escapedLanguage"',
      'URI="audio/index.m3u8"',
    ];
    final streamAttributes = <String>[
      'BANDWIDTH=${variant.bandwidth ?? 1}',
      if (variant.resolution != null) 'RESOLUTION=${variant.resolution}',
      if (escapedCodecs != null) 'CODECS="$escapedCodecs"',
      'AUDIO="offline-audio"',
    ];
    final content = [
      '#EXTM3U',
      '#EXT-X-VERSION:${math.max(bundle.video.protocolVersion, bundle.audio!.protocolVersion)}',
      '#EXT-X-MEDIA:${mediaAttributes.join(',')}',
      '#EXT-X-STREAM-INF:${streamAttributes.join(',')}',
      'video/index.m3u8',
      '',
    ].join('\n');
    await File(manifestPath).writeAsString(content);
  }

  HlsVariant _selectMediaVariant(List<HlsVariant> variants) {
    if (variants.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }
    final mediaVariants = variants.whereType<HlsVariant>().toList()
      ..sort((a, b) {
        final bandwidthA = a.bandwidth ?? 0;
        final bandwidthB = b.bandwidth ?? 0;
        return bandwidthB.compareTo(bandwidthA);
      });
    if (mediaVariants.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }
    return mediaVariants.first;
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
      taskKind: task.kind,
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
      taskKind: task.kind,
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
        taskKind: task.kind,
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
    if (task.status == DownloadStatus.completed) {
      return task.kind == DownloadKind.hls;
    }
    return (task.status == DownloadStatus.canceled ||
            task.status == DownloadStatus.failed) &&
        (task.kind == DownloadKind.directFile || task.kind == DownloadKind.hls);
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
    required DownloadKind taskKind,
    String? originalLocalPath,
  }) async {
    final latest = await _repository.getTask(taskId);
    if (latest == null) return;
    if (latest.status != DownloadStatus.paused &&
        latest.status != DownloadStatus.canceled) {
      return;
    }
    final shouldClearLocalDownload = switch (taskKind) {
      DownloadKind.hls => latest.status == DownloadStatus.canceled,
      DownloadKind.directFile ||
      DownloadKind.bt ||
      DownloadKind.unknown =>
        true,
    };
    if (!shouldClearLocalDownload) {
      return;
    }

    final clearedLocalPath = await _clearDiscardedDownload(
      localPath: originalLocalPath ?? latest.localPath,
      taskKind: taskKind,
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
    required DownloadKind taskKind,
    required bool clearNow,
  }) async {
    if (localPath == null) return null;
    if (!clearNow) return localPath;
    try {
      if (taskKind == DownloadKind.hls) {
        final segmentDirectory = Directory(p.dirname(localPath));
        if (await segmentDirectory.exists()) {
          await segmentDirectory.delete(recursive: true);
        }
        return null;
      }

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

class _HlsMediaBundle {
  const _HlsMediaBundle({
    required this.video,
    this.audio,
    this.variant,
    this.audioRendition,
  });

  final HlsManifest video;
  final HlsManifest? audio;
  final HlsVariant? variant;
  final HlsRendition? audioRendition;

  Iterable<HlsManifest> get manifests sync* {
    yield video;
    if (audio case final audioManifest?) {
      yield audioManifest;
    }
  }
}
