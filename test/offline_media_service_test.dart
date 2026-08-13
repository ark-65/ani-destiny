import 'dart:io';

import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/offline_media_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/local_offline_media_service.dart';
import 'package:ani_destiny/features/download/domain/entities/offline_media_item.dart';
import 'package:ani_destiny/features/download/domain/repositories/offline_media_repository.dart';
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

  test('verify maps manifest parser exceptions to damaged status', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-media-verify-exception-');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final manifest = File(p.join(tempDirectory.path, 'index.m3u8'));
    await manifest.writeAsString('#EXTM3U\nsegment.ts\n');
    final item = _item(manifest.path);
    await repository.upsert(item);
    final service = LocalOfflineMediaService(
      repository: repository,
      manifestVerifier: (_) => throw StateError('broken manifest parser'),
    );

    expect(
      await service.verify(item),
      OfflineMediaIntegrityStatus.damaged,
    );
    final restored = (await repository.getAll()).single;
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

  test('remove keeps the database record when cleanup throws non-fs error',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final item = _item('/downloads/task-1/index.m3u8');
    await repository.upsert(item);
    final service = LocalOfflineMediaService(
      repository: repository,
      directoryRemover: (_) => throw StateError('unexpected cleanup failure'),
    );

    await expectLater(
      service.remove(item),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'offline_media_cleanup_failed',
        ),
      ),
    );

    expect((await repository.getAll()).single.id, item.id);
  });

  test('remove maps repository delete failure to cleanup failure code',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);
    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-media-repo-delete-');
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
    final service = LocalOfflineMediaService(
      repository: _FailingDeleteRepository(
        delegate: repository,
        failingItemIds: {item.id},
      ),
    );

    await expectLater(
      service.remove(item),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'offline_media_cleanup_failed',
        ),
      ),
    );

    expect((await repository.getAll()).single.id, item.id);
    expect(await mediaDirectory.exists(), isFalse);
  });

  test(
    'remove maps cleanup AppException to unified cleanup failure code',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = OfflineMediaRepositoryImpl(database);
      final item = _item('/downloads/task-1/index.m3u8');
      await repository.upsert(item);
      final service = LocalOfflineMediaService(
        repository: repository,
        directoryRemover: (_) => throw const AppException(
          'cleanup blocked by policy',
          code: 'some_other_code',
        ),
      );

      await expectLater(
        service.remove(item),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'offline_media_cleanup_failed',
          ),
        ),
      );

      expect((await repository.getAll()).single.id, item.id);
    },
  );

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
    final secondDirectory =
        Directory(p.join(tempDirectory.path, 'task-second'));
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

  test(
    'removeAll continues when repository delete fails and returns batch failure code',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = OfflineMediaRepositoryImpl(database);
      final tempDirectory = await Directory.systemTemp
          .createTemp('offline-anime-repo-delete-failure-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final firstDirectory =
          Directory(p.join(tempDirectory.path, 'task-first'));
      final secondDirectory =
          Directory(p.join(tempDirectory.path, 'task-second'));
      final thirdDirectory =
          Directory(p.join(tempDirectory.path, 'task-third'));
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
        repository: _FailingDeleteRepository(
          delegate: repository,
          failingItemIds: {'offline-second'},
        ),
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
      expect(remaining.map((item) => item.id).toSet(), {'offline-second'});
      expect(await firstDirectory.exists(), isFalse);
      expect(await secondDirectory.exists(), isFalse);
      expect(await thirdDirectory.exists(), isFalse);
    },
  );

  test(
    'removeAll maps repository AppException failure to batch failure code',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = OfflineMediaRepositoryImpl(database);
      final tempDirectory = await Directory.systemTemp
          .createTemp('offline-anime-repo-delete-app-error-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final failingDirectory =
          Directory(p.join(tempDirectory.path, 'task-fail'));
      final successDirectory =
          Directory(p.join(tempDirectory.path, 'task-success'));
      await Future.wait([failingDirectory.create(), successDirectory.create()]);

      final failingManifest = File(p.join(failingDirectory.path, 'index.m3u8'));
      final successManifest = File(p.join(successDirectory.path, 'index.m3u8'));
      await failingManifest.writeAsString('#EXTM3U\n');
      await successManifest.writeAsString('#EXTM3U\n');

      final items = <OfflineMediaItem>[
        OfflineMediaItem(
          id: 'offline-fail',
          downloadTaskId: 'task-fail',
          animeId: 'anime-1',
          episodeId: 'episode-fail',
          title: 'HLS Test',
          episodeTitle: 'Episode fail',
          manifestPath: failingManifest.path,
          downloadedBytes: 1,
          createdAt: DateTime(2026, 7, 26),
        ),
        OfflineMediaItem(
          id: 'offline-success',
          downloadTaskId: 'task-success',
          animeId: 'anime-1',
          episodeId: 'episode-success',
          title: 'HLS Test',
          episodeTitle: 'Episode success',
          manifestPath: successManifest.path,
          downloadedBytes: 1,
          createdAt: DateTime(2026, 7, 26),
        ),
      ];
      for (final item in items) {
        await repository.upsert(item);
      }

      final service = LocalOfflineMediaService(
        repository: _FailingDeleteRepository(
          delegate: repository,
          failingItemIds: {'offline-fail'},
          error: const AppException(
            'cleanup blocked by policy',
            code: 'some_other_code',
          ),
        ),
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
      expect(remaining.single.id, 'offline-fail');
      expect(await failingDirectory.exists(), isFalse);
      expect(await successDirectory.exists(), isFalse);
    },
  );

  test(
    'removeAll continues for mixed directory-repo failures and keeps failed items',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = OfflineMediaRepositoryImpl(database);
      final tempDirectory =
          await Directory.systemTemp.createTemp('offline-anime-mixed-failure-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final firstDirectory =
          Directory(p.join(tempDirectory.path, 'task-first'));
      final secondDirectory =
          Directory(p.join(tempDirectory.path, 'task-second'));
      final thirdDirectory =
          Directory(p.join(tempDirectory.path, 'task-third'));
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
        repository: _FailingDeleteRepository(
          delegate: repository,
          failingItemIds: {'offline-third'},
        ),
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
        {'offline-second', 'offline-third'},
      );
      expect(await firstDirectory.exists(), isFalse);
      expect(await secondDirectory.exists(), isTrue);
      expect(await thirdDirectory.exists(), isFalse);
    },
  );

  test(
    'removeAll maps non-AppException failures to batch failure and keeps all failed items',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = OfflineMediaRepositoryImpl(database);
      final rawFailureItem = OfflineMediaItem(
        id: 'offline-task-raw-fail',
        downloadTaskId: 'task-raw-fail',
        animeId: 'anime-1',
        episodeId: 'episode-raw-fail',
        title: 'HLS Test',
        episodeTitle: 'Episode raw',
        manifestPath: '/downloads/task-raw-fail/index.m3u8',
        downloadedBytes: 3,
        createdAt: DateTime(2026, 7, 25),
      );
      final appFailureItem = OfflineMediaItem(
        id: 'offline-task-app-fail',
        downloadTaskId: 'task-app-fail',
        animeId: 'anime-1',
        episodeId: 'episode-app-fail',
        title: 'HLS Test',
        episodeTitle: 'Episode app',
        manifestPath: '/downloads/task-app-fail/index.m3u8',
        downloadedBytes: 3,
        createdAt: DateTime(2026, 7, 25),
      );
      await repository.upsert(rawFailureItem);
      await repository.upsert(appFailureItem);

      final service = _ThrowingRemoveService(
        repository: repository,
        errors: [
          StateError('raw failure one'),
          const AppException(
            'expected app failure',
            code: 'some_other_code',
          ),
        ],
      );

      final items = await repository.getAll();

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
      expect(remaining.map((item) => item.id).toSet(), {
        rawFailureItem.id,
        appFailureItem.id,
      });
    },
  );
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

