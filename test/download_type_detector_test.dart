import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/services/download_type_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectDownloadKind', () {
    test('detects m3u8 URLs as HLS', () {
      expect(
        detectDownloadKind('https://cdn.example.test/anime/index.m3u8'),
        DownloadKind.hls,
      );
    });

    test('detects HLS content type as HLS', () {
      expect(
        detectDownloadKind(
          'https://cdn.example.test/stream',
          contentType: 'application/vnd.apple.mpegurl',
        ),
        DownloadKind.hls,
      );
    });

    test('detects magnet URLs as BT placeholder tasks', () {
      expect(
        detectDownloadKind('magnet:?xt=urn:btih:abc123'),
        DownloadKind.bt,
      );
    });

    test('detects direct media files', () {
      expect(
        detectDownloadKind('https://cdn.example.test/movie.mp4?token=1'),
        DownloadKind.directFile,
      );
    });

    test('returns unknown for unsupported URL shapes', () {
      expect(
        detectDownloadKind('https://cdn.example.test/watch?id=1'),
        DownloadKind.unknown,
      );
    });
  });
}
