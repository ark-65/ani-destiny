import 'dart:async';
import 'dart:io';

import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/download_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/http_download_service.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/hls_manifest.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_progress.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/download/domain/services/hls_manifest_loader.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  test('HLS task enters pending state when created', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.pending);
    expect(task.failureReason, DownloadFailureReason.none);
  });

  test('starting HLS task with valid manifest downloads segments and writes local manifest',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-complete');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    const segmentOne = <int>[1, 2, 3, 4, 5];
    const segmentTwo = <int>[6, 7, 8, 9, 10, 11];
    final dio = _FakeHlsSegmentDownloadDio({
      'https://cdn.example.test/segment-1.ts': segmentOne,
      'https://cdn.example.test/segment-2.ts': segmentTwo,
    });

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: dio,
      repository: repository,
      hlsManifestLoader: _FakeHlsManifestLoader(
        (manifestUri, headers) async {
          expect(manifestUri.toString(), 'https://cdn.example.test/index.m3u8');
          return HlsManifest(
            uri: Uri.parse('https://cdn.example.test/index.m3u8'),
            segments: [
              HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-1.ts')),
              HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-2.ts')),
            ],
            variants: [],
            isLive: false,
            targetDuration: null,
          );
        },
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.completed);
    expect(task.failureReason, DownloadFailureReason.none);
    expect(task.failureMessage, isNull);
    expect(task.progress, 1);
    expect(task.downloadedBytes, segmentOne.length + segmentTwo.length);
    expect(task.totalBytes, segmentOne.length + segmentTwo.length);
    expect(task.localPath, isNotNull);
    expect(task.localPath, contains('downloads${p.separator}'));

    final manifestPath = task.localPath!;
    final manifestContent = await File(manifestPath).readAsString();
    expect(manifestContent, contains('#EXTM3U'));
    expect(manifestContent, contains('segments/segment-000000.ts'));
    expect(manifestContent, contains('segments/segment-000001.ts'));
    expect(manifestContent, contains('#EXT-X-ENDLIST'));
    expect(
      File(p.join(p.dirname(manifestPath), 'segments', 'segment-000000.ts')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(p.dirname(manifestPath), 'segments', 'segment-000001.ts')).existsSync(),
      isTrue,
    );

    expect(dio.downloadedUris, ['https://cdn.example.test/segment-1.ts', 'https://cdn.example.test/segment-2.ts']);
    expect(task.failureMessage, isNull);
  });

  test('starting HLS task resumes from existing segment files', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-resume');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    const segmentOne = <int>[1, 2, 3, 4, 5];
    const segmentTwo = <int>[6, 7, 8, 9, 10, 11];
    final manifestLoader = _FakeHlsManifestLoader(
      (manifestUri, headers) async {
        expect(manifestUri.toString(), 'https://cdn.example.test/index.m3u8');
        return HlsManifest(
          uri: manifestUri,
          segments: [
            HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-1.ts')),
            HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-2.ts')),
          ],
          variants: const [],
          isLive: false,
          targetDuration: null,
        );
      },
    );

    final firstAttemptDio = _FlakyHlsSegmentDownloadDio(
      {
        'https://cdn.example.test/segment-1.ts': segmentOne,
        'https://cdn.example.test/segment-2.ts': segmentTwo,
      },
      failOnFirst: {'https://cdn.example.test/segment-2.ts'},
    );

    final repository = DownloadRepositoryImpl(database);
    final firstAttemptService = HttpDownloadService(
      dio: firstAttemptDio,
      repository: repository,
      hlsManifestLoader: manifestLoader,
    );

    final taskId = await firstAttemptService.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await firstAttemptService.start(taskId);

    final failedTask = await repository.getTask(taskId);
    expect(failedTask, isNotNull);
    expect(failedTask!.status, DownloadStatus.failed);
    expect(failedTask.localPath, isNotNull);

    final manifestDirectory = p.dirname(failedTask.localPath!);
    final segmentDir = Directory(p.join(manifestDirectory, 'segments'));
    expect(
      File(p.join(segmentDir.path, 'segment-000000.ts')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(segmentDir.path, 'segment-000001.ts')).existsSync(),
      isFalse,
    );

    final retryDio = _FakeHlsSegmentDownloadDio({
      'https://cdn.example.test/segment-1.ts': segmentOne,
      'https://cdn.example.test/segment-2.ts': segmentTwo,
    });
    final retryService = HttpDownloadService(
      dio: retryDio,
      repository: repository,
      hlsManifestLoader: manifestLoader,
    );

    await retryService.start(taskId);

    final completedTask = await repository.getTask(taskId);
    expect(completedTask, isNotNull);
    expect(completedTask!.status, DownloadStatus.completed);
    expect(completedTask.progress, 1);
    expect(completedTask.downloadedBytes, segmentOne.length + segmentTwo.length);
    expect(completedTask.totalBytes, segmentOne.length + segmentTwo.length);
    expect(
      File(p.join(segmentDir.path, 'segment-000000.ts')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(segmentDir.path, 'segment-000001.ts')).existsSync(),
      isTrue,
    );
    expect(retryDio.downloadedUris, ['https://cdn.example.test/segment-2.ts']);
  });

  test('starting HLS task fails when a downloaded segment is empty', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-empty-segment');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    const segmentOne = <int>[];
    const segmentTwo = <int>[6, 7, 8, 9, 10, 11];
    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: _FakeHlsSegmentDownloadDio({
        'https://cdn.example.test/segment-1.ts': segmentOne,
        'https://cdn.example.test/segment-2.ts': segmentTwo,
      }),
      repository: repository,
      hlsManifestLoader: _FakeHlsManifestLoader(
        (manifestUri, headers) async {
          expect(manifestUri.toString(), 'https://cdn.example.test/index.m3u8');
          return HlsManifest(
            uri: manifestUri,
            segments: [
              HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-1.ts')),
              HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-2.ts')),
            ],
            variants: const [],
            isLive: false,
            targetDuration: null,
          );
        },
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.failed);
    expect(task.failureReason, DownloadFailureReason.invalidManifest);
    expect(task.failureMessage, contains('empty segment file'));

    expect(task.localPath, isNotNull);
    final manifestDirectory = p.dirname(task.localPath!);
    final segmentDir = Directory(p.join(manifestDirectory, 'segments'));
    expect(File(p.join(segmentDir.path, 'segment-000000.ts')).existsSync(), isTrue);
    expect(File(p.join(segmentDir.path, 'segment-000000.ts')).readAsBytesSync(), isEmpty);
    expect(File(p.join(segmentDir.path, 'segment-000001.ts')).existsSync(), isTrue);
    expect(File(p.join(segmentDir.path, 'segment-000001.ts')).readAsBytesSync(), segmentTwo);
  });

  test('starting HLS task with master playlist resolves highest-bandwidth variant first', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-master');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    final loadLog = <String>[];
    final repository = DownloadRepositoryImpl(database);
    const segmentBytes = <int>[1, 2, 3, 4, 5, 6];
    final service = HttpDownloadService(
      dio: _FakeHlsSegmentDownloadDio({
        'https://cdn.example.test/1080/segment-1.ts': segmentBytes,
      }),
      repository: repository,
      hlsManifestLoader: _FakeHlsManifestLoader(
        (manifestUri, headers) async {
          loadLog.add(manifestUri.toString());
          if (manifestUri.path == '/index.m3u8') {
            return HlsManifest(
              uri: manifestUri,
              segments: const [],
              variants: [
                HlsVariant(
                  uri: Uri.parse('https://cdn.example.test/720/index.m3u8'),
                  bandwidth: 100000,
                  resolution: '960x540',
                ),
                HlsVariant(
                  uri: Uri.parse('https://cdn.example.test/1080/index.m3u8'),
                  bandwidth: 3200000,
                  resolution: '1920x1080',
                ),
              ],
              isLive: false,
              targetDuration: null,
            );
          }
          if (manifestUri.path == '/1080/index.m3u8') {
            return HlsManifest(
              uri: manifestUri,
              segments: [
                HlsSegment(
                  uri: Uri.parse('https://cdn.example.test/1080/segment-1.ts'),
                  duration: const Duration(seconds: 8),
                  title: 'segment-1',
                ),
              ],
              variants: const [],
              isLive: false,
              targetDuration: const Duration(seconds: 6),
            );
          }
          throw const FormatException('unexpected manifest uri');
        },
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.completed);
    expect(task.failureReason, DownloadFailureReason.none);
    expect(task.failureMessage, isNull);
    expect(
      loadLog,
      const <String>[
        'https://cdn.example.test/index.m3u8',
        'https://cdn.example.test/1080/index.m3u8',
      ],
    );
    expect(task.localPath, isNotNull);
    final manifestContent = await File(task.localPath!).readAsString();
    expect(manifestContent, contains('#EXTINF:8.000,segment-1'));
    expect(task.totalBytes, segmentBytes.length);
    expect(task.downloadedBytes, segmentBytes.length);
    expect(task.progress, 1);
    expect(
      File(p.join(p.dirname(task.localPath!), 'segments', 'segment-000000.ts')).existsSync(),
      isTrue,
    );
  });

  test('starting HLS task with invalid variant manifest reports invalid-manifest failure', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-invalid-variant');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
      hlsManifestLoader: _FakeHlsManifestLoader(
        (manifestUri, headers) async {
          if (manifestUri.path == '/index.m3u8') {
            return HlsManifest(
              uri: manifestUri,
              segments: const [],
              variants: [
                HlsVariant(
                  uri: Uri.parse('https://cdn.example.test/720/index.m3u8'),
                  bandwidth: 100000,
                  resolution: '960x540',
                ),
              ],
              isLive: false,
              targetDuration: null,
            );
          }
          if (manifestUri.path == '/720/index.m3u8') {
            throw const FormatException('variant manifest invalid');
          }
          throw const FormatException('unexpected manifest uri');
        },
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.failed);
    expect(task.failureReason, DownloadFailureReason.invalidManifest);
    expect(task.failureMessage, 'variant manifest invalid');
  });

  test('starting HLS task with live media playlist stays unsupported for now', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-live');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
      hlsManifestLoader: _FakeHlsManifestLoader(
        (manifestUri, headers) async {
          return HlsManifest(
            uri: manifestUri,
            segments: [
              HlsSegment(uri: Uri.parse('https://cdn.example.test/segment-1.ts')),
            ],
            variants: const [],
            isLive: true,
            targetDuration: const Duration(seconds: 6),
          );
        },
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.unsupported);
    expect(task.failureReason, DownloadFailureReason.unsupportedType);
    expect(task.failureMessage, isNull);
  });

  test('starting HLS task with invalid manifest records invalid-manifest failure', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-hls-invalid');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
      hlsManifestLoader: _FakeHlsManifestLoader(
        (_, __) async => throw const FormatException('Invalid HLS manifest.'),
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.failed);
    expect(task.failureReason, DownloadFailureReason.invalidManifest);
  });

  test('unsupported tasks drop implementation placeholder messages on read',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final now = DateTime.utc(2026, 7, 1, 12);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-unsupported-bt',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'BT Test',
        episodeTitle: 'Episode 1',
        url: 'magnet:?xt=urn:btih:abc123',
        kind: DownloadKind.bt,
        status: DownloadStatus.unsupported,
        failureReason: DownloadFailureReason.unsupportedType,
        failureMessage: 'BT download is not implemented yet.',
        progress: 0,
        downloadedBytes: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final task = await repository.getTask('task-unsupported-bt');

    expect(task, isNotNull);
    expect(task!.failureReason, DownloadFailureReason.unsupportedType);
    expect(task.failureMessage, isNull);
  });

  test('old raw unexpected failure messages are normalized on read', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final now = DateTime.utc(2026, 7, 3, 12);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-raw-failure',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.unknown,
        failureMessage: 'StateError: filesystem sync failed',
        progress: 0.2,
        downloadedBytes: 200,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final task = await repository.getTask('task-raw-failure');

    expect(task, isNotNull);
    expect(task!.failureReason, DownloadFailureReason.unknown);
    expect(task.failureMessage, unexpectedDownloadFailureMessage);
  });

  test('old raw unsupported operation failures are normalized on read',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final now = DateTime.utc(2026, 7, 3, 12);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-raw-unsupported-operation',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.unknown,
        failureMessage: 'Unsupported operation: background transfer disabled',
        progress: 0,
        downloadedBytes: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final task = await repository.getTask('task-raw-unsupported-operation');

    expect(task, isNotNull);
    expect(task!.failureReason, DownloadFailureReason.unknown);
    expect(task.failureMessage, unexpectedDownloadFailureMessage);
  });

  test('old raw network failure messages are normalized on read', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final now = DateTime.utc(2026, 7, 3, 21);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-raw-network-failure',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.networkError,
        failureMessage: 'DioException [connection timeout]: socket closed',
        progress: 0.1,
        downloadedBytes: 100,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final task = await repository.getTask('task-raw-network-failure');

    expect(task, isNotNull);
    expect(task!.failureReason, DownloadFailureReason.networkError);
    expect(task.failureMessage, unexpectedDownloadFailureMessage);
  });

  test('old raw Dart and IO failure messages are normalized on read', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final now = DateTime.utc(2026, 7, 3, 22);
    const rawMessages = <String>[
      'RangeError (index): Invalid value: Not in inclusive range 0..1',
      'NoSuchMethodError: The method length was called on null.',
      'ArgumentError: Invalid argument(s): missing download directory',
      'Invalid argument(s): missing download directory',
      'PathNotFoundException: Cannot open file, path = /tmp/missing.mp4',
      'PlatformException(download_failed, Channel call failed, null, null)',
      'ClientException: Connection closed before full header was received',
      'HttpException: Connection closed while receiving data',
      'SocketException: Connection reset by peer',
      'HandshakeException: Connection terminated during handshake',
      'TlsException: Failure trusting builtin roots',
      'TimeoutException after 0:00:30.000000: download stalled',
      'TypeError: Failed to fetch',
      'Error: Network request failed',
      'Connection refused, errno = 61',
      'Connection reset by peer',
      'Connection closed before full header was received',
      'Failed host lookup: cdn.example.test',
      'Network is unreachable, errno = 51',
      'No route to host, errno = 65',
      'Operation timed out, errno = 60',
      'OS Error: No space left on device, errno = 28',
      'Connection timed out, errno = 110',
      'No space left on device, errno = 28',
      'Permission denied, errno = 13',
      'CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate',
      'CertificateException: certificate has expired',
      'IOException: write failed',
      'NetworkException: connection aborted',
      'UnknownHostException: cdn.example.test',
      'XMLHttpRequest error.',
    ];

    for (final message in rawMessages) {
      await repository.upsertTask(
        DownloadTask(
          id: 'task-${rawMessages.indexOf(message)}',
          animeId: 'anime-1',
          episodeId: 'episode-1',
          sourceId: 'sakura',
          title: 'Direct Test',
          episodeTitle: 'Episode 1',
          url: 'https://cdn.example.test/video.mp4',
          kind: DownloadKind.directFile,
          status: DownloadStatus.failed,
          failureReason: DownloadFailureReason.unknown,
          failureMessage: message,
          progress: 0.1,
          downloadedBytes: 100,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    for (var index = 0; index < rawMessages.length; index += 1) {
      final task = await repository.getTask('task-$index');

      expect(task, isNotNull);
      expect(task!.failureReason, DownloadFailureReason.unknown);
      expect(task.failureMessage, unexpectedDownloadFailureMessage);
    }
  });

  test('direct file progress maps downloaded and total bytes', () {
    const progress = DownloadProgress(
      taskId: 'task-1',
      progress: 0.5,
      status: DownloadStatus.downloading,
      downloadedBytes: 512,
      totalBytes: 1024,
    );

    expect(progress.status, DownloadStatus.downloading);
    expect(progress.downloadedBytes, 512);
    expect(progress.totalBytes, 1024);
    expect(progress.progress, 0.5);
  });

  test('cancel task state transition records canceled reason', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
      ),
      title: 'Direct Test',
      episodeTitle: 'Episode 1',
    );

    await service.cancel(taskId);

    final task = await repository.getTask(taskId);
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.canceled);
    expect(task.failureReason, DownloadFailureReason.canceled);
    expect(task.failureMessage, isNull);
  });

  test('stale stop does not overwrite a completed direct download', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final now = DateTime(2026, 6, 26, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-completed-stop',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.completed,
        failureReason: DownloadFailureReason.none,
        progress: 1,
        totalBytes: 1000,
        downloadedBytes: 1000,
        localPath: '/tmp/video.mp4',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.pause('task-completed-stop');

    final task = await repository.getTask('task-completed-stop');
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.completed);
    expect(task.failureReason, DownloadFailureReason.none);
    expect(task.failureMessage, isNull);
    expect(task.progress, 1);
    expect(task.localPath, '/tmp/video.mp4');
  });

  test('stale cancel does not overwrite a completed direct download', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final now = DateTime(2026, 6, 26, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-completed-cancel',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.completed,
        failureReason: DownloadFailureReason.none,
        progress: 1,
        totalBytes: 1000,
        downloadedBytes: 1000,
        localPath: '/tmp/video.mp4',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.cancel('task-completed-cancel');

    final task = await repository.getTask('task-completed-cancel');
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.completed);
    expect(task.failureReason, DownloadFailureReason.none);
    expect(task.failureMessage, isNull);
    expect(task.progress, 1);
    expect(task.localPath, '/tmp/video.mp4');
  });

  test('stopping a direct download clears stale progress and partial files',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-stop');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final partialFile = File(p.join(tempDir.path, 'partial-stop.mp4'));
    await partialFile.writeAsString('partial');
    final now = DateTime(2026, 6, 26, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-stop-reset',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.downloading,
        failureReason: DownloadFailureReason.none,
        progress: 0.6,
        totalBytes: 1000,
        downloadedBytes: 600,
        localPath: partialFile.path,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.pause('task-stop-reset');

    final task = await repository.getTask('task-stop-reset');
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.paused);
    expect(task.failureReason, DownloadFailureReason.none);
    expect(task.failureMessage, isNull);
    expect(task.progress, 0);
    expect(task.totalBytes, isNull);
    expect(task.downloadedBytes, 0);
    expect(task.localPath, isNull);
    expect(partialFile.existsSync(), isFalse);
  });

  test('canceling a direct download clears stale progress and partial files',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-download-cancel');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final partialFile = File(p.join(tempDir.path, 'partial-cancel.mp4'));
    await partialFile.writeAsString('partial');
    final now = DateTime(2026, 6, 26, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-cancel-reset',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.paused,
        failureReason: DownloadFailureReason.none,
        progress: 0.6,
        totalBytes: 1000,
        downloadedBytes: 600,
        localPath: partialFile.path,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.cancel('task-cancel-reset');

    final task = await repository.getTask('task-cancel-reset');
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.canceled);
    expect(task.failureReason, DownloadFailureReason.canceled);
    expect(task.failureMessage, isNull);
    expect(task.progress, 0);
    expect(task.totalBytes, isNull);
    expect(task.downloadedBytes, 0);
    expect(task.localPath, isNull);
    expect(partialFile.existsSync(), isFalse);
  });

  test(
      'canceling an active direct download stays plain canceled until cleanup actually fails',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-active-cancel');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    final repository = DownloadRepositoryImpl(database);
    final dio = _BlockingCancelDio();
    final service = HttpDownloadService(
      dio: dio,
      repository: repository,
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
      ),
      title: 'Direct Test',
      episodeTitle: 'Episode 1',
    );

    final startFuture = service.start(taskId);
    await dio.downloadStarted.future;

    var cancelSettled = false;
    final cancelFuture = service.cancel(taskId).then((_) {
      cancelSettled = true;
    });
    await Future<void>.delayed(Duration.zero);

    final canceledTask = await repository.getTask(taskId);
    expect(canceledTask, isNotNull);
    expect(canceledTask!.status, DownloadStatus.canceled);
    expect(canceledTask.failureReason, DownloadFailureReason.canceled);
    expect(canceledTask.failureMessage, isNull);
    expect(canceledTask.progress, 0);
    expect(canceledTask.totalBytes, isNull);
    expect(canceledTask.downloadedBytes, 0);
    expect(canceledTask.localPath, isNull);
    expect(cancelSettled, isFalse);

    final partialFile = File(dio.savePath!);
    expect(partialFile.existsSync(), isTrue);

    dio.allowCancelCompletion.complete();
    await cancelFuture;
    await startFuture;

    final finalizedTask = await repository.getTask(taskId);
    expect(finalizedTask, isNotNull);
    expect(finalizedTask!.status, DownloadStatus.canceled);
    expect(finalizedTask.localPath, isNull);
    expect(partialFile.existsSync(), isFalse);
    expect(cancelSettled, isTrue);
  });

  test(
      'pausing an active direct download waits for the canceled attempt to settle',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-active-pause');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    final repository = DownloadRepositoryImpl(database);
    final dio = _BlockingCancelDio();
    final service = HttpDownloadService(
      dio: dio,
      repository: repository,
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
      ),
      title: 'Direct Test',
      episodeTitle: 'Episode 1',
    );

    final startFuture = service.start(taskId);
    await dio.downloadStarted.future;

    var pauseSettled = false;
    final pauseFuture = service.pause(taskId).then((_) {
      pauseSettled = true;
    });
    await Future<void>.delayed(Duration.zero);

    final pausedTask = await repository.getTask(taskId);
    expect(pausedTask, isNotNull);
    expect(pausedTask!.status, DownloadStatus.paused);
    expect(pausedTask.failureReason, DownloadFailureReason.none);
    expect(pausedTask.failureMessage, isNull);
    expect(pausedTask.progress, 0);
    expect(pausedTask.totalBytes, isNull);
    expect(pausedTask.downloadedBytes, 0);
    expect(pausedTask.localPath, isNotNull);
    expect(pauseSettled, isFalse);

    final partialFile = File(dio.savePath!);
    expect(partialFile.existsSync(), isTrue);

    dio.allowCancelCompletion.complete();
    await pauseFuture;
    await startFuture;

    final finalizedTask = await repository.getTask(taskId);
    expect(finalizedTask, isNotNull);
    expect(finalizedTask!.status, DownloadStatus.paused);
    expect(finalizedTask.localPath, isNull);
    expect(partialFile.existsSync(), isFalse);
    expect(pauseSettled, isTrue);
  });

  test('removing a discarded task clears any leftover partial file first',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-remove-discarded');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final partialFile = File(p.join(tempDir.path, 'partial-remove.mp4'));
    await partialFile.writeAsString('partial');
    final now = DateTime(2026, 6, 26, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-remove-discarded',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.canceled,
        failureReason: DownloadFailureReason.canceled,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: null,
        localPath: partialFile.path,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.removeEndedTask('task-remove-discarded');

    final task = await repository.getTask('task-remove-discarded');
    expect(task, isNull);
    expect(partialFile.existsSync(), isFalse);
  });

  test('removing a failed task clears any leftover partial file first',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-remove-failed');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final partialFile = File(p.join(tempDir.path, 'partial-failed-remove.mp4'));
    await partialFile.writeAsString('partial');
    final now = DateTime(2026, 7, 2, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-remove-failed',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.failed,
        failureReason: DownloadFailureReason.networkError,
        failureMessage: 'offline',
        progress: 0.4,
        downloadedBytes: 400,
        totalBytes: 1000,
        localPath: partialFile.path,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.removeEndedTask('task-remove-failed');

    final task = await repository.getTask('task-remove-failed');
    expect(task, isNull);
    expect(partialFile.existsSync(), isFalse);
  });

  test('removing a completed HLS task clears downloaded segment directory',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-remove-hls-completed');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    _mockApplicationDocumentsDirectory(tempDir.path);

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
    );
    final manifestDirectory = Directory(
      p.join(tempDir.path, 'downloads', 'hls-completed-task'),
    );
    final segmentDirectory = Directory(
      p.join(manifestDirectory.path, 'segments'),
    );
    await segmentDirectory.create(recursive: true);
    final manifestFile = File(p.join(manifestDirectory.path, 'index.m3u8'));
    final firstSegment = File(p.join(segmentDirectory.path, 'segment-000000.ts'));
    final secondSegment = File(p.join(segmentDirectory.path, 'segment-000001.ts'));
    await manifestFile.writeAsString('#EXTM3U');
    await firstSegment.writeAsString('segment-1');
    await secondSegment.writeAsString('segment-2');
    final now = DateTime(2026, 7, 24, 0, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-remove-completed-hls',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'HLS Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/index.m3u8',
        kind: DownloadKind.hls,
        status: DownloadStatus.completed,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 1,
        downloadedBytes: 12,
        totalBytes: 12,
        localPath: manifestFile.path,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.removeEndedTask('task-remove-completed-hls');

    final task = await repository.getTask('task-remove-completed-hls');
    expect(task, isNull);
    expect(manifestDirectory.existsSync(), isFalse);
    expect(manifestFile.existsSync(), isFalse);
    expect(firstSegment.existsSync(), isFalse);
    expect(secondSegment.existsSync(), isFalse);
    expect(segmentDirectory.existsSync(), isFalse);
  });

  test('unexpected direct-download failures stay calm in stored task state',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir = await Directory.systemTemp
        .createTemp('ani-destiny-download-unexpected');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    final repository = DownloadRepositoryImpl(database);
    final service = HttpDownloadService(
      dio: _UnexpectedFailureDio(),
      repository: repository,
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
      ),
      title: 'Direct Test',
      episodeTitle: 'Episode 1',
    );

    await expectLater(
      service.start(taskId),
      throwsA(
        isA<AppException>()
            .having(
              (error) => error.code,
              'code',
              'download_unexpected_error',
            )
            .having(
              (error) => error.message,
              'message',
              'AniDestiny could not finish this download because of an unexpected error.',
            ),
      ),
    );

    final task = await repository.getTask(taskId);

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.failed);
    expect(task.failureReason, DownloadFailureReason.unknown);
    expect(
      task.failureMessage,
      'AniDestiny could not finish this download because of an unexpected error.',
    );
  });

  test(
      'retrying a stopped direct download resets stale progress before restart',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final tempDir =
        await Directory.systemTemp.createTemp('ani-destiny-downloads');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    final repository = DownloadRepositoryImpl(database);
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'offline',
              ),
            );
          },
        ),
      );
    final service = HttpDownloadService(
      dio: dio,
      repository: repository,
    );
    final now = DateTime(2026, 6, 25, 20, 0);

    await repository.upsertTask(
      DownloadTask(
        id: 'task-1',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Direct Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        status: DownloadStatus.paused,
        failureReason: DownloadFailureReason.none,
        progress: 0.6,
        totalBytes: 1000,
        downloadedBytes: 600,
        localPath: '/tmp/old-video.mp4',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await expectLater(
      service.start('task-1'),
      throwsA(isA<AppException>()),
    );

    final task = await repository.getTask('task-1');

    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.failed);
    expect(task.progress, 0);
    expect(task.totalBytes, isNull);
    expect(task.downloadedBytes, 0);
    expect(task.localPath, isNotNull);
    expect(p.basename(task.localPath!), 'Direct Test-Episode 1.mp4');
    expect(p.basename(p.dirname(task.localPath!)), 'downloads');
    expect(task.failureReason, DownloadFailureReason.networkError);
    expect(
      task.failureMessage,
      'AniDestiny could not finish this download because the source could not be reached. Retry when the connection is stable.',
    );
    expect(task.failureMessage, isNot(contains('offline')));
  });
}

