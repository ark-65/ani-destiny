import 'dart:io';

import 'package:ani_destiny/features/download/domain/services/offline_media_integrity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('isPlayableOfflineMediaPath rejects files without a HLS header',
      () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-invalid-header',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString('segment.ts\n');

    expect(isPlayableOfflineMediaPath(manifestPath), isFalse);
  });

  test('isPlayableOfflineMediaPath skips an HLS gap segment', () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-gap',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final segmentPath = p.join(temporaryDir.path, 'segments', 'available.ts');
    await Directory(p.dirname(segmentPath)).create(recursive: true);
    await File(segmentPath).writeAsString('ok');
    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\n'
      '#EXTINF:6,\n'
      'segments/available.ts\n'
      '#EXTINF:6,\n'
      '#EXT-X-GAP\n'
      'segments/missing.ts\n'
      '#EXT-X-ENDLIST\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isTrue);
  });

  test('isPlayableOfflineMediaPath returns true for non-m3u8 media files',
      () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-non-m3u8',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final mediaPath = p.join(temporaryDir.path, 'video.mp4');
    await File(mediaPath).writeAsString('video bytes');

    expect(isPlayableOfflineMediaPath(mediaPath), isTrue);
  });

  test('isPlayableOfflineMediaPath rejects directory paths', () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-directory',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    expect(isPlayableOfflineMediaPath(temporaryDir.path), isFalse);
  });

  test(
      'isPlayableOfflineMediaPath handles reserved characters encoded in segment file names',
      () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-query-chars',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    const encodedSegmentFileName = 'segment%3Fname%23part.ts';
    final segmentPath =
        p.join(temporaryDir.path, 'segments', encodedSegmentFileName);
    await Directory(p.dirname(segmentPath)).create(recursive: true);
    await File(segmentPath).writeAsString('ok');

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\nsegments/$encodedSegmentFileName?download_cache=true\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isTrue);
  });

  test(
      'isPlayableOfflineMediaPath handles encoded backslash segment separators',
      () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-segments',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final segmentPath =
        p.join(temporaryDir.path, 'segments', 'segment name.ts');
    await Directory(p.dirname(segmentPath)).create(recursive: true);
    await File(segmentPath).writeAsString('ok');

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\nsegments%5Csegment%2520name.ts\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isTrue);
  });

  test(
      'isPlayableOfflineMediaPath handles encoded nested separators and spaces',
      () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-segments-nested',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final segmentPath = p.join(
      temporaryDir.path,
      'segments',
      'nested',
      'space name.ts',
    );
    await Directory(p.dirname(segmentPath)).create(recursive: true);
    await File(segmentPath).writeAsString('ok');

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\nsegments%5Cnested%252Fspace%20name.ts\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isTrue);
  });

  test(
    'isPlayableOfflineMediaPath handles absolute Windows paths with double encoding',
    () async {
      const windowsSegmentDirectory = 'C:/ani-destiny-offline/windows';
      const windowsSegmentPath =
          '$windowsSegmentDirectory/segments/episode-000001'
          '/nested/space name.ts';
      const windowsManifestSegment = '$windowsSegmentDirectory/segments%5C'
          'episode-000001%252Fnested%252Fspace%2520name.ts?download_cache=true#retry';

      await Directory(windowsSegmentPath).parent.create(recursive: true);
      await File(windowsSegmentPath).writeAsString('segment');
      addTearDown(() async {
        final segmentDirectory = Directory(windowsSegmentDirectory);
        if (await segmentDirectory.exists()) {
          await segmentDirectory.delete(recursive: true);
        }
      });

      final temporaryDir = await Directory.systemTemp.createTemp(
        'ani-destiny-offline-media-absolute-windows',
      );
      addTearDown(() async {
        await temporaryDir.delete(recursive: true);
      });
      final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
      final localManifest = File(manifestPath);
      await localManifest.writeAsString(
        '#EXTM3U\n$windowsManifestSegment\n',
      );

      expect(isPlayableOfflineMediaPath(manifestPath), isTrue);
    },
    testOn: 'windows',
  );
}
