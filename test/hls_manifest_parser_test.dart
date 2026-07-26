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
    expect(manifest.mediaSequence, 0);
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

  test('preserves a non-zero media sequence', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-MEDIA-SEQUENCE:451
#EXT-X-KEY:METHOD=AES-128,URI="keys/episode.key"
#EXTINF:6,
segment-451.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(manifest.mediaSequence, 451);
    expect(manifest.segments.single.encryptionKey?.iv, isNull);
  });

  test('rejects an invalid media sequence', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-MEDIA-SEQUENCE:-1
#EXTINF:6,
segment.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
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

  test('parses a relative initialization segment', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-MAP:URI="init/init.mp4"
#EXTINF:6,
segment-001.m4s
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(
      manifest.initializationSegment?.uri.toString(),
      'https://cdn.example.test/anime/init/init.mp4',
    );
    expect(
      manifest.segments.single.initializationSegment?.uri.toString(),
      'https://cdn.example.test/anime/init/init.mp4',
    );
  });

  test('associates changing initialization segments with following media', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-MAP:URI="init-1.mp4"
#EXTINF:6,
segment-001.m4s
#EXT-X-MAP:URI="init-2.mp4"
#EXTINF:6,
segment-002.m4s
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(
      manifest.segments
          .map((segment) => segment.initializationSegment?.uri.toString()),
      [
        'https://cdn.example.test/anime/init-1.mp4',
        'https://cdn.example.test/anime/init-2.mp4',
      ],
    );
  });

  test('associates discontinuity boundaries with following media', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXTINF:6,
segment-001.ts
#EXT-X-DISCONTINUITY
#EXTINF:6,
segment-002.ts
#EXTINF:6,
segment-003.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(
      manifest.segments.map((segment) => segment.hasDiscontinuity),
      [false, true, false],
    );
  });

  test('applies an AES-128 key to following media segments', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-KEY:METHOD=AES-128,URI="keys/episode.key",IV=0x0123456789ABCDEF
#EXTINF:6,
segment-001.ts
#EXT-X-KEY:METHOD=NONE
#EXTINF:6,
segment-002.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    final key = manifest.segments.first.encryptionKey;
    expect(key?.method, 'AES-128');
    expect(
      key?.uri.toString(),
      'https://cdn.example.test/anime/keys/episode.key',
    );
    expect(key?.iv, '0x0123456789ABCDEF');
    expect(manifest.segments.last.encryptionKey, isNull);
  });

  test('preserves commas inside quoted attribute URIs', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-MAP:URI="init.mp4?token=alpha,beta"
#EXT-X-KEY:METHOD=AES-128,URI="keys/episode.key?token=gamma,delta"
#EXTINF:6,
segment-001.m4s
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(
      manifest.segments.single.initializationSegment?.uri.toString(),
      'https://cdn.example.test/anime/init.mp4?token=alpha,beta',
    );
    expect(
      manifest.segments.single.encryptionKey?.uri.toString(),
      'https://cdn.example.test/anime/keys/episode.key?token=gamma,delta',
    );
  });

  test('rejects an unterminated quoted attribute', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-MAP:URI="init.mp4?token=alpha,beta
#EXTINF:6,
segment-001.m4s
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
  });

  test('rejects unsupported encryption methods', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-KEY:METHOD=SAMPLE-AES,URI="keys/episode.key"
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
  });

  test('parses explicit and implicit media and initialization byte ranges', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-MAP:URI="media.mp4",BYTERANGE="4@0"
#EXTINF:6,
#EXT-X-BYTERANGE:5@4
media.mp4
#EXTINF:6,
#EXT-X-BYTERANGE:3
media.mp4
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(manifest.segments, hasLength(2));
    expect(manifest.segments.first.byteRange?.offset, 4);
    expect(manifest.segments.first.byteRange?.length, 5);
    expect(manifest.segments.last.byteRange?.offset, 9);
    expect(manifest.segments.last.byteRange?.length, 3);
    expect(manifest.segments.first.initializationSegment?.byteRange?.offset, 0);
    expect(manifest.segments.first.initializationSegment?.byteRange?.length, 4);
  });

  test('rejects implicit byte range after a different resource', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXTINF:6,
#EXT-X-BYTERANGE:4@0
first.ts
#EXTINF:6,
#EXT-X-BYTERANGE:4
second.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('same resource'),
        ),
      ),
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
