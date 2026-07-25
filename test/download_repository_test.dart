import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/download_repository_impl.dart';
import 'package:ani_destiny/features/download/data/repositories/offline_media_repository_impl.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/download/domain/entities/offline_media_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DownloadRepository stores headers and upgraded task fields', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = DownloadRepositoryImpl(database);
    final now = DateTime(2026, 5, 30, 10, 30);
    const headers = {
      'referer': 'https://example.test/watch/1',
      'user-agent': 'AniDestiny Test',
    };

    await repository.upsertTask(
      DownloadTask(
        id: 'task-1',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        sourceId: 'sakura',
        title: 'Download Test',
        episodeTitle: 'Episode 1',
        url: 'https://cdn.example.test/video.mp4',
        kind: DownloadKind.directFile,
        headers: headers,
        status: DownloadStatus.downloading,
        failureReason: DownloadFailureReason.none,
        progress: 0.5,
        totalBytes: 1024,
        downloadedBytes: 512,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final restored = await repository.getTask('task-1');

    expect(restored, isNotNull);
    expect(restored!.headers, headers);
    expect(restored.kind, DownloadKind.directFile);
    expect(restored.status, DownloadStatus.downloading);
    expect(restored.failureReason, DownloadFailureReason.none);
    expect(restored.totalBytes, 1024);
    expect(restored.downloadedBytes, 512);
  });

  test('OfflineMediaRepository restores completed assets independently',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final repository = OfflineMediaRepositoryImpl(database);
    final createdAt = DateTime(2026, 7, 25, 20, 30);
    await repository.upsert(
      OfflineMediaItem(
        id: 'offline-task-1',
        downloadTaskId: 'task-1',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        title: 'HLS Test',
        episodeTitle: 'Episode 1',
        manifestPath: '/downloads/task-1/index.m3u8',
        downloadedBytes: 2048,
        createdAt: createdAt,
      ),
    );

    final restored = await repository.getByDownloadTaskId('task-1');

    expect(restored, isNotNull);
    expect(restored!.id, 'offline-task-1');
    expect(restored.manifestPath, '/downloads/task-1/index.m3u8');
    expect(restored.downloadedBytes, 2048);
    expect((await repository.getAll()).single.downloadTaskId, 'task-1');
  });
}
