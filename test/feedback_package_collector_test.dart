import 'package:ani_destiny/core/diagnostics/feedback_package_collector.dart';
import 'package:ani_destiny/core/diagnostics/feedback_package_formatter.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/player/domain/services/playback_diagnostics.dart';
import 'package:ani_destiny/features/source/domain/entities/source_diagnostic.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_event.dart';
import 'package:ani_destiny/features/source/domain/entities/source_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collector summarizes diagnostics without full download URLs', () {
    final now = DateTime.utc(2026, 5, 30, 2, 3, 4);
    final package = FeedbackPackageCollector(
      appName: 'AniDestiny',
      appVersion: '1.0.1',
      platform: 'android',
      currentSourceId: 'sakura',
      sourceHealth: [
        const SourceHealth(
          sourceId: 'sakura',
          status: SourceHealthStatus.degraded,
          failureCount: 2,
          lastErrorMessage: 'https://example.test/detail?id=1&token=secret',
        ),
      ],
      sourceDiagnostics: const [
        SourceDiagnostic(
          sourceId: 'sakura',
          operation: 'detail',
          level: SourceDiagnosticLevel.error,
          message: 'parser failed token=secret',
          url: 'https://example.test/a/detail.html?token=secret',
          statusCode: 200,
        ),
      ],
      fallbackEvents: [
        SourceFallbackEvent(
          fromSourceId: 'sakura',
          toSourceId: 'mock',
          operation: 'detail',
          reason: 'source failed token=secret',
          timestamp: now,
        ),
      ],
      playbackDiagnostics: const PlaybackDiagnostics(
        sourceId: 'sakura',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../video.m3u8',
        headerKeys: ['Referer', 'User-Agent'],
      ),
      danmakuEnabled: true,
      dandanplayAppIdConfigured: true,
      dandanplayAppSecretConfigured: false,
      downloadTasks: [
        DownloadTask(
          id: 'task-1',
          animeId: 'anime-1',
          episodeId: 'episode-1',
          sourceId: 'sakura',
          title: 'Anime',
          episodeTitle: 'Episode',
          url: 'https://cdn.example.test/video.mp4?token=secret',
          kind: DownloadKind.directFile,
          status: DownloadStatus.failed,
          failureReason: DownloadFailureReason.networkError,
          failureMessage: 'GET failed token=secret',
          progress: 0.5,
          downloadedBytes: 1024,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter().format(package);
    final lower = markdown.toLowerCase();

    expect(markdown, contains('- Total tasks: 1'));
    expect(markdown, contains('- failed: 1'));
    expect(markdown, contains('networkError'));
    expect(markdown, contains('https://example.test/.../detail.html'));
    expect(markdown, isNot(contains('https://cdn.example.test/video.mp4')));
    expect(lower, isNot(contains('token')));
    expect(lower, isNot(contains('secret')));
  });
}