class _FailingDeleteRepository implements OfflineMediaRepository {
  _FailingDeleteRepository({
    required OfflineMediaRepository delegate,
    required Set<String> failingItemIds,
    Object? error,
  })  : _delegate = delegate,
        _failingItemIds = failingItemIds,
        _error = error;

  final OfflineMediaRepository _delegate;
  final Set<String> _failingItemIds;
  final Object? _error;

  @override
  Future<void> delete(String id) async {
    if (_failingItemIds.contains(id)) {
      throw _error ?? StateError('persistent delete failure');
    }
    await _delegate.delete(id);
  }

  @override
  Future<List<OfflineMediaItem>> getAll() => _delegate.getAll();

  @override
  Stream<List<OfflineMediaItem>> watchAll() => _delegate.watchAll();

  @override
  Future<OfflineMediaItem?> getByDownloadTaskId(String downloadTaskId) =>
      _delegate.getByDownloadTaskId(downloadTaskId);

  @override
  Future<void> upsert(OfflineMediaItem item) => _delegate.upsert(item);
}

class _ThrowingRemoveService extends LocalOfflineMediaService {
  _ThrowingRemoveService({
    required super.repository,
    required List<Object> errors,
  }) : _errors = errors;

  final List<Object> _errors;
  var _index = 0;

  @override
  Future<void> remove(OfflineMediaItem item) async {
    final error = _errors[_index++ % _errors.length];
    if (error is AppException) {
      throw error;
    }
    throw error;
  }
}
