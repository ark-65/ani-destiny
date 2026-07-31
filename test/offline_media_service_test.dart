import 'dart:io';

import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/offline_media_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/local_offline_media_service.dart';
import 'package:ani_destiny/features/download/domain/entities/offline_media_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('verify reports playable only when manifest segments are complete',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-media-verify-');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final manifest = File(p.join(tempDirectory.path, 'index.m3u8'));
    final segment = File(p.join(tempDirectory.path, 'segment.ts'));
    await manifest.writeAsString('#EXTM3U\nsegment.ts\n');
    await segment.writeAsBytes([1, 2, 3]);
    final service = LocalOfflineMediaService(repository: repository);
    final item = _item(manifest.path);

    expect(
      await service.verify(item),
      OfflineMediaIntegrityStatus.playable,
    );
    var restored = (await repository.getAll()).single;
    expect(restored.integrityStatus, OfflineMediaIntegrityStatus.playable);
    expect(restored.verifiedAt, isNotNull);

    await segment.delete();

    expect(
      await service.verify(item),
      OfflineMediaIntegrityStatus.damaged,
    );
    restored = (await repository.getAll()).single;
    expect(restored.integrityStatus, OfflineMediaIntegrityStatus.damaged);
    expect(restored.verifiedAt, isNotNull);
  });

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

  test('removeAll deletes each episode directory and repository record',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-anime-remove-');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final items = <OfflineMediaItem>[];
    for (var index = 1; index <= 2; index++) {
      final directory = Directory(p.join(tempDirectory.path, 'task-$index'));
      await directory.create();
      final manifest = File(p.join(directory.path, 'index.m3u8'));
      await manifest.writeAsString('#EXTM3U\n');
      final item = OfflineMediaItem(
        id: 'offline-$index',
        downloadTaskId: 'task-$index',
        animeId: 'anime-1',
        episodeId: 'episode-$index',
        title: 'HLS Test',
        episodeTitle: 'Episode $index',
        manifestPath: manifest.path,
        downloadedBytes: 1,
        createdAt: DateTime(2026, 7, 26),
      );
      items.add(item);
      await repository.upsert(item);
    }

    await LocalOfflineMediaService(repository: repository).removeAll(items);

    expect(await repository.getAll(), isEmpty);
    for (var index = 1; index <= 2; index++) {
      expect(
        await Directory(p.join(tempDirectory.path, 'task-$index')).exists(),
        isFalse,
      );
    }
  });

  test('removeAll keeps deleting remaining items when one item cleanup fails',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-anime-remove-failure-');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final firstDirectory = Directory(p.join(tempDirectory.path, 'task-first'));
    final secondDirectory = Directory(p.join(tempDirectory.path, 'task-second'));
    final thirdDirectory = Directory(p.join(tempDirectory.path, 'task-third'));
    await Future.wait([
      firstDirectory.create(),
      secondDirectory.create(),
      thirdDirectory.create(),
    ]);

    final firstManifest = File(p.join(firstDirectory.path, 'index.m3u8'));
    final secondManifest = File(p.join(secondDirectory.path, 'index.m3u8'));
    final thirdManifest = File(p.join(thirdDirectory.path, 'index.m3u8'));
    await firstManifest.writeAsString('#EXTM3U\n');
    await secondManifest.writeAsString('#EXTM3U\n');
    await thirdManifest.writeAsString('#EXTM3U\n');

    final items = <OfflineMediaItem>[
      OfflineMediaItem(
        id: 'offline-first',
        downloadTaskId: 'task-first',
        animeId: 'anime-1',
        episodeId: 'episode-first',
        title: 'HLS Test',
        episodeTitle: 'Episode first',
        manifestPath: firstManifest.path,
        downloadedBytes: 1,
        createdAt: DateTime(2026, 7, 26),
      ),
      OfflineMediaItem(
        id: 'offline-second',
        downloadTaskId: 'task-second',
        animeId: 'anime-1',
        episodeId: 'episode-second',
        title: 'HLS Test',
        episodeTitle: 'Episode second',
        manifestPath: secondManifest.path,
        downloadedBytes: 1,
        createdAt: DateTime(2026, 7, 26),
      ),
      OfflineMediaItem(
        id: 'offline-third',
        downloadTaskId: 'task-third',
        animeId: 'anime-1',
        episodeId: 'episode-third',
        title: 'HLS Test',
        episodeTitle: 'Episode third',
        manifestPath: thirdManifest.path,
        downloadedBytes: 1,
        createdAt: DateTime(2026, 7, 26),
      ),
    ];
    for (final item in items) {
      await repository.upsert(item);
    }

    final service = LocalOfflineMediaService(
      repository: repository,
      directoryRemover: (path) {
        if (path == secondDirectory.path) {
          throw const FileSystemException('blocked');
        }
        return Directory(path).delete(recursive: true);
      },
    );

    await expectLater(
      service.removeAll(items),
      throwsA(
        isA<AppException>().having(
          (exception) => exception.code,
          'code',
          'offline_media_cleanup_batch_failed',
        ),
      ),
    );

    final remaining = await repository.getAll();
    expect(
      remaining.map((item) => item.id).toSet(),
      {'offline-second'},
    );
    expect(await firstDirectory.exists(), isFalse);
    expect(await secondDirectory.exists(), isTrue);
    expect(await thirdDirectory.exists(), isFalse);
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
