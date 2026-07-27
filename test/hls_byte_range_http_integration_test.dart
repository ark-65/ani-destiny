@TestOn('vm')
library;

import 'dart:io';

import 'package:ani_destiny/core/storage/app_database.dart';
import 'package:ani_destiny/features/download/data/repositories/download_repository_impl.dart';
import 'package:ani_destiny/features/download/data/services/hls_manifest_loader.dart';
import 'package:ani_destiny/features/download/data/services/hls_manifest_parser.dart';
import 'package:ani_destiny/features/download/data/services/http_download_service.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/download/domain/entities/hls_manifest.dart';
import 'package:ani_destiny/features/download/domain/services/hls_manifest_loader.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('real HTTP 206 ranges become independent local HLS files', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('ani-destiny-hls-http-range');
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    const sourceBytes = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    final receivedRanges = <String?>[];
    server.listen((request) {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      receivedRanges.add(range);
      final match = RegExp(r'^bytes=(\d+)-(\d+)$').firstMatch(range ?? '');
      if (request.uri.path != '/media.mp4' || match == null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.close();
        return;
      }
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2)!);
      request.response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/${sourceBytes.length}',
        )
        ..add(sourceBytes.sublist(start, end + 1))
        ..close();
    });

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DownloadRepositoryImpl(database);
    final mediaUri =
        Uri.parse('http://${server.address.host}:${server.port}/media.mp4');
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
      applicationDocumentsDirectory: () async => tempDirectory,
      hlsManifestLoader: _StaticManifestLoader(
        const HlsManifestParser().parse(
          '''
#EXTM3U
#EXT-X-MAP:URI="$mediaUri",BYTERANGE="4@0"
#EXTINF:6,
#EXT-X-BYTERANGE:5@4
$mediaUri
#EXTINF:6,
#EXT-X-BYTERANGE:3
$mediaUri
#EXT-X-ENDLIST
''',
          uri: Uri.parse(
            'http://${server.address.host}:${server.port}/index.m3u8',
          ),
        ),
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'loopback',
      source: DownloadSource(
        url: 'http://${server.address.host}:${server.port}/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS HTTP Range Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = (await repository.getTask(taskId))!;
    expect(task.status, DownloadStatus.completed);
    expect(task.downloadedBytes, sourceBytes.length);
    expect(receivedRanges, ['bytes=0-3', 'bytes=4-8', 'bytes=9-11']);
    final manifest = File(task.localPath!);
    expect(await manifest.readAsString(), isNot(contains('http://')));
    expect(
      await File(
        p.join(manifest.parent.path, 'segments', 'initialization.mp4'),
      ).readAsBytes(),
      [0, 1, 2, 3],
    );
    expect(
      await File(
        p.join(manifest.parent.path, 'segments', 'segment-000000.mp4'),
      ).readAsBytes(),
      [4, 5, 6, 7, 8],
    );
    expect(
      await File(
        p.join(manifest.parent.path, 'segments', 'segment-000001.mp4'),
      ).readAsBytes(),
      [9, 10, 11],
    );
  });

  test('quoted comma asset URIs survive parsing and real HTTP download',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('ani-destiny-hls-http-comma');
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final requestedUris = <String>[];
    const assets = <String, List<int>>{
      '/key.bin?token=alpha,beta': [
        1,
        2,
        3,
        4,
        1,
        2,
        3,
        4,
        1,
        2,
        3,
        4,
        1,
        2,
        3,
        4,
      ],
      '/init.mp4?token=gamma,delta': [5, 6, 7, 8],
      '/segment.m4s': [9, 10, 11, 12],
    };
    server.listen((request) {
      final requestUri = request.uri.toString();
      requestedUris.add(requestUri);
      final bytes = assets[requestUri];
      if (bytes == null) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.add(bytes);
      }
      request.response.close();
    });

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DownloadRepositoryImpl(database);
    final origin = 'http://${server.address.host}:${server.port}';
    final service = HttpDownloadService(
      dio: Dio(),
      repository: repository,
      applicationDocumentsDirectory: () async => tempDirectory,
      hlsManifestLoader: _StaticManifestLoader(
        const HlsManifestParser().parse(
          '''
#EXTM3U
#EXT-X-MAP:URI="$origin/init.mp4?token=gamma,delta"
#EXT-X-KEY:METHOD=AES-128,URI="$origin/key.bin?token=alpha,beta"
#EXTINF:6,
$origin/segment.m4s
#EXT-X-ENDLIST
''',
          uri: Uri.parse('$origin/index.m3u8'),
        ),
      ),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'loopback',
      source: DownloadSource(
        url: '$origin/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Quoted Attribute Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = (await repository.getTask(taskId))!;
    expect(task.status, DownloadStatus.completed);
    expect(task.downloadedBytes, 24);
    expect(
      requestedUris,
      [
        '/key.bin?token=alpha,beta',
        '/init.mp4?token=gamma,delta',
        '/segment.m4s',
      ],
    );
    final localManifest = await File(task.localPath!).readAsString();
    expect(localManifest, isNot(contains(origin)));
    expect(localManifest, contains('segments/key-000000.key'));
    expect(localManifest, contains('segments/initialization.mp4'));
    expect(localManifest, contains('segments/segment-000000.m4s'));
  });

  test('defined HLS variables resolve through real HTTP into local assets',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('ani-destiny-hls-http-define');
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final requestedUris = <String>[];
    const keyBytes = <int>[
      1,
      2,
      3,
      4,
      1,
      2,
      3,
      4,
      1,
      2,
      3,
      4,
      1,
      2,
      3,
      4,
    ];
    server.listen((request) {
      final requestUri = request.uri.toString();
      requestedUris.add(requestUri);
      switch (request.uri.path) {
        case '/master.m3u8':
          request.response.write(r'''
#EXTM3U
#EXT-X-DEFINE:NAME="asset",VALUE="episode-1"
#EXT-X-STREAM-INF:BANDWIDTH=1200000
media/index.m3u8
''');
        case '/media/index.m3u8':
          request.response.write(r'''
#EXTM3U
#EXT-X-DEFINE:IMPORT="asset"
#EXT-X-MAP:URI="{$asset}/init.mp4"
#EXT-X-KEY:METHOD=AES-128,URI="../keys/{$asset}.key"
#EXTINF:6,
{$asset}/segment.m4s
#EXT-X-ENDLIST
''');
        case '/keys/episode-1.key':
          request.response.add(keyBytes);
        case '/media/episode-1/init.mp4':
          request.response.add([5, 6, 7, 8]);
        case '/media/episode-1/segment.m4s':
          request.response.add([9, 10, 11, 12]);
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
      request.response.close();
    });

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DownloadRepositoryImpl(database);
    final origin = 'http://${server.address.host}:${server.port}';
    final dio = Dio();
    final service = HttpDownloadService(
      dio: dio,
      repository: repository,
      applicationDocumentsDirectory: () async => tempDirectory,
      hlsManifestLoader: DioHlsManifestLoader(dio: dio),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'loopback',
      source: DownloadSource(
        url: '$origin/master.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS Variable Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = (await repository.getTask(taskId))!;
    expect(task.status, DownloadStatus.completed);
    expect(task.downloadedBytes, 24);
    expect(
      requestedUris,
      [
        '/master.m3u8',
        '/media/index.m3u8',
        '/keys/episode-1.key',
        '/media/episode-1/init.mp4',
        '/media/episode-1/segment.m4s',
      ],
    );
    final localManifest = await File(task.localPath!).readAsString();
    expect(localManifest, isNot(contains(r'{$asset}')));
    expect(localManifest, isNot(contains(origin)));
    expect(localManifest, contains('segments/key-000000.key'));
    expect(localManifest, contains('segments/initialization.mp4'));
    expect(localManifest, contains('segments/segment-000000.m4s'));
  });

  test('missing EXTINF fails before requesting media or publishing assets',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('ani-destiny-hls-http-extinf');
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final requestedPaths = <String>[];
    server.listen((request) {
      requestedPaths.add(request.uri.path);
      switch (request.uri.path) {
        case '/index.m3u8':
          request.response.write('''
#EXTM3U
#EXT-X-TARGETDURATION:6
segment.ts
#EXT-X-ENDLIST
''');
        case '/segment.ts':
          request.response.add([1, 2, 3, 4]);
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
      request.response.close();
    });

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DownloadRepositoryImpl(database);
    final origin = 'http://${server.address.host}:${server.port}';
    final dio = Dio();
    final service = HttpDownloadService(
      dio: dio,
      repository: repository,
      applicationDocumentsDirectory: () async => tempDirectory,
      hlsManifestLoader: DioHlsManifestLoader(dio: dio),
    );

    final taskId = await service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'loopback',
      source: DownloadSource(
        url: '$origin/index.m3u8',
        kind: DownloadKind.hls,
      ),
      title: 'HLS EXTINF Test',
      episodeTitle: 'Episode 1',
    );

    await service.start(taskId);

    final task = (await repository.getTask(taskId))!;
    expect(task.status, DownloadStatus.failed);
    expect(task.failureReason, DownloadFailureReason.invalidManifest);
    expect(task.failureMessage, 'HLS segment duration missing.');
    expect(requestedPaths, ['/index.m3u8']);
    expect(File(task.localPath!).existsSync(), isFalse);
  });
}

class _StaticManifestLoader implements HlsManifestLoader {
  const _StaticManifestLoader(this.manifest);

  final HlsManifest manifest;

  @override
  Future<HlsManifest> load(
    Uri manifestUri, {
    Map<String, String> headers = const {},
    Map<String, String> importedVariables = const {},
  }) async =>
      manifest;
}