class _BlockingCancelDio extends DioForNative {
  final Completer<void> downloadStarted = Completer<void>();
  final Completer<void> allowCancelCompletion = Completer<void>();
  String? savePath;

  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    this.savePath = savePath as String;
    final file = File(this.savePath!);
    await file.parent.create(recursive: true);
    await file.writeAsString('partial');
    onReceiveProgress?.call(600, 1000);
    if (!downloadStarted.isCompleted) {
      downloadStarted.complete();
    }
    await cancelToken?.whenCancel;
    await allowCancelCompletion.future;
    throw DioException.requestCancelled(
      requestOptions: RequestOptions(path: urlPath),
      reason: 'canceled',
    );
  }
}

class _UnexpectedFailureDio extends DioForNative {
  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    throw StateError('filesystem sync failed');
  }
}

void _mockApplicationDocumentsDirectory(String path) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return path;
    }
    return null;
  });
}

class _FakeHlsSegmentDownloadDio extends DioForNative {
  _FakeHlsSegmentDownloadDio(this.segmentBytesByUri);

  final Map<String, List<int>> segmentBytesByUri;
  final List<String> downloadedUris = <String>[];

  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    downloadedUris.add(urlPath);
    final bytes = segmentBytesByUri[urlPath] ?? const <int>[];
    final content = Uint8List.fromList(bytes);

