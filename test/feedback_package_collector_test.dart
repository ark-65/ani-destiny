import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/diagnostics/feedback_package_collector.dart';
import 'package:ani_destiny/core/diagnostics/feedback_package_formatter.dart';
import 'package:ani_destiny/core/diagnostics/playback_diagnostic_time_formatter.dart';
import 'package:ani_destiny/features/download/download_task_cleanup_state.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/player/domain/services/playback_diagnostics.dart';
import 'package:ani_destiny/features/source/domain/entities/source_diagnostic.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_event.dart';
import 'package:ani_destiny/features/source/domain/entities/source_health.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collector summarizes diagnostics without full download URLs', () {
    final now = DateTime.utc(2026, 5, 30, 2, 3, 4);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.1',
      platform: 'Android',
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
      playbackDiagnostics: PlaybackDiagnostics(
        capturedAt: now,
        animeTitle: 'Anime',
        episodeTitle: 'Episode 1',
        selectedAppSourceId: 'sakura',
        sourceId: 'sakura',
        requestedSourceId: 'mock',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../video.m3u8',
        headerKeys: ['Referer', 'User-Agent'],
        state: PlaybackDiagnosticState.error,
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

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);
    final lower = markdown.toLowerCase();

    expect(markdown, contains('- Total tasks: 1'));
    expect(
      markdown,
      contains('- Selected app source: sakura'),
    );
    expect(markdown, contains('- Active playback source: sakura'));
    expect(markdown, contains('- State: Failed'));
    expect(
      markdown,
      contains(
        '- Captured at: ${formatPlaybackDiagnosticCapturedAt(now, localeName: l10n.locale.toLanguageTag(), includeExactIso: true)}',
      ),
    );
    expect(markdown, contains('- Selected playback source: mock'));
    expect(
      markdown,
      contains(
        '- Playback source status: mock is temporarily unavailable. AniDestiny is playing from sakura instead.',
      ),
    );
    expect(markdown, contains('- Request header names: Referer'));
    expect(markdown, contains('- Failed: 1'));
    expect(markdown, contains('Reason: Network error'));
    expect(markdown, contains('https://example.test/.../detail.html'));
    expect(markdown, isNot(contains('https://cdn.example.test/video.mp4')));
    expect(lower, isNot(contains('token')));
    expect(lower, isNot(contains('secret')));
    expect(
      markdown.indexOf('- Active playback source: sakura'),
      lessThan(markdown.indexOf('- State: Failed')),
    );
    expect(
      markdown.indexOf('- State: Failed'),
      lessThan(
        markdown.indexOf(
          '- Captured at: ${formatPlaybackDiagnosticCapturedAt(now, localeName: l10n.locale.toLanguageTag(), includeExactIso: true)}',
        ),
      ),
    );
  });

  test('collector localizes copied feedback summary for Chinese support copy',
      () {
    final now = DateTime.utc(2026, 6, 8, 1, 2, 3);
    const l10n = AppLocalizations(Locale('zh'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.2',
      platform: 'Android',
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
      playbackDiagnostics: PlaybackDiagnostics(
        capturedAt: now,
        animeTitle: 'Anime',
        episodeTitle: 'Episode 1',
        selectedAppSourceId: 'sakura',
        sourceId: 'sakura',
        requestedSourceId: null,
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../video.m3u8',
        headerKeys: [],
        state: PlaybackDiagnosticState.ready,
      ),
      danmakuEnabled: true,
      dandanplayAppIdConfigured: false,
      dandanplayAppSecretConfigured: false,
      downloadTasks: const [],
      sourceLabelForId: _sourceLabelForId,
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);

    expect(markdown, contains('# AniDestiny 反馈摘要'));
    expect(markdown, contains('- 应用所选数据源: Sakura Anime'));
    expect(markdown, contains('Sakura Anime · 正常'));
    expect(markdown, contains('失败次数: 0'));
    expect(markdown, contains('详情: Sakura Anime -> Mock 动漫数据源'));
    expect(
      markdown,
      contains(
        '- 采集时间: ${formatPlaybackDiagnosticCapturedAt(now, localeName: l10n.locale.toLanguageTag(), includeExactIso: true)}',
      ),
    );
    expect(markdown, contains('- 线路: Line 1'));
    expect(markdown, contains('- 状态: 就绪'));
    expect(markdown, isNot(contains('请求头名称')));
    expect(markdown, contains('- 启用: 是'));
    expect(markdown, contains('Dandanplay App ID 已配置: 否'));
    expect(markdown, isNot(contains('- 当前数据源: sakura')));
    expect(markdown, isNot(contains('detail: sakura -> mock')));
    expect(markdown, isNot(contains('Enabled: true')));
    expect(markdown, isNot(contains('healthy')));
  });

  test('collector does not treat canceled downloads as the latest issue', () {
    final now = DateTime.utc(2026, 6, 5, 1, 2, 3);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.2',
      platform: 'Android',
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

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);

    expect(markdown, contains('- Discarded: 1'));
    expect(markdown, contains('- Latest issue: None'));
    expect(markdown, isNot(contains('Reason: Discarded')));
    expect(markdown, isNot(contains('Download canceled.')));
  });

  test('collector uses stopped download wording in support summaries', () {
    final now = DateTime.utc(2026, 6, 25, 15, 0, 0);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.4',
      platform: 'Windows',
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
          id: 'task-stopped',
          animeId: 'anime-1',
          episodeId: 'episode-1',
          sourceId: 'sakura',
          title: 'Anime',
          episodeTitle: 'Episode 1',
          url: 'https://cdn.example.test/video.mp4',
          kind: DownloadKind.directFile,
          status: DownloadStatus.paused,
          failureReason: DownloadFailureReason.none,
          progress: 0.25,
          downloadedBytes: 256,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);

    expect(markdown, contains('- Stopped: 1'));
    expect(markdown, isNot(contains('- Paused: 1')));
    expect(markdown, contains('- Latest issue: None'));
  });

  test('collector keeps manual-cleanup download wording aligned with the page',
      () {
    const leftoverPath = '/tmp/manual-cleanup-partial.mp4';
    debugSetDownloadCleanupPathExists(
      (localPath) => localPath == leftoverPath,
    );
    addTearDown(() => debugSetDownloadCleanupPathExists(null));

    final now = DateTime.utc(2026, 6, 27, 1, 0, 0);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.4',
      platform: 'Windows',
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
          id: 'task-cleanup',
          animeId: 'anime-1',
          episodeId: 'episode-1',
          sourceId: 'sakura',
          title: 'Anime',
          episodeTitle: 'Episode 1',
          url: 'https://cdn.example.test/video.mp4',
          kind: DownloadKind.directFile,
          status: DownloadStatus.canceled,
          failureReason: DownloadFailureReason.canceled,
          progress: 0,
          downloadedBytes: 0,
          localPath: leftoverPath,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);

    expect(markdown, contains('- Needs cleanup: 1'));
    expect(markdown, contains('- Discarded: 0'));
    expect(
      markdown,
      contains('- Latest issue: Needs cleanup · Reason: Discarded'),
    );
    expect(markdown, contains('Local path: /tmp/manual-cleanup-partial.mp4'));
    expect(
      markdown,
      contains(
        'Message: Delete the leftover partial file from your device first. Then return to Downloads and tap Check again on that task.',
      ),
    );
  });

  test(
      'collector points multi-task manual cleanup summaries at the batch recheck action',
      () {
    const firstLeftoverPath = '/tmp/manual-cleanup-partial-1.mp4';
    const secondLeftoverPath = '/tmp/manual-cleanup-partial-2.mp4';
    debugSetDownloadCleanupPathExists(
      (localPath) =>
          localPath == firstLeftoverPath || localPath == secondLeftoverPath,
    );
    addTearDown(() => debugSetDownloadCleanupPathExists(null));

    final now = DateTime.utc(2026, 6, 30, 1, 0, 0);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.4',
      platform: 'Windows',
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
          id: 'task-cleanup-1',
          animeId: 'anime-1',
          episodeId: 'episode-1',
          sourceId: 'sakura',
          title: 'Anime',
          episodeTitle: 'Episode 1',
          url: 'https://cdn.example.test/video-1.mp4',
          kind: DownloadKind.directFile,
          status: DownloadStatus.canceled,
          failureReason: DownloadFailureReason.canceled,
          progress: 0,
          downloadedBytes: 0,
          localPath: firstLeftoverPath,
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 1)),
        ),
        DownloadTask(
          id: 'task-cleanup-2',
          animeId: 'anime-2',
          episodeId: 'episode-2',
          sourceId: 'sakura',
          title: 'Anime 2',
          episodeTitle: 'Episode 2',
          url: 'https://cdn.example.test/video-2.mp4',
          kind: DownloadKind.directFile,
          status: DownloadStatus.canceled,
          failureReason: DownloadFailureReason.canceled,
          progress: 0,
          downloadedBytes: 0,
          localPath: secondLeftoverPath,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);

    expect(markdown, contains('- Needs cleanup: 2'));
    expect(markdown, contains('Local path: /tmp/manual-cleanup-partial-1.mp4'));
    expect(
      markdown,
      contains(
        'Message: Delete the leftover partial file from your device first. Then return to Downloads and use "Check 2 leftover files again", or tap Check again on that task.',
      ),
    );
  });

  test(
      'collector adds selected app source to playback summary only for divergent playback context',
      () {
    final now = DateTime.utc(2026, 6, 8, 1, 2, 3);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.2',
      platform: 'Android',
      currentSourceId: 'remote-proxy',
      sourceHealth: const [],
      sourceDiagnostics: const [],
      fallbackEvents: const [],
      playbackDiagnostics: PlaybackDiagnostics(
        capturedAt: now,
        animeTitle: 'Anime',
        episodeTitle: 'Episode 1',
        selectedAppSourceId: 'remote-proxy',
        sourceId: 'sakura',
        requestedSourceId: 'mock',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../video.m3u8',
        headerKeys: const [],
        state: PlaybackDiagnosticState.playing,
      ),
      danmakuEnabled: true,
      dandanplayAppIdConfigured: false,
      dandanplayAppSecretConfigured: false,
      downloadTasks: const [],
      sourceLabelForId: (sourceId) {
        return switch (sourceId) {
          'remote-proxy' => 'Remote Source Proxy',
          _ => _sourceLabelForId(sourceId),
        };
      },
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);
    final selectedAppSourceMatches =
        RegExp(r'^- Selected app source: Remote Source Proxy$', multiLine: true)
            .allMatches(markdown)
            .length;

    expect(selectedAppSourceMatches, 1);
    expect(
      markdown,
      contains(
        '- Selected app source at playback: Remote Source Proxy',
      ),
    );
    expect(markdown, contains('- Selected playback source: Mock Anime Source'));
    expect(markdown, contains('- Active playback source: Sakura Anime'));
  });

  test(
      'collector keeps the captured app source in playback summary after the live source changes',
      () {
    final now = DateTime.utc(2026, 6, 8, 1, 2, 3);
    const l10n = AppLocalizations(Locale('en'));
    final package = FeedbackPackageCollector(
      l10n: l10n,
      appName: 'AniDestiny',
      appVersion: '1.0.2',
      platform: 'Android',
      currentSourceId: 'sakura',
      sourceHealth: const [],
      sourceDiagnostics: const [],
      fallbackEvents: const [],
      playbackDiagnostics: PlaybackDiagnostics(
        capturedAt: now,
        animeTitle: 'Anime',
        episodeTitle: 'Episode 1',
        selectedAppSourceId: 'remote-proxy',
        sourceId: 'sakura',
        requestedSourceId: 'mock',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../video.m3u8',
        headerKeys: const [],
        state: PlaybackDiagnosticState.playing,
      ),
      danmakuEnabled: true,
      dandanplayAppIdConfigured: false,
      dandanplayAppSecretConfigured: false,
      downloadTasks: const [],
      sourceLabelForId: (sourceId) {
        return switch (sourceId) {
          'remote-proxy' => 'Remote Source Proxy',
          _ => _sourceLabelForId(sourceId),
        };
      },
    ).collect(generatedAt: now);

    final markdown = const FeedbackPackageFormatter(l10n: l10n).format(package);

    expect(markdown, contains('- Selected app source: Sakura Anime'));
    expect(
      markdown,
      contains(
        '## Playback\n- Anime: Anime\n- Episode: Episode 1\n- Selected app source at playback: Remote Source Proxy\n- Selected playback source: Mock Anime Source\n- Active playback source: Sakura Anime\n- Playback source status: Mock Anime Source is temporarily unavailable. AniDestiny is playing from Sakura Anime instead.\n- Line: Line 1\n- State: Playing\n- Captured at: ${formatPlaybackDiagnosticCapturedAt(now, localeName: l10n.locale.toLanguageTag(), includeExactIso: true)}',
      ),
    );
    expect(
      markdown,
      contains('- Selected app source at playback: Remote Source Proxy'),
    );
  });
}

String _sourceLabelForId(String sourceId) {
  return switch (sourceId) {
    'mock' => 'Mock Anime Source',
    'sakura' => 'Sakura Anime',
    _ => sourceId,
  };
}
