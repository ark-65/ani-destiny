import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search empty copy no longer points users to the mock source', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(l10n.searchEmpty.toLowerCase(), isNot(contains('mock')));
    }
  });

  test('source settings copy no longer recommends the mock source', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(
        l10n.sourceSettingsSubtitle.toLowerCase(),
        isNot(contains('mock')),
      );
      expect(l10n.sourceV1Note.toLowerCase(), isNot(contains('mock')));
      expect(
        l10n.sourceDisplayDescription('sakura', 'ignored').toLowerCase(),
        isNot(contains('experimental')),
      );
      expect(
        l10n.sourceStatusValue.toLowerCase(),
        isNot(contains('experimental')),
      );
    }
  });

  test('player placeholder copy no longer exposes mock wording', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(l10n.playerReadyHint.toLowerCase(), isNot(contains('mock')));
    }
  });

  test('external player copy no longer uses placeholder text', () {
    for (final locale in const [
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]) {
      final l10n = AppLocalizations(locale);
      expect(l10n.externalPlayer.toLowerCase(), isNot(contains('placeholder')));
      expect(
        l10n.externalPlayerUnavailable('Sakura Anime').toLowerCase(),
        isNot(contains('not implemented')),
      );
      expect(
        l10n.externalPlayerHeadersUnsupported('Sakura Anime').toLowerCase(),
        isNot(contains('request headers')),
      );
      expect(
        l10n.externalPlayerHeadersUnsupported('Sakura Anime'),
        isNot(contains('请求头')),
      );
      expect(
        l10n.externalPlayerHeadersUnsupported('Sakura Anime'),
        isNot(contains('ヘッダー')),
      );
      expect(
        l10n.externalPlayerHeadersUnsupported('Sakura Anime'),
        contains('Sakura Anime'),
      );
      expect(
        l10n.externalPlayerOpened('Sakura Anime').toLowerCase(),
        isNot(contains('success')),
      );
      expect(
        l10n.externalPlayerOpened('Sakura Anime').toLowerCase(),
        isNot(contains('placeholder')),
      );
    }
  });

  test('external player failure copy explains staying in AniDestiny', () {
    const zh = AppLocalizations(Locale('zh'));
    final zhNotice = zh.externalPlayerUnavailable('Sakura Anime');
    expect(zhNotice, contains('Sakura Anime'));
    expect(zhNotice, contains('AniDestiny'));
    expect(zhNotice, contains('留在'));

    const en = AppLocalizations(Locale('en'));
    final enNotice = en.externalPlayerUnavailable('Sakura Anime');
    expect(enNotice, contains('Sakura Anime'));
    expect(enNotice, contains('Staying in AniDestiny'));
    expect(
      enNotice.toLowerCase(),
      isNot(contains('later')),
    );

    const ja = AppLocalizations(Locale('ja'));
    final jaNotice = ja.externalPlayerUnavailable('Sakura Anime');
    expect(jaNotice, contains('Sakura Anime'));
    expect(jaNotice, contains('AniDestiny'));
    expect(jaNotice, contains('残ります'));
  });

  test('external player success copy names the active source', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.externalPlayerOpened('Sakura Anime'), contains('Sakura Anime'));

    const en = AppLocalizations(Locale('en'));
    final enNotice = en.externalPlayerOpened('Sakura Anime');
    expect(enNotice, contains('Sakura Anime'));
    expect(enNotice.toLowerCase(), contains('opened'));

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.externalPlayerOpened('Sakura Anime'), contains('Sakura Anime'));
  });

  test('next episode recovery copy explains staying on the current episode',
      () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.nextEpisodeStayedOnCurrent, contains('当前这一集'));
    expect(zh.nextEpisodeStayedOnCurrent, isNot(contains('数据源')));

    const en = AppLocalizations(Locale('en'));
    expect(en.nextEpisodeStayedOnCurrent, contains('current one'));
    expect(
      en.nextEpisodeStayedOnCurrent.toLowerCase(),
      isNot(contains('source')),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.nextEpisodeStayedOnCurrent, contains('現在のエピソード'));
    expect(ja.nextEpisodeStayedOnCurrent, isNot(contains('ソース')));
  });

  test('latest episode label stays short and localized', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.latestEpisode, '最后一集');

    const en = AppLocalizations(Locale('en'));
    expect(en.latestEpisode, 'Latest episode');

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.latestEpisode, '最新話');
  });

  test('player fallback copy stays calm and avoids fallback jargon', () {
    const zh = AppLocalizations(Locale('zh'));
    final zhNotice = zh.sourceFallbackPlayerNotice(
      'Mock Anime Source',
      'Sakura Anime',
    );
    expect(zhNotice, contains('Mock Anime Source'));
    expect(zhNotice, contains('Sakura Anime'));
    expect(zhNotice, isNot(contains('备用播放数据')));

    const en = AppLocalizations(Locale('en'));
    final enNotice = en.sourceFallbackPlayerNotice(
      'Mock Anime Source',
      'Sakura Anime',
    );
    expect(enNotice, contains('AniDestiny'));
    expect(enNotice, contains('Sakura Anime'));
    expect(enNotice.toLowerCase(), isNot(contains('fallback data')));

    const ja = AppLocalizations(Locale('ja'));
    final jaNotice = ja.sourceFallbackPlayerNotice(
      'Mock Anime Source',
      'Sakura Anime',
    );
    expect(jaNotice, contains('Mock Anime Source'));
    expect(jaNotice, contains('Sakura Anime'));
    expect(jaNotice, isNot(contains('代替データ')));
  });

  test('generic fallback copy stays calm and avoids fallback jargon', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.sourceFallbackNotice, contains('AniDestiny'));
    expect(zh.sourceFallbackNotice, contains('其他数据源'));
    expect(zh.sourceFallbackNotice, isNot(contains('备用数据')));

    const en = AppLocalizations(Locale('en'));
    expect(en.sourceFallbackNotice, contains('AniDestiny'));
    expect(en.sourceFallbackNotice, contains('another source'));
    expect(
      en.sourceFallbackNotice.toLowerCase(),
      isNot(contains('fallback data')),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.sourceFallbackNotice, contains('AniDestiny'));
    expect(ja.sourceFallbackNotice, contains('別のソース'));
    expect(ja.sourceFallbackNotice, isNot(contains('代替データ')));
  });

  test('busy player exit copy matches the active handoff', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.playerExitBusyNextEpisode, contains('下一集'));
    expect(zh.playerExitBusyExternalPlayer, contains('外部播放器'));
    expect(zh.playerExitBusyRetryingPlayback, contains('重试播放'));

    const en = AppLocalizations(Locale('en'));
    expect(
      en.playerExitBusyNextEpisode.toLowerCase(),
      contains('next episode'),
    );
    expect(
      en.playerExitBusyExternalPlayer.toLowerCase(),
      contains('external player'),
    );
    expect(
      en.playerExitBusyRetryingPlayback.toLowerCase(),
      contains('retry'),
    );
    expect(
      en.playerExitBusyNextEpisode.toLowerCase(),
      isNot(contains('current playback action')),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.playerExitBusyNextEpisode, contains('次のエピソード'));
    expect(ja.playerExitBusyExternalPlayer, contains('外部プレイヤー'));
    expect(ja.playerExitBusyRetryingPlayback, contains('再試行'));
  });

  test('source health labels stay localized in Chinese and Japanese', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.sourceHealthHealthy, '正常');
    expect(zh.sourceHealthDegraded, '不稳定');
    expect(zh.sourceHealthUnavailable, '不可用');
    expect(zh.sourceHealthDegradedHint, isNot(contains('fallback')));
    expect(zh.sourceHealthUnavailableHint, isNot(contains('fallback')));

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.sourceHealthHealthy, '正常');
    expect(ja.sourceHealthDegraded, '不安定');
    expect(ja.sourceHealthUnavailable, '利用不可');
    expect(ja.sourceHealthDegradedHint, isNot(contains('fallback')));
    expect(ja.sourceHealthUnavailableHint, isNot(contains('fallback')));
  });

  test('runtime diagnostics helpers keep support copy localized', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.runtimeDiagnosticsSubtitle, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsSummaryHint, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsEmptyHint, isNot(contains('Debug')));
    expect(
      zh.playbackDiagnosticsSnapshotPreview(
        '番剧 A',
        '第 2 集',
        'Sakura Anime · 线路 1',
        '2026/6/17 09:02',
      ),
      '最近一次播放：番剧 A · 第 2 集\nSakura Anime · 线路 1 · 2026/6/17 09:02',
    );
    expect(zh.playbackDiagnosticsDebugHint, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsDebugHint, isNot(contains('header keys')));
    expect(zh.copyDiagnosticsPlaybackPendingHint, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticCapturedAt, '采集时间');
    expect(zh.selectedAppSource, '应用所选数据源');
    expect(zh.playbackDiagnosticSelectedAppSource, '播放时应用所选数据源');
    expect(zh.playbackDiagnosticRequestedSource, '所选播放源');
    expect(zh.playbackDiagnosticSource, '当前播放源');
    expect(zh.playbackDiagnosticSourceStatus, '播放源状态');
    expect(zh.sourceFallbackEvents, isNot(contains('fallback')));
    expect(zh.sourceFallbackEventsEmpty, isNot(contains('fallback')));
    expect(zh.playbackDiagnosticHeaders, '请求头名称');
    expect(zh.yesNo(true), '是');
    expect(zh.yesNo(false), '否');
    expect(zh.platformDisplayName('android'), 'Android');
    expect(zh.sourceOperationLabel('detail'), '详情');

    const en = AppLocalizations(Locale('en'));
    expect(en.playbackDiagnosticsSummaryHint, isNot(contains('player page')));
    expect(
      en.playbackDiagnosticsSnapshotPreview(
        'Anime 1',
        'Episode 2',
        'Mock Anime Source · Line 1',
        'Jun 17, 2026 1:02 AM',
      ),
      'Latest playback: Anime 1 · Episode 2\nMock Anime Source · Line 1 · Jun 17, 2026 1:02 AM',
    );
    expect(en.playbackDiagnosticHeaders, 'Request header names');
    expect(en.playbackDiagnosticCapturedAt, 'Captured at');
    expect(en.selectedAppSource, 'Selected app source');
    expect(en.copyPlaybackDiagnostics, 'Copy playback diagnostics');
    expect(en.playbackDiagnosticsCopied, 'Playback diagnostics copied');
    expect(
      en.playbackDiagnosticSelectedAppSource,
      'Selected app source at playback',
    );
    expect(en.playbackDiagnosticRequestedSource, 'Selected playback source');
    expect(en.playbackDiagnosticSource, 'Active playback source');
    expect(en.playbackDiagnosticSourceStatus, 'Playback source status');
    expect(
      en.copyDiagnosticsPlaybackPendingHint,
      contains('playback section stays unavailable'),
    );
    expect(en.sourceOperationLabel('play_sources'), 'Playback lines');
    expect(en.yesNo(true), 'Yes');
    expect(en.yesNo(false), 'No');

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.runtimeDiagnosticsSubtitle, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsSummaryHint, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsEmptyHint, isNot(contains('Debug')));
    expect(
      ja.playbackDiagnosticsSnapshotPreview(
        'アニメ 1',
        '第 2 話',
        'Sakura Anime · ライン 1',
        '2026/6/17 1:02',
      ),
      '最新の再生: アニメ 1 · 第 2 話\nSakura Anime · ライン 1 · 2026/6/17 1:02',
    );
    expect(ja.playbackDiagnosticsDebugHint, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsDebugHint, isNot(contains('header keys')));
    expect(ja.copyDiagnosticsPlaybackPendingHint, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticCapturedAt, '取得時刻');
    expect(ja.selectedAppSource, '選択中のアプリソース');
    expect(ja.copyPlaybackDiagnostics, '再生診断をコピー');
    expect(ja.playbackDiagnosticsCopied, '再生診断をコピーしました');
    expect(ja.playbackDiagnosticSelectedAppSource, '再生時のアプリソース');
    expect(ja.playbackDiagnosticRequestedSource, '選択した再生ソース');
    expect(ja.playbackDiagnosticSource, '現在の再生ソース');
    expect(ja.playbackDiagnosticSourceStatus, '再生ソース状態');
    expect(ja.sourceFallbackEvents, isNot(contains('fallback')));
    expect(ja.sourceFallbackEventsEmpty, isNot(contains('fallback')));
    expect(ja.playbackDiagnosticHeaders, 'リクエストヘッダー名');
    expect(ja.yesNo(true), 'はい');
    expect(ja.yesNo(false), 'いいえ');
    expect(ja.platformDisplayName('windows'), 'Windows');
    expect(ja.sourceOperationLabel('detail'), '詳細');
  });
}
