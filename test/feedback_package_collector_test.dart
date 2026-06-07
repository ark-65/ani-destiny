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

  test('collector can localize user-facing source labels in feedback output',
      () {
    final now = DateTime.utc(2026, 6, 8, 1, 2, 3);
    final package = FeedbackPackageCollector(
      appName: 'AniDestiny',
      appVersion: '1.0.2',
      platform: 'android',
      currentSourceId: 'sakura',
      sourceHealth: const [
        SourceHealth(
          sourceId: 'sakura',
          status: SourceHealthStatus.healthy,
          failureCount: 0,
        ),
      ],
      sourceDiagnostics: const [
        SourceDiagnostic(
          sourceId: 'sakura',
          operation: 'detail',
          level: SourceDiagnosticLevel.info,
          message: 'loaded',
        ),
      ],
      fallbackEvents: [
        SourceFallbackEvent(
          fromSourceId: 'sakura',
          toSourceId: 'mock',
          operation: 'detail',
          reason: 'fallback',
          timestamp: now,
        ),
      ],
      playbackDiagnostics: const PlaybackDiagnostics(
        sourceId: 'sakura',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../video.m3u8',
        headerKeys: [],
      ),
      danmakuEnabled: true,
      dandanplayAppIdConfigured: false,
      dandanplayAppSecretConfigured: false,
      downloadTasks: const [],
      sourceLabelForId: _sourceLabelForId,
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter().format(package);

    expect(markdown, contains('- Current source: Sakura Anime'));
    expect(markdown, contains('  - Sakura Anime: healthy, failures=0'));
    expect(markdown, contains('detail: Sakura Anime -> Mock Anime Source'));
    expect(markdown, contains('  - Sakura Anime/detail: loaded'));
    expect(markdown, contains('- Source: Sakura Anime'));
    expect(markdown, isNot(contains('- Current source: sakura')));
    expect(markdown, isNot(contains('  - sakura: healthy, failures=0')));
    expect(markdown, isNot(contains('detail: sakura -> mock')));
    expect(markdown, isNot(contains('  - sakura/detail: loaded')));
    expect(markdown, isNot(contains('- Source: sakura')));
  });

  test('collector does not treat canceled downloads as the latest issue', () {
    final now = DateTime.utc(2026, 6, 5, 1, 2, 3);
    final package = FeedbackPackageCollector(
      appName: 'AniDestiny',
      appVersion: '1.0.2',
      platform: 'android',
      currentSourceId: 'sakura',
      sourceHealth: const [],
      sourceDiagnostics: const [],
      fallbackEvents: const [],
      playbackDiagnostics: null,
      danmakuEnabled: false,
      dandanplayAppIdConfigured: false,
      dandanplayAppSecretConfigured: false,
      downloadTasks: [
        DownloadTask(
          id: 'task-canceled',
          animeId: 'anime-1',
          episodeId: 'episode-1',
          sourceId: 'sakura',
          title: 'Anime',
          episodeTitle: 'Episode 1',
          url: 'https://cdn.example.test/video.mp4',
          kind: DownloadKind.directFile,
          status: DownloadStatus.canceled,
          failureReason: DownloadFailureReason.canceled,
          failureMessage: 'Download canceled.',
          progress: 0.25,
          downloadedBytes: 256,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter().format(package);

    expect(markdown, contains('- canceled: 1'));
    expect(markdown, contains('- Latest issue: none'));
    expect(markdown, isNot(contains('reason=canceled')));
    expect(markdown, isNot(contains('Download canceled.')));
  });
}

String _sourceLabelForId(String sourceId) {
  return switch (sourceId) {
    'mock' => 'Mock Anime Source',
    'sakura' => 'Sakura Anime',
    _ => sourceId,
  };
}
