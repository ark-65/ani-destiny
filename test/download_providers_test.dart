import 'dart:io';

import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/offline_media_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/local_offline_media_service.dart';
import 'package:ani_destiny/features/download/domain/entities/offline_media_item.dart';
import 'package:ani_destiny/features/download/presentation/providers/download_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('offline media items are refreshed during provider startup', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMediaRepositoryImpl(database);

    final tempDirectory =
        await Directory.systemTemp.createTemp('offline-media-integrity-startup-');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final playableDirectory = Directory(
      p.join(tempDirectory.path, 'playable'),
    );
    final damagedDirectory = Directory(p.join(tempDirectory.path, 'damaged'));
    await Future.wait([
      playableDirectory.create(),
      damagedDirectory.create(),
    ]);

    final playableManifest = File(p.join(playableDirectory.path, 'index.m3u8'));
    final playableSegment = File(p.join(playableDirectory.path, 'segment.ts'));
    await playableManifest.writeAsString('#EXTM3U\nsegment.ts\n');
    await playableSegment.writeAsBytes([1, 2, 3]);

    final damagedManifest = File(p.join(damagedDirectory.path, 'index.m3u8'));
    await damagedManifest.writeAsString('#EXTM3U\nsegment.ts\n');

    await repository.upsert(
      _offlineMediaItem(id: 'playable', manifestPath: playableManifest.path),
    );
    await repository.upsert(
      _offlineMediaItem(id: 'damaged', manifestPath: damagedManifest.path),
    );

    final container = ProviderContainer(
      overrides: [
        offlineMediaRepositoryProvider.overrideWithValue(repository),
        offlineMediaServiceProvider.overrideWithValue(
          LocalOfflineMediaService(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final items = await container.read(offlineMediaItemsProvider.future);
    final byId = <String, OfflineMediaItem>{
      for (final item in items) item.id: item,
    };

    expect(byId['playable']?.integrityStatus, OfflineMediaIntegrityStatus.playable);
    expect(byId['damaged']?.integrityStatus, OfflineMediaIntegrityStatus.damaged);
  });
}

OfflineMediaItem _offlineMediaItem({
  required String id,
  required String manifestPath,
}) {
  return OfflineMediaItem(
    id: id,
    downloadTaskId: 'task-$id',
    animeId: 'anime-1',
    episodeId: 'episode-$id',
    title: 'HLS Test',
    episodeTitle: 'Episode $id',
    manifestPath: manifestPath,
    downloadedBytes: 1024,
    createdAt: DateTime(2026, 8, 13),
  );
}
