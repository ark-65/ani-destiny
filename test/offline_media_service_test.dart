import 'dart:io';

import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/offline_media_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/local_offline_media_service.dart';
import 'package:ani_destiny/features/download/domain/entities/offline_media_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('remove deletes the asset directory before its database record',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-media-remove-');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final mediaDirectory =
        Directory(p.join(tempDirectory.path, 'downloads', 'task-1'));
    await mediaDirectory.create(recursive: true);
    final manifest = File(p.join(mediaDirectory.path, 'index.m3u8'));
    final segment = File(p.join(mediaDirectory.path, 'segment.ts'));
    await manifest.writeAsString('#EXTM3U\nsegment.ts\n');
    await segment.writeAsBytes([1, 2, 3]);
    final item = _item(manifest.path);
    await repository.upsert(item);

    await LocalOfflineMediaService(repository: repository).remove(item);

    expect(await mediaDirectory.exists(), isFalse);
    expect(await repository.getAll(), isEmpty);
  });

  test('remove keeps the database record when file cleanup fails', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final item = _item('/downloads/task-1/index.m3u8');
    await repository.upsert(item);
    final service = LocalOfflineMediaService(
      repository: repository,
      directoryRemover: (_) => throw const FileSystemException('denied'),
    );

    await expectLater(service.remove(item), throwsA(isA<Exception>()));

    expect((await repository.getAll()).single.id, item.id);
  });
}

OfflineMediaItem _item(String manifestPath) {
  return OfflineMediaItem(
    id: 'offline-task-1',
    downloadTaskId: 'task-1',
    animeId: 'anime-1',
    episodeId: 'episode-1',
    title: 'HLS Test',
    episodeTitle: 'Episode 1',
    manifestPath: manifestPath,
    downloadedBytes: 3,
    createdAt: DateTime(2026, 7, 25),
  );
}
