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

  test(
    'alternate audio HLS stays playable after database and service restart',
    () async {
      final tempDirectory =
          await Directory.systemTemp.createTemp('offline-media-audio-restart-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final databasePath = p.join(tempDirectory.path, 'app.sqlite');
      final mediaDirectory =
          Directory(p.join(tempDirectory.path, 'downloads', 'task-audio'));
      final videoDirectory = Directory(p.join(mediaDirectory.path, 'video'));
      final audioDirectory = Directory(p.join(mediaDirectory.path, 'audio'));
      await videoDirectory.create(recursive: true);
      await audioDirectory.create(recursive: true);
      final masterManifest = File(p.join(mediaDirectory.path, 'index.m3u8'));
      final videoManifest = File(p.join(videoDirectory.path, 'index.m3u8'));
      final audioManifest = File(p.join(audioDirectory.path, 'index.m3u8'));
      final videoSegment = File(p.join(videoDirectory.path, 'segment.ts'));
      final audioSegment = File(p.join(audioDirectory.path, 'segment.aac'));
      await masterManifest.writeAsString(
        '#EXTM3U\n'
        '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="offline-audio",'
        'NAME="Japanese",DEFAULT=YES,AUTOSELECT=YES,'
        'URI="audio/index.m3u8"\n'
        '#EXT-X-STREAM-INF:BANDWIDTH=2400000,AUDIO="offline-audio"\n'
        'video/index.m3u8\n',
      );
      await videoManifest.writeAsString(
        '#EXTM3U\n'
        '#EXT-X-TARGETDURATION:6\n'
        '#EXTINF:6,\n'
        'segment.ts\n'
        '#EXT-X-ENDLIST\n',
      );
      await audioManifest.writeAsString(
        '#EXTM3U\n'
        '#EXT-X-TARGETDURATION:6\n'
        '#EXTINF:6,\n'
        'segment.aac\n'
        '#EXT-X-ENDLIST\n',
      );
      await videoSegment.writeAsBytes([1, 2, 3, 4]);
      await audioSegment.writeAsBytes([5, 6, 7]);

      final firstDatabase = AppDatabase(NativeDatabase(File(databasePath)));
      final firstRepository = OfflineMediaRepositoryImpl(firstDatabase);
      final item = OfflineMediaItem(
        id: 'offline-task-audio',
        downloadTaskId: 'task-audio',
        animeId: 'anime-1',
        episodeId: 'episode-audio',
        title: 'Offline Anime',
        episodeTitle: 'Episode with alternate audio',
        manifestPath: masterManifest.path,
        downloadedBytes:
            await videoSegment.length() + await audioSegment.length(),
        createdAt: DateTime(2026, 7, 28),
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
      expect(routeArgs.playUrl, Uri.file(masterManifest.path).toString());
      expect(routeArgs.sourceId, 'offline');
      expect(routeArgs.playHeaders, isEmpty);
      expect(isPlayableOfflineMediaUrl(routeArgs.playUrl), isTrue);
    },
  );
}
