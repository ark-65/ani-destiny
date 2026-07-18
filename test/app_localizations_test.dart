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

  test('source operation labels normalize space and dash variants', () {
    for (final locale in const [Locale('zh'), Locale('en'), Locale('ja')]) {
      final l10n = AppLocalizations(locale);

      final playbackSourcesLabel = l10n.sourceOperationLabel('play_sources');
      expect(l10n.sourceOperationLabel('play sources'), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('play-sources'), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('play/sources'), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('  play  sources  '), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('playSources'), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('play-line'), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('play_line'), equals(playbackSourcesLabel));
      expect(l10n.sourceOperationLabel('playline'), equals(playbackSourcesLabel));

      final playbackQueueLabel = l10n.sourceOperationLabel('playback_queue');
      expect(l10n.sourceOperationLabel('playback queue'), equals(playbackQueueLabel));
      expect(l10n.sourceOperationLabel('playback-queue'), equals(playbackQueueLabel));
      expect(l10n.sourceOperationLabel('playbackQueue'), equals(playbackQueueLabel));
    }
  });

  test('missing source copy tells users to switch source first', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(
      zh.noPlaySource,
      contains('请先切换到其他数据源再重试'),
    );
    expect(
      zh.noDownloadSource,
      contains('请先切换到其他数据源再重试'),
    );

    const en = AppLocalizations(Locale('en'));
    expect(
      en.noPlaySource,
      contains('Switch to another source before retrying'),
    );
    expect(
      en.noDownloadSource,
      contains('Switch to another source before retrying'),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(
      ja.noPlaySource,
      contains('先に別のソースへ切り替えてから再試行してください'),
    );
    expect(
      ja.noDownloadSource,
      contains('先に別のソースへ切り替えてから再試行してください'),
    );
  });

  test('missing source suggestion copy follows next-step guidance', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(
      zh.sourceUnavailableSuggestion,
      contains('先切换到其他数据源再重试'),
    );

    const en = AppLocalizations(Locale('en'));
    expect(
      en.sourceUnavailableSuggestion,
      contains('Switch to another source before retrying'),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(
      ja.sourceUnavailableSuggestion,
      contains('先に別のソースへ切り替えてから再試行してください'),
    );
  });

  test('playback failure guidance in Chinese stays calm and actionable', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.playbackFailedSuggestion, contains('播放暂时中断了'));
    expect(zh.playbackFailedSuggestion, contains('先点“重试”恢复'));
    expect(zh.playbackFailedSuggestion, contains('切换到其他播放线路'));
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
    expect(zh.sourceFallbackNotice, contains('切换到其他数据源再重试'));
    expect(zh.sourceFallbackNotice, isNot(contains('备用数据')));

    const en = AppLocalizations(Locale('en'));
    expect(en.sourceFallbackNotice, contains('AniDestiny'));
    expect(en.sourceFallbackNotice, contains('another source'));
    expect(
      en.sourceFallbackNotice.toLowerCase(),
      contains('switch to another source and retry'),
    );
    expect(
      en.sourceFallbackNotice.toLowerCase(),
      isNot(contains('fallback data')),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.sourceFallbackNotice, contains('AniDestiny'));
    expect(ja.sourceFallbackNotice, contains('別のソース'));
    expect(ja.sourceFallbackNotice, contains('別のソースに切り替えて再試行'));
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

  test('download stopped and stopping states stay distinct in Japanese', () {
    const ja = AppLocalizations(Locale('ja'));
    expect(ja.downloadStoppingStatus, '停止中...');
    expect(ja.downloadStoppedStatus, '停止済み');
    expect(ja.downloadStoppedStatus, isNot(contains('中')));
  });

  test('download entry action copy points directly to Downloads', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.checkDownloadLines, '查看下载线路');
    expect(zh.openDownloads, '打开下载列表');
    expect(zh.openDownloads, contains('下载'));
    expect(zh.reviewInDownloads, '去下载列表查看');
    expect(zh.reviewInDownloads, contains('下载'));

    const en = AppLocalizations(Locale('en'));
    expect(en.checkDownloadLines, 'Check download lines');
    expect(en.openDownloads, 'Open Downloads');
    expect(en.openDownloads, isNot('Open'));
    expect(en.reviewInDownloads, 'Review in Downloads');
    expect(en.reviewInDownloads, contains('Downloads'));

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.checkDownloadLines, 'ダウンロードラインを確認');
    expect(ja.openDownloads, 'ダウンロード一覧を開く');
    expect(ja.openDownloads, contains('ダウンロード'));
    expect(ja.reviewInDownloads, 'ダウンロード一覧で確認');
    expect(ja.reviewInDownloads, contains('ダウンロード'));
  });

  test('failed partial download guidance uses discard wording', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.downloadFailedRetryOrDiscardPartialNote, contains('放弃这个下载'));
    expect(
      zh.downloadFailedRetryOrDiscardPartialNote,
      isNot(contains('从列表移除')),
    );

    const en = AppLocalizations(Locale('en'));
    expect(
      en.downloadFailedRetryOrDiscardPartialNote,
      contains('discard this download'),
    );
    expect(
      en.downloadFailedRetryOrDiscardPartialNote,
      isNot(contains('remove it from the list')),
    );

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.downloadFailedRetryOrDiscardPartialNote, contains('破棄'));
    expect(
      ja.downloadFailedRetryOrDiscardPartialNote,
      isNot(contains('一覧から削除')),
    );
  });

  test('runtime diagnostics helpers keep support copy localized', () {
    const zh = AppLocalizations(Locale('zh'));
    expect(zh.runtimeDiagnosticsSubtitle, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsEmptyHint, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticsLatestPlayback, '最近一次播放');
    expect(zh.playbackDiagnosticsRequestDetails, '播放请求细节');
    expect(
      zh.playbackDiagnosticsRequestDetailsHint,
      '下面这些是最近一次播放的已脱敏请求细节，主要用于确认线路和请求是否正常。',
    );
    expect(
      zh.playbackDiagnosticsSnapshotHint,
      '这里展示的是当前会话里捕获的最近一次播放现场；先确认作品、播放源、状态、线路和采集时间。',
    );
    expect(
      zh.playbackDiagnosticsSnapshotPreview(
        '番剧 A',
        '第 2 集',
        '当前播放源：Sakura Anime · 线路 1\n状态：缓冲中',
        '采集时间：2026/6/17 09:02',
      ),
      '番剧 A · 第 2 集\n当前播放源：Sakura Anime · 线路 1\n状态：缓冲中\n采集时间：2026/6/17 09:02',
    );
    expect(zh.copyDiagnosticsPlaybackPendingHint, isNot(contains('Debug')));
    expect(zh.playbackDiagnosticCapturedAt, '采集时间');
    expect(zh.selectedAppSource, '应用所选数据源');
    expect(zh.playbackDiagnosticSelectedAppSource, '播放时应用所选数据源');
    expect(zh.playbackDiagnosticRequestedSource, '所选播放源');
    expect(zh.playbackDiagnosticSource, '当前播放源');
    expect(zh.playbackDiagnosticSourceStatus, '播放源状态');
    expect(zh.playbackDiagnosticBuffering, '播放缓存');
    expect(zh.playbackDiagnosticBufferingDefault, '默认省流量');
    expect(zh.playbackDiagnosticBufferingStronger, '强化预读');
    expect(zh.sourceFallbackEvents, isNot(contains('fallback')));
    expect(zh.sourceFallbackEventsEmpty, isNot(contains('fallback')));
    expect(zh.playbackDiagnosticHeaders, '请求头名称');
    expect(zh.playbackDiagnosticsPrivacyNote, '将复制最近一次播放的已脱敏摘要，不包含敏感值。');
    expect(zh.copyPlaybackDiagnosticsPendingHint, '先在当前会话里播放一次后，才能复制最近一次播放诊断。');
    expect(zh.yesNo(true), '是');
    expect(zh.yesNo(false), '否');
    expect(zh.platformDisplayName('android'), 'Android');
    expect(zh.sourceOperationLabel('detail'), '详情');
    expect(zh.sourceOperationLabel(' DETAIL '), zh.sourceOperationLabel('detail'));
    expect(zh.sourceOperationLabel('playback_queue'), '播放队列');
    expect(zh.sourceOperationLabel(' playback_queue_unknown '), '其他操作');

    const en = AppLocalizations(Locale('en'));
    expect(en.playbackDiagnosticsLatestPlayback, 'Latest playback');
    expect(en.playbackDiagnosticsRequestDetails, 'Playback request details');
    expect(
      en.playbackDiagnosticsRequestDetailsHint,
      'These sanitized request details help confirm how the latest playback was requested.',
    );
    expect(
      en.playbackDiagnosticsSnapshotHint,
      'This is the latest playback snapshot captured in this session. Confirm the title, playback source, state, line, and capture time first.',
    );
    expect(
      en.playbackDiagnosticsSnapshotPreview(
        'Anime 1',
        'Episode 2',
        'Active playback source: Mock Anime Source\nLine: Line 1\nState: Buffering',
        'Captured at: Jun 17, 2026 1:02 AM',
      ),
      'Anime 1 · Episode 2\nActive playback source: Mock Anime Source\nLine: Line 1\nState: Buffering\nCaptured at: Jun 17, 2026 1:02 AM',
    );
    expect(en.playbackDiagnosticHeaders, 'Request header names');
    expect(en.playbackDiagnosticCapturedAt, 'Captured at');
    expect(en.selectedAppSource, 'Selected app source');
    expect(en.copyPlaybackDiagnostics, 'Copy playback diagnostics');
    expect(
      en.playbackDiagnosticsPrivacyNote,
      'Copies a sanitized summary of the latest playback without sensitive values.',
    );
    expect(
      en.copyPlaybackDiagnosticsPendingHint,
      'Start playback once in this session to copy the latest playback diagnostics.',
    );
    expect(en.playbackDiagnosticsCopied, 'Playback diagnostics copied');
    expect(
      en.playbackDiagnosticSelectedAppSource,
      'Selected app source at playback',
    );
    expect(en.playbackDiagnosticRequestedSource, 'Selected playback source');
    expect(en.playbackDiagnosticSource, 'Active playback source');
    expect(en.playbackDiagnosticSourceStatus, 'Playback source status');
    expect(en.playbackDiagnosticBuffering, 'Playback buffer');
    expect(en.playbackDiagnosticBufferingDefault, 'Default data saving');
    expect(en.playbackDiagnosticBufferingStronger, 'Stronger preloading');
    expect(
      en.copyDiagnosticsPlaybackPendingHint,
      contains('playback section stays unavailable'),
    );
    expect(en.sourceOperationLabel('play_sources'), 'Playback lines');
    expect(en.sourceOperationLabel(' PLAY_SOURCES '), en.sourceOperationLabel('play_sources'));
    expect(en.sourceOperationLabel('playback_queue'), 'Playback queue');
    expect(en.sourceOperationLabel('playback_queue_unknown'), 'Other operation');
    expect(en.yesNo(true), 'Yes');
    expect(en.yesNo(false), 'No');

    const ja = AppLocalizations(Locale('ja'));
    expect(ja.runtimeDiagnosticsSubtitle, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsEmptyHint, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticsLatestPlayback, '最新の再生');
    expect(ja.playbackDiagnosticsRequestDetails, '再生リクエストの詳細');
    expect(
      ja.playbackDiagnosticsRequestDetailsHint,
      '以下は最新の再生で使われた、機密値を除いたリクエスト詳細です。ラインやリクエストの状態確認に使えます。',
    );
    expect(
      ja.playbackDiagnosticsSnapshotHint,
      'ここには、このセッションで取得した最新の再生状況を表示します。作品名、再生ソース、状態、ライン、取得時刻を先に確認できます。',
    );
    expect(
      ja.copyPlaybackDiagnosticsPendingHint,
      'このセッションで一度再生すると、最新の再生診断をコピーできます。',
    );
    expect(
      ja.playbackDiagnosticsPrivacyNote,
      '最新の再生を機密値なしで要約した内容をコピーします。',
    );
    expect(
      ja.playbackDiagnosticsSnapshotPreview(
        'アニメ 1',
        '第 2 話',
        '現在の再生ソース: Sakura Anime · ライン 1\n状態: バッファ中',
        '取得時刻: 2026/6/17 1:02',
      ),
      'アニメ 1 · 第 2 話\n現在の再生ソース: Sakura Anime · ライン 1\n状態: バッファ中\n取得時刻: 2026/6/17 1:02',
    );
    expect(ja.copyDiagnosticsPlaybackPendingHint, isNot(contains('Debug')));
    expect(ja.playbackDiagnosticCapturedAt, '取得時刻');
    expect(ja.selectedAppSource, '選択中のアプリソース');
    expect(ja.copyPlaybackDiagnostics, '再生診断をコピー');
    expect(ja.playbackDiagnosticsCopied, '再生診断をコピーしました');
    expect(ja.playbackDiagnosticSelectedAppSource, '再生時のアプリソース');
    expect(ja.playbackDiagnosticRequestedSource, '選択した再生ソース');
    expect(ja.playbackDiagnosticSource, '現在の再生ソース');
    expect(ja.playbackDiagnosticSourceStatus, '再生ソース状態');
    expect(ja.playbackDiagnosticBuffering, '再生バッファ');
    expect(ja.playbackDiagnosticBufferingDefault, '標準のデータ節約');
    expect(ja.playbackDiagnosticBufferingStronger, '強化プリロード');
    expect(ja.sourceFallbackEvents, isNot(contains('fallback')));
    expect(ja.sourceFallbackEventsEmpty, isNot(contains('fallback')));
    expect(ja.playbackDiagnosticHeaders, 'リクエストヘッダー名');
    expect(ja.yesNo(true), 'はい');
    expect(ja.yesNo(false), 'いいえ');
    expect(ja.platformDisplayName('windows'), 'Windows');
    expect(ja.sourceOperationLabel('detail'), '詳細');
    expect(ja.sourceOperationLabel(' detail '), ja.sourceOperationLabel('detail'));
    expect(ja.sourceOperationLabel('playback_queue'), '再生キュー');
    expect(ja.sourceOperationLabel('playback_queue_unknown'), 'その他の操作');
  });
}
