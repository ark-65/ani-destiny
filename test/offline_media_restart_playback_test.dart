import 'dart:io';

import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/offline_media_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/local_offline_media_service.dart';
import 'package:ani_destiny/features/download/domain/entities/offline_media_item.dart';
import 'package:ani_destiny/features/download/domain/services/offline_media_integrity.dart';
import 'package:ani_destiny/features/download/presentation/pages/download_page.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'offline HLS stays playable after database and service restart',
    () async {
      final tempDirectory =
          await Directory.systemTemp.createTemp('offline-media-restart-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final databasePath = p.join(tempDirectory.path, 'app.sqlite');
      final mediaDirectory =
          Directory(p.join(tempDirectory.path, 'downloads', 'task-1'));
      await mediaDirectory.create(recursive: true);
      final manifest = File(p.join(mediaDirectory.path, 'index.m3u8'));
      final segment = File(p.join(mediaDirectory.path, 'segment-000000.ts'));
      await manifest.writeAsString(
        '#EXTM3U\n'
        '#EXT-X-TARGETDURATION:10\n'
        '#EXTINF:10,\n'
        'segment-000000.ts\n'
        '#EXT-X-ENDLIST\n',
      );
      await segment.writeAsBytes([1, 2, 3]);

      final firstDatabase = AppDatabase(NativeDatabase(File(databasePath)));
      final firstRepository = OfflineMediaRepositoryImpl(firstDatabase);
      final item = OfflineMediaItem(
        id: 'offline-task-1',
        downloadTaskId: 'task-1',
        animeId: 'anime-1',
        episodeId: 'episode-1',
        title: 'Offline Anime',
        episodeTitle: 'Episode 1',
        manifestPath: manifest.path,
        downloadedBytes: await segment.length(),
        createdAt: DateTime(2026, 7, 26),
      );
      await firstRepository.upsert(item);
      expect(
        await LocalOfflineMediaService(
          repository: firstRepository,
        ).verify(item),
        OfflineMediaIntegrityStatus.playable,
      );
      await firstDatabase.close();

      final secondDatabase = AppDatabase(NativeDatabase(File(databasePath)));
      addTearDown(secondDatabase.close);
      final secondRepository = OfflineMediaRepositoryImpl(secondDatabase);
      final restored = (await secondRepository.getAll()).single;

      expect(restored.integrityStatus, OfflineMediaIntegrityStatus.playable);
      expect(
        await LocalOfflineMediaService(
          repository: secondRepository,
        ).verify(restored),
        OfflineMediaIntegrityStatus.playable,
      );
      final routeArgs = offlineMediaPlayerRouteArgs(restored);
      expect(routeArgs.playUrl, Uri.file(manifest.path).toString());
      expect(routeArgs.sourceId, 'offline');
      expect(routeArgs.playHeaders, isEmpty);
      expect(isPlayableOfflineMediaUrl(routeArgs.playUrl), isTrue);
    },
  );
}
