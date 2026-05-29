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
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
