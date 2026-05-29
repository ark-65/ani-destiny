import 'package:ani_destiny/core/diagnostics/feedback_package.dart';
import 'package:ani_destiny/core/diagnostics/feedback_package_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedback markdown includes expected sections', () {
    final markdown = const FeedbackPackageFormatter().format(
      FeedbackPackage(
        generatedAt: DateTime.utc(2026, 5, 30, 1, 2, 3),
        appName: 'AniDestiny',
        appVersion: '1.0.1',
        platform: 'android',
        sourceSummary: '- Current source: sakura',
        playbackSummary: '- URL type: m3u8',
        danmakuSummary: '- Enabled: true',
        downloadSummary: '- Total tasks: 0',
      ),
    );

    expect(markdown, contains('# AniDestiny Feedback Package'));
    expect(markdown, contains('## App'));
    expect(markdown, contains('## Platform'));
    expect(markdown, contains('## Source'));
    expect(markdown, contains('## Playback'));
    expect(markdown, contains('## Danmaku'));
    expect(markdown, contains('## Downloads'));
    expect(markdown, contains('## Notes'));
  });

  test('feedback markdown sanitizes sensitive text defensively', () {
    final markdown = const FeedbackPackageFormatter().format(
      FeedbackPackage(
        generatedAt: DateTime.utc(2026, 5, 30),
        appName: 'AniDestiny',
        appVersion: '1.0.1',
        platform: 'android token=secret',
        sourceSummary: 'url=https://example.test/a/video.mp4?token=secret',
        playbackSummary: 'cookie=session secret=value',
        danmakuSummary: 'DANDANPLAY_APP_SECRET=value',
        downloadSummary: 'Authorization: Bearer abc123',
      ),
    );
    final lower = markdown.toLowerCase();

    expect(lower, isNot(contains('token')));
    expect(lower, isNot(contains('cookie')));
    expect(lower, isNot(contains('secret')));
    expect(markdown, isNot(contains('abc123')));
    expect(markdown, contains('[hidden]'));
  });
}
