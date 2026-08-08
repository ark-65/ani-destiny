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

  test('rejects media segments without EXTINF duration', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:10
segment-1.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://example.com/media/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'HLS segment duration missing.',
        ),
      ),
    );
  });

  test('rejects non-positive and non-finite EXTINF durations', () {
    for (final duration in ['0', '-1', 'NaN', 'Infinity', 'invalid']) {
      expect(
        () => parser.parse(
          '''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:$duration,
segment-1.ts
#EXT-X-ENDLIST
''',
          uri: Uri.parse('https://example.com/media/index.m3u8'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid HLS segment duration.',
          ),
        ),
        reason: 'duration=$duration',
      );
    }
  });

  test('rejects missing and invalid media target durations', () {
    for (final targetDurationLine in [
      '',
      '#EXT-X-TARGETDURATION:0',
      '#EXT-X-TARGETDURATION:-1',
      '#EXT-X-TARGETDURATION:invalid',
    ]) {
      expect(
        () => parser.parse(
          '''
#EXTM3U
$targetDurationLine
#EXTINF:6,
segment-1.ts
#EXT-X-ENDLIST
''',
          uri: Uri.parse('https://example.com/media/index.m3u8'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            targetDurationLine.isEmpty
                ? 'HLS target duration missing.'
                : 'Invalid HLS target duration.',
          ),
        ),
        reason: 'targetDurationLine=$targetDurationLine',
      );
    }
  });

  test('rejects target duration shorter than rounded segment duration', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXTINF:6.6,
segment-1.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://example.com/media/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'HLS target duration is shorter than a media segment.',
        ),
      ),
    );
  });

  test('preserves the declared HLS protocol version', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:6
#EXTINF:6,
segment-1.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(manifest.protocolVersion, 7);
  });

  test('rejects an invalid HLS protocol version', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-VERSION:0
#EXTINF:6,
segment-1.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
  });

  test('preserves a non-zero media sequence', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
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

  test('preserves a non-zero discontinuity sequence', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-DISCONTINUITY-SEQUENCE:17
#EXTINF:6,
segment.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(manifest.discontinuitySequence, 17);
  });

  test('rejects an invalid discontinuity sequence', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-DISCONTINUITY-SEQUENCE:-1
#EXTINF:6,
segment.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
  });

  test('preserves program date time on its media segment', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-PROGRAM-DATE-TIME:2026-07-29T01:02:03.456+08:00
#EXTINF:6,
segment-1.ts
#EXTINF:6,
segment-2.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(
      manifest.segments.first.programDateTime,
      DateTime.parse('2026-07-29T01:02:03.456+08:00'),
    );
    expect(manifest.segments.last.programDateTime, isNull);
  });

  test('rejects an invalid program date time', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-PROGRAM-DATE-TIME:not-a-date
#EXTINF:6,
segment.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
  });

  test('preserves the suggested HLS start position', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-START:TIME-OFFSET=-12.5,PRECISE=YES
#EXT-X-TARGETDURATION:6
#EXTINF:6,
segment.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(manifest.startPosition?.timeOffsetSeconds, -12.5);
    expect(manifest.startPosition?.precise, isTrue);
  });

  test('rejects invalid or duplicate HLS start positions', () {
    for (final startTags in [
      ['#EXT-X-START:PRECISE=YES'],
      ['#EXT-X-START:TIME-OFFSET=NaN'],
      ['#EXT-X-START:TIME-OFFSET=1,PRECISE=MAYBE'],
      [
        '#EXT-X-START:TIME-OFFSET=1',
        '#EXT-X-START:TIME-OFFSET=2',
      ],
    ]) {
      expect(
        () => parser.parse(
          [
            '#EXTM3U',
            ...startTags,
            '#EXT-X-TARGETDURATION:6',
            '#EXTINF:6,',
            'segment.ts',
            '#EXT-X-ENDLIST',
          ].join('\n'),
          uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
        ),
        throwsFormatException,
      );
    }
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

  for (final bandwidth in ['', 'invalid', '0', '-1']) {
    test('rejects invalid master variant bandwidth "$bandwidth"', () {
      final bandwidthAttribute =
          bandwidth.isEmpty ? '' : 'BANDWIDTH=$bandwidth';
      expect(
        () => parser.parse(
          '''
#EXTM3U
#EXT-X-STREAM-INF:$bandwidthAttribute
video/index.m3u8
''',
          uri: Uri.parse('https://cdn.example.test/master.m3u8'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid HLS variant bandwidth.',
          ),
        ),
      );
    });
  }

  test('preserves alternate audio group on master playlist variants', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-main",NAME="Japanese",DEFAULT=YES,URI="audio/index.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080,CODECS="avc1.640028,mp4a.40.2",AUDIO="audio-main",VIDEO="video-main",SUBTITLES="subs-main"
video/index.m3u8
''',
      uri: Uri.parse('https://cdn.example.test/master.m3u8'),
    );

    expect(manifest.variants.single.audioGroupId, 'audio-main');
    expect(manifest.variants.single.videoGroupId, 'video-main');
    expect(manifest.variants.single.subtitlesGroupId, 'subs-main');
    expect(manifest.variants.single.codecs, 'avc1.640028,mp4a.40.2');
    expect(manifest.renditions, hasLength(1));
    expect(manifest.renditions.single.type, 'AUDIO');
    expect(manifest.renditions.single.groupId, 'audio-main');
    expect(manifest.renditions.single.name, 'Japanese');
    expect(manifest.renditions.single.isDefault, isTrue);
    expect(
      manifest.renditions.single.uri.toString(),
      'https://cdn.example.test/audio/index.m3u8',
    );
  });

  test('rejects an empty alternate video group on a variant', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,VIDEO=""
video/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS variant video group.',
        ),
      ),
    );
  });

  for (final attributes in [
    'TYPE=AUDIO,GROUP-ID="",NAME="Japanese",URI="audio/index.m3u8"',
    'TYPE=AUDIO,GROUP-ID="audio-main",NAME="",URI="audio/index.m3u8"',
  ]) {
    test('rejects empty required audio rendition attributes', () {
      expect(
        () => parser.parse(
          '''
#EXTM3U
#EXT-X-MEDIA:$attributes
#EXT-X-STREAM-INF:BANDWIDTH=2400000,AUDIO="audio-main"
video/index.m3u8
''',
          uri: Uri.parse('https://cdn.example.test/master.m3u8'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid HLS media rendition.',
          ),
        ),
      );
    });
  }

  for (final selectionAttributes in [
    'DEFAULT=MAYBE',
    'AUTOSELECT=1',
    'DEFAULT=YES,AUTOSELECT=NO',
  ]) {
    test('rejects invalid audio selection attributes $selectionAttributes', () {
      expect(
        () => parser.parse(
          '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-main",NAME="Japanese",$selectionAttributes,URI="audio/index.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=2400000,AUDIO="audio-main"
video/index.m3u8
''',
          uri: Uri.parse('https://cdn.example.test/master.m3u8'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid HLS audio selection attributes.',
          ),
        ),
      );
    });
  }

  test('rejects multiple default renditions in one audio group', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-main",NAME="Japanese",DEFAULT=YES,URI="audio/ja.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-main",NAME="English",DEFAULT=YES,URI="audio/en.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=2400000,AUDIO="audio-main"
video/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'HLS audio group contains multiple default renditions.',
        ),
      ),
    );
  });

  test('rejects an empty audio group on a master variant', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,AUDIO=""
video/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS variant audio group.',
        ),
      ),
    );
  });

  test('rejects an empty subtitles group on a master variant', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,SUBTITLES=""
video/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS variant subtitles group.',
        ),
      ),
    );
  });

  test('rejects an incomplete master variant missing media URI', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS variant URI.',
        ),
      ),
    );
  });

  test('rejects consecutive stream-inf records before a media URI is present', () {
    expect(
      () => parser.parse(
        '''
    #EXTM3U
    #EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
    #EXT-X-STREAM-INF:BANDWIDTH=4800000,RESOLUTION=3840x2160
    master/index.m3u8
    ''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS variant URI.',
        ),
      ),
    );
  });

  test('rejects playlists that mix stream variants and media segments', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
1080p/index.m3u8
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/mixed.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS mixed playlist type.',
        ),
      ),
    );
  });

  test('rejects media playlist tags in master playlists', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
1080p/index.m3u8
#EXT-X-KEY:METHOD=AES-128,URI="keys/episode.key",IV=0x0123456789ABCDEF0123456789ABCDEF
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS media tag in master playlist.',
      ),
      ),
    );
  });

  test('rejects unsupported media rendition types', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",URI="subs/index.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
1080p/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS media rendition type.',
        ),
      ),
    );
  });

  test('rejects master playlist media tags missing TYPE', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-MEDIA:GROUP-ID="audio-main",NAME="Japanese",AUTOSELECT=YES
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
1080p/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS media rendition.',
        ),
      ),
    );
  });

  test('rejects session tags in media playlists', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-SESSION-DATA:DATA-ID="session",VALUE="test"
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/video/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS master tag in media playlist.',
        ),
      ),
    );
  });

  test('rejects session key tags in media playlists', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-SESSION-KEY:METHOD=AES-128,URI="https://example.com/keys/session.key",IV=0x00000000000000000000000000000001
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/video/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS master tag in media playlist.',
        ),
      ),
    );
  });

  test('rejects a stream-inf record interrupted by another EXT tag', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
#EXTINF:6,
master/index.m3u8
''',
        uri: Uri.parse('https://cdn.example.test/master.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS variant URI.',
        ),
      ),
    );
  });

  test('rejects master playlist tags in media playlists', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-main",NAME="English",AUTOSELECT=YES
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/video/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid HLS master tag in media playlist.',
        ),
      ),
    );
  });

  test('rejects consecutive segment duration tags before segment URI', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXTINF:6,
#EXTINF:6,
segment/index-001.ts
''',
        uri: Uri.parse('https://cdn.example.test/video/index.m3u8'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'HLS segment URI missing.',
        ),
      ),
    );
  });

  test('substitutes locally defined variables in HLS asset URIs', () {
    final manifest = parser.parse(
      r'''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-DEFINE:NAME="token",VALUE="signed-value"
#EXT-X-DEFINE:NAME="path",VALUE="media/{$token}"
#EXT-X-MAP:URI="{$path}/init.mp4"
#EXT-X-KEY:METHOD=AES-128,URI="keys/{$token}.key"
#EXTINF:6,
{$path}/segment-001.m4s
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    final segment = manifest.segments.single;
    expect(
      segment.uri.toString(),
      'https://cdn.example.test/anime/media/signed-value/segment-001.m4s',
    );
    expect(
      segment.initializationSegment?.uri.toString(),
      'https://cdn.example.test/anime/media/signed-value/init.mp4',
    );
    expect(
      segment.encryptionKey?.uri.toString(),
      'https://cdn.example.test/anime/keys/signed-value.key',
    );
  });

  test('imports an explicitly requested variable from a parent manifest', () {
    final manifest = parser.parse(
      r'''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-DEFINE:IMPORT="token"
#EXTINF:6,
media/{$token}/segment.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      importedVariables: const {'token': 'signed-value'},
    );

    expect(
      manifest.segments.single.uri.toString(),
      'https://cdn.example.test/anime/media/signed-value/segment.ts',
    );
    expect(manifest.variables, {'token': 'signed-value'});
  });

  test('rejects unavailable HLS variables and imports', () {
    expect(
      () => parser.parse(
        r'''
#EXTM3U
#EXTINF:6,
media/{$token}/segment.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-DEFINE:IMPORT="token"
#EXTINF:6,
media/segment.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
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
#EXT-X-TARGETDURATION:6
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

  test('associates the active AES-128 key with an initialization segment', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-KEY:METHOD=AES-128,URI="keys/init.key",IV=0x0123456789ABCDEF0123456789ABCDEF
#EXT-X-MAP:URI="init.mp4"
#EXT-X-KEY:METHOD=NONE
#EXTINF:6,
segment-001.m4s
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    final initializationKey =
        manifest.segments.single.initializationSegment?.encryptionKey;
    expect(
      initializationKey?.uri.toString(),
      'https://cdn.example.test/anime/keys/init.key',
    );
    expect(
      initializationKey?.iv,
      '0x0123456789ABCDEF0123456789ABCDEF',
    );
    expect(manifest.segments.single.encryptionKey, isNull);
  });

  test('associates discontinuity boundaries with following media', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
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

  test('associates gap markers with only the following media segment', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXTINF:6,
segment-001.ts
#EXTINF:6,
#EXT-X-GAP
missing-002.ts
#EXTINF:6,
segment-003.ts
#EXT-X-ENDLIST
''',
      uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
    );

    expect(
      manifest.segments.map((segment) => segment.isGap),
      [false, true, false],
    );
  });

  test('applies an AES-128 key to following media segments', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXT-X-KEY:METHOD=AES-128,URI="keys/episode.key",IV=0x0123456789ABCDEF0123456789ABCDEF,KEYFORMAT="identity"
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
    expect(key?.iv, '0x0123456789ABCDEF0123456789ABCDEF');
    expect(manifest.segments.last.encryptionKey, isNull);
  });

  test('rejects non-identity AES-128 key formats', () {
    expect(
      () => parser.parse(
        '''
#EXTM3U
#EXT-X-KEY:METHOD=AES-128,URI="skd://license",KEYFORMAT="com.apple.streamingkeydelivery"
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
        uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
      ),
      throwsFormatException,
    );
  });

  test('rejects malformed explicit AES-128 IVs', () {
    for (final iv in [
      '0123456789ABCDEF0123456789ABCDEF',
      '0x0123456789ABCDEF',
      '0x0123456789ABCDEG0123456789ABCDEF',
    ]) {
      expect(
        () => parser.parse(
          '''
#EXTM3U
#EXT-X-KEY:METHOD=AES-128,URI="keys/episode.key",IV=$iv
#EXTINF:6,
segment-001.ts
#EXT-X-ENDLIST
''',
          uri: Uri.parse('https://cdn.example.test/anime/index.m3u8'),
        ),
        throwsFormatException,
        reason: 'IV $iv must not produce an offline asset.',
      );
    }
  });

  test('preserves commas inside quoted attribute URIs', () {
    final manifest = parser.parse(
      '''
#EXTM3U
#EXT-X-TARGETDURATION:6
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
#EXT-X-TARGETDURATION:6
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
