import 'package:ani_destiny/core/diagnostics/diagnostic_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizeUrl removes query and keeps safe URL shape', () {
    final value = sanitizeUrl(
      'https://cdn.example.test/path/to/video.m3u8?token=secret&x=1',
    );

    expect(value, 'https://cdn.example.test/.../video.m3u8');
    expect(value, isNot(contains('token')));
    expect(value, isNot(contains('secret')));
  });

  test('sanitizeHeaders keeps keys and hides values', () {
    final value = sanitizeHeaders({
      'Authorization': 'Bearer secret-token',
      'Cookie': 'sid=secret',
      'User-Agent': 'AniDestinyTest',
    });

    expect(value.keys, containsAll(['Authorization', 'Cookie', 'User-Agent']));
    expect(value.values.toSet(), {'[hidden]'});
    expect(value.toString(), isNot(contains('secret-token')));
  });

  test('sanitizePath hides local usernames', () {
    expect(
      sanitizePath('/Users/ark/Downloads/AniDestiny/video.mp4'),
      '/Users/<user>/Downloads/AniDestiny/video.mp4',
    );
    expect(
      sanitizePath(r'C:\Users\ark\Downloads\AniDestiny\video.mp4'),
      r'C:\Users\<user>\Downloads\AniDestiny\video.mp4',
    );
  });

  test('sanitizeError hides sensitive values and compresses messages', () {
    final value = sanitizeError(
      'Authorization: Bearer abc123 token=secret '
      'https://example.test/a/b.m3u8?cookie=session '
      '/Users/ark/Downloads/file.mp4',
    );

    expect(value, contains('[sensitive]=[hidden]'));
    expect(value, contains('https://example.test/.../b.m3u8'));
    expect(value, contains('/Users/<user>/Downloads/file.mp4'));
    expect(value, isNot(contains('abc123')));
    expect(value, isNot(contains('secret')));
    expect(value, isNot(contains('session')));
  });

  test('sanitizeError hides file URI paths', () {
    final value = sanitizeError(
      'Failed opening file:///C:/Users/ark/Downloads/offline/index.m3u8 '
      'with /tmp/ani-destiny-offline/manifest.m3u8',
    );

    expect(value, contains('file:[hidden]'));
    expect(value, contains('[path:[hidden]]'));
    expect(
      value,
      isNot(contains('/tmp/ani-destiny-offline/manifest.m3u8')),
    );
  });

  test('sanitizeError hides Windows drive paths with forward slashes', () {
    final value = sanitizeError(
      'Cannot open C:/Users/ark/Downloads/ani-destiny-offline/index.m3u8',
    );

    expect(value, contains('C:/Users/<user>/Downloads/ani-destiny-offline/index.m3u8'));
    expect(value, isNot(contains('C:/Users/ark/Downloads/ani-destiny-offline/index.m3u8')));
  });

  test('sanitizeError hides /private and /var absolute paths', () {
    final value = sanitizeError(
      'open /private/var/folders/xx/yy/cache/manifest.m3u8 and /var/tmp/session.tmp failed',
    );

    expect(value, contains('[path:[hidden]]'));
    expect(value, isNot(contains('/private/var/folders/xx/yy/cache/manifest.m3u8')));
    expect(value, isNot(contains('/var/tmp/session.tmp')));
  });

  test('sanitizeError omits HTML documents', () {
    expect(
      sanitizeError('<html><body>token=secret</body></html>'),
      'HTML document omitted',
    );
  });

  test('sanitizeSourceFallbackNoticeReason extracts reason with equal separator', () {
    expect(
      sanitizeSourceFallbackNoticeReason(
        'Fallback reason = DNS timeout while reading metadata.',
      ),
      'DNS timeout while reading metadata.',
    );

    expect(
      sanitizeSourceFallbackNoticeReason(
        'Fallback reason＝DNS timeout while reading metadata.',
      ),
      'DNS timeout while reading metadata.',
    );
  });

  test('sanitizeSourceFallbackNoticeReason strips common exception prefixes', () {
    expect(
      sanitizeSourceFallbackNoticeReason(
        'Exception: DNS timeout while reading metadata.',
      ),
      'DNS timeout while reading metadata.',
    );

    expect(
      sanitizeSourceFallbackNoticeReason(
        'AppException: [source_fallback_exhausted] DNS timeout while reading metadata.',
      ),
      'DNS timeout while reading metadata.',
    );

    expect(
      sanitizeSourceFallbackNoticeReason(
        'Source fallback used -> Exception: DNS timeout while reading metadata.',
      ),
      'DNS timeout while reading metadata.',
    );
  });
}
