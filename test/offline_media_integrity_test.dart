import 'dart:io';

import 'package:ani_destiny/features/download/domain/services/offline_media_integrity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
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
    final segmentPath = p.join(temporaryDir.path, 'segments', encodedSegmentFileName);
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
}
