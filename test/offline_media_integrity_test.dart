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

  test('isPlayableOfflineMediaPath rejects remote URLs', () async {
    expect(
      isPlayableOfflineMediaPath('https://example.com/episode/index.m3u8'),
      isFalse,
    );
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

  test('isPlayableOfflineMediaPath rejects segment directory paths', () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-segment-directory',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final segmentDirectory = p.join(temporaryDir.path, 'segments');
    await Directory(segmentDirectory).create(recursive: true);

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\n'
      '#EXTINF:8,\n'
      'segments\n'
      '#EXT-X-ENDLIST\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isFalse);
  });

  test('isPlayableOfflineMediaPath rejects path traversal outside manifest directory',
      () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-manifest-traversal-root',
    );
    addTearDown(() async {
      await temporaryRoot.delete(recursive: true);
    });

    final manifestDirectory = p.join(temporaryRoot.path, 'manifest');
    await Directory(manifestDirectory).create(recursive: true);

    final outsideDirectory = p.join(temporaryRoot.path, 'outside');
    await Directory(outsideDirectory).create(recursive: true);
    await File(p.join(outsideDirectory, 'escape.ts')).writeAsString('ok');

    final manifestPath = p.join(manifestDirectory, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\n'
      '../outside/escape.ts\n'
      '#EXT-X-ENDLIST\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isFalse);
  });

  test('isPlayableOfflineMediaPath rejects map directory paths', () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-map-directory',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final mapDirectory = p.join(temporaryDir.path, 'maps');
    await Directory(mapDirectory).create(recursive: true);
    await File(p.join(temporaryDir.path, 'segment.ts')).writeAsString('ok');

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\n'
      '#EXT-X-MAP:URI="maps"\n'
      '#EXTINF:8,\n'
      'segment.ts\n'
      '#EXT-X-ENDLIST\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isFalse);
  });

  test('isPlayableOfflineMediaPath rejects key directory paths', () async {
    final temporaryDir = await Directory.systemTemp.createTemp(
      'ani-destiny-offline-media-key-directory',
    );
    addTearDown(() async {
      await temporaryDir.delete(recursive: true);
    });

    final keyDirectory = p.join(temporaryDir.path, 'keys');
    await Directory(keyDirectory).create(recursive: true);
    await File(p.join(temporaryDir.path, 'segment.ts')).writeAsString('ok');

    final manifestPath = p.join(temporaryDir.path, 'index.m3u8');
    await File(manifestPath).writeAsString(
      '#EXTM3U\n'
      '#EXT-X-TARGETDURATION:6\n'
      '#EXT-X-KEY:METHOD=AES-128,URI="keys"\n'
      '#EXTINF:6,\n'
      'segment.ts\n'
      '#EXT-X-ENDLIST\n',
    );

    expect(isPlayableOfflineMediaPath(manifestPath), isFalse);
  });

  test(
    'isPlayableOfflineMediaPath handles absolute Windows paths with double encoding',
    () async {
      final temporaryDir = await Directory.systemTemp.createTemp(
        'ani-destiny-offline-media-absolute-windows',
      );
      addTearDown(() async {
        await temporaryDir.delete(recursive: true);
      });

      final windowsSegmentDirectory = p.join(temporaryDir.path, 'windows');
      final windowsSegmentPath = p.join(
        windowsSegmentDirectory,
        'segments',
        'episode-000001',
        'nested',
        'space name.ts',
      );
      final windowsManifestSegment =
          '${windowsSegmentDirectory.replaceAll('\\', '/')}/segments%5C'
          'episode-000001%252Fnested%252Fspace%2520name.ts?download_cache=true#retry';

      await Directory(windowsSegmentPath).parent.create(recursive: true);
      await File(windowsSegmentPath).writeAsString('segment');

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