    final file = File(savePath as String);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(content);
    onReceiveProgress?.call(content.length, content.length);

    return Response(
      requestOptions: RequestOptions(path: urlPath),
      statusCode: 200,
      data: content,
    );
  }
}

class _FlakyHlsSegmentDownloadDio extends DioForNative {
  _FlakyHlsSegmentDownloadDio(
    this.segmentBytesByUri, {
    Set<String> failOnFirst = const {},
  }) : failOnFirst = Set<String>.from(failOnFirst);

  final Map<String, List<int>> segmentBytesByUri;
  final Set<String> failOnFirst;
  final Map<String, int> _attemptsByUri = {};
  final List<String> downloadedUris = <String>[];

  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    downloadedUris.add(urlPath);
    final attempt = (_attemptsByUri[urlPath] ?? 0) + 1;
    _attemptsByUri[urlPath] = attempt;
    if (failOnFirst.contains(urlPath) && attempt == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: urlPath),
        type: DioExceptionType.connectionError,
        message: 'network unavailable',
      );
    }

    final bytes = segmentBytesByUri[urlPath] ?? const <int>[];
    final content = Uint8List.fromList(bytes);

    final file = File(savePath as String);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(content);
    onReceiveProgress?.call(content.length, content.length);

    return Response(
      requestOptions: RequestOptions(path: urlPath),
      statusCode: 200,
      data: content,
    );
  }
}

class _FakeHlsManifestLoader implements HlsManifestLoader {
  const _FakeHlsManifestLoader(this.loadManifest);

  final Future<HlsManifest> Function(Uri, Map<String, String>) loadManifest;

  @override
  Future<HlsManifest> load(
    Uri manifestUri, {
    Map<String, String> headers = const {},
  }) {
    return loadManifest(manifestUri, headers);
  }
}
