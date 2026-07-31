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

  test(
    'encrypted local HLS with init segment stays playable after database restart',
    () async {
      final tempDirectory =
          await Directory.systemTemp.createTemp('offline-media-encrypted-restart-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final databasePath = p.join(tempDirectory.path, 'app.sqlite');
      final mediaDirectory =
          Directory(p.join(tempDirectory.path, 'downloads', 'task-encrypted'));
      final mediaSegmentsDirectory = Directory(p.join(mediaDirectory.path, 'segments'));
      await mediaDirectory.create(recursive: true);
      await mediaSegmentsDirectory.create(recursive: true);

      final manifest = File(p.join(mediaDirectory.path, 'index.m3u8'));
      final initSegment = File(p.join(mediaDirectory.path, 'init.mp4'));
      final segment = File(p.join(mediaDirectory.path, 'segment.ts'));
      final keyFile = File(p.join(mediaSegmentsDirectory.path, 'segment.key'));

      await manifest.writeAsString(
        '#EXTM3U\n'
        '#EXT-X-TARGETDURATION:6\n'
        '#EXT-X-MAP:URI="init.mp4"\n'
        '#EXT-X-KEY:METHOD=AES-128,URI="segments/segment.key"\n'
        '#EXTINF:6,\n'
        'segment.ts\n'
        '#EXT-X-ENDLIST\n',
      );
      await initSegment.writeAsBytes([1, 2, 3]);
      await segment.writeAsBytes([4, 5, 6]);
      await keyFile.writeAsBytes(List<int>.filled(16, 7));

      final firstDatabase = AppDatabase(NativeDatabase(File(databasePath)));
      final firstRepository = OfflineMediaRepositoryImpl(firstDatabase);
      final item = OfflineMediaItem(
        id: 'offline-task-encrypted',
        downloadTaskId: 'task-encrypted',
        animeId: 'anime-2',
        episodeId: 'episode-encrypted',
        title: 'Offline Anime Encrypted',
        episodeTitle: 'Episode encrypted',
        manifestPath: manifest.path,
        downloadedBytes: await initSegment.length() +
            await segment.length() +
            await keyFile.length(),
        createdAt: DateTime(2026, 7, 29),
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
      final secondRepository = OfflineMediaRepositoryImpl(secondDatabase);
      final restored = (await secondRepository.getAll()).single;

      expect(restored.integrityStatus, OfflineMediaIntegrityStatus.playable);
      final service = LocalOfflineMediaService(
        repository: secondRepository,
      );
      expect(await service.verify(restored), OfflineMediaIntegrityStatus.playable);

      final routeArgs = offlineMediaPlayerRouteArgs(restored);
      expect(routeArgs.playUrl, Uri.file(manifest.path).toString());
      expect(routeArgs.sourceId, 'offline');
      expect(routeArgs.playHeaders, isEmpty);
      expect(isPlayableOfflineMediaUrl(routeArgs.playUrl), isTrue);

      await keyFile.delete();
      expect(await service.verify(restored), OfflineMediaIntegrityStatus.damaged);
    },
  );

  test(
    'offline HLS stays playable after two consecutive database and service restarts',
    () async {
      final tempDirectory =
          await Directory.systemTemp.createTemp('offline-media-double-restart-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final databasePath = p.join(tempDirectory.path, 'app.sqlite');
      final mediaDirectory =
          Directory(p.join(tempDirectory.path, 'downloads', 'task-double-restart'));
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
        id: 'offline-task-double-restart',
        downloadTaskId: 'task-double-restart',
        animeId: 'anime-1',
        episodeId: 'episode-double-restart',
        title: 'Offline Anime',
        episodeTitle: 'Episode with double restart',
        manifestPath: manifest.path,
        downloadedBytes: await segment.length(),
        createdAt: DateTime(2026, 7, 30),
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
      final secondRepository = OfflineMediaRepositoryImpl(secondDatabase);
      final firstRestore = (await secondRepository.getAll()).single;
      expect(firstRestore.integrityStatus, OfflineMediaIntegrityStatus.playable);
      expect(
        await LocalOfflineMediaService(
          repository: secondRepository,
        ).verify(firstRestore),
        OfflineMediaIntegrityStatus.playable,
      );
      await secondDatabase.close();

      final thirdDatabase = AppDatabase(NativeDatabase(File(databasePath)));
      addTearDown(thirdDatabase.close);
      final thirdRepository = OfflineMediaRepositoryImpl(thirdDatabase);
      final secondRestore = (await thirdRepository.getAll()).single;

      expect(secondRestore.integrityStatus, OfflineMediaIntegrityStatus.playable);
      final routeArgs = offlineMediaPlayerRouteArgs(secondRestore);
      expect(routeArgs.playUrl, Uri.file(manifest.path).toString());
      expect(routeArgs.sourceId, 'offline');
      expect(routeArgs.playHeaders, isEmpty);
      expect(isPlayableOfflineMediaUrl(routeArgs.playUrl), isTrue);
      expect(
        await LocalOfflineMediaService(
          repository: thirdRepository,
        ).verify(secondRestore),
        OfflineMediaIntegrityStatus.playable,
      );
    },
  );

  test(
    'offline HLS survives recheck after restart and supports full delete flow',
    () async {
      final tempDirectory = await Directory.systemTemp
          .createTemp('offline-media-recheck-delete-');
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final databasePath = p.join(tempDirectory.path, 'app.sqlite');
      final mediaDirectory =
          Directory(p.join(tempDirectory.path, 'downloads', 'task-delete'));
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
        id: 'offline-task-recheck-delete',
        downloadTaskId: 'task-delete',
        animeId: 'anime-3',
        episodeId: 'episode-recheck-delete',
        title: 'Offline Anime',
        episodeTitle: 'Episode for recheck delete',
        manifestPath: manifest.path,
        downloadedBytes: await segment.length(),
        createdAt: DateTime(2026, 7, 31),
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
      final secondRepository = OfflineMediaRepositoryImpl(secondDatabase);
      final restored = (await secondRepository.getAll()).single;

      expect(restored.integrityStatus, OfflineMediaIntegrityStatus.playable);
      expect(
        await LocalOfflineMediaService(
          repository: secondRepository,
        ).verify(restored),
        OfflineMediaIntegrityStatus.playable,
      );

      await LocalOfflineMediaService(
        repository: secondRepository,
      ).remove(restored);

      expect(await secondRepository.getAll(), isEmpty);
      expect(await mediaDirectory.exists(), isFalse);

      await secondDatabase.close();

      final thirdDatabase = AppDatabase(NativeDatabase(File(databasePath)));
      addTearDown(thirdDatabase.close);
      final thirdRepository = OfflineMediaRepositoryImpl(thirdDatabase);
      expect(await thirdRepository.getAll(), isEmpty);
    },
  );
}
