import 'dart:io';

import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/download_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/http_download_service.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_progress.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  test('unsupported HLS task records unsupported failure reason', () async {
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
    expect(task!.status, DownloadStatus.unsupported);
    expect(task.failureReason, DownloadFailureReason.unsupportedType);
    expect(task.failureMessage, contains('HLS offline download'));
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
    expect(task.failureMessage, 'offline');
  });
}
