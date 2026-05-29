import 'package:ani_destiny/features/download/data/services/hls_manifest_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = HlsManifestParser();

  test('parses simple media playlist segments', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:9.5,
segment-001.ts
#EXTINF:8.0,Opening
segment-002.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(manifest.isMediaPlaylist, isTrue);
    expect(manifest.isMasterPlaylist, isFalse);
    expect(manifest.isLive, isFalse);
    expect(manifest.targetDuration, const Duration(seconds: 10));
    expect(manifest.segments, hasLength(2));
    expect(
      manifest.segments.first.uri.toString(),
      'https://cdn.example.test/anime/segment-001.ts',
    );
    expect(
      manifest.segments.last.duration,
      const Duration(seconds: 8),
    );
    expect(manifest.segments.last.title, 'Opening');
  });

  test('recognizes master playlist variants', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=1280x720
720p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
1080p/index.m3u8
''',
      uri: Uri.parse('https://cdn.example.test/master.m3u8'),
    );

    expect(manifest.isMasterPlaylist, isTrue);
    expect(manifest.variants, hasLength(2));
    expect(manifest.variants.first.bandwidth, 1200000);
    expect(manifest.variants.first.resolution, '1280x720');
    expect(
      manifest.variants.last.uri.toString(),
      'https://cdn.example.test/1080p/index.m3u8',
    );
  });

  test('throws for invalid manifests', () {
    expect(
      () => parser.parse(
        '#EXT-X-TARGETDURATION:10',
        uri: Uri.parse('https://cdn.example.test/broken.m3u8'),
      ),
      throwsFormatException,
    );
  });
}
