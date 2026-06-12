import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static Locale resolve(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return const Locale('zh');
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return const Locale('zh');
  }

  String get _languageCode {
    return switch (locale.languageCode) {
      'en' => 'en',
      'ja' => 'ja',
      _ => 'zh',
    };
  }

  String _t(String key) {
    return _localizedValues[_languageCode]![key] ??
        _localizedValues['zh']![key] ??
        key;
  }

  String get appName => _t('appName');
  String get retry => _t('retry');
  String get home => _t('home');
  String get search => _t('search');
  String get favorites => _t('favorites');
  String get history => _t('history');
  String get settings => _t('settings');
  String get source => _t('source');
  String sourceName(String name) => '${_t('source')}: $name';
  String sourceDisplayName(String sourceId, String fallback) {
    return switch (sourceId) {
      'mock' => _t('mockSourceName'),
      'sakura' => _t('sakuraSourceName'),
      'remote-proxy' => _t('remoteProxySourceName'),
      _ => _sourceFallbackText(
          sourceId: sourceId,
          fallback: fallback,
          unknownText: _t('sourceUnknownName'),
        ),
    };
  }

  String sourceDisplayLabel(String sourceId) {
    return sourceDisplayName(sourceId, sourceId);
  }

  String sourceDisplayDescription(String sourceId, String fallback) {
    return switch (sourceId) {
      'mock' => _t('mockSourceDescription'),
      'sakura' => _t('sakuraSourceDescription'),
      'remote-proxy' => _t('remoteProxySourceDescription'),
      _ => _sourceFallbackText(
          sourceId: sourceId,
          fallback: fallback,
          unknownText: _t('sourceUnknownDescription'),
        ),
    };
  }

  String _sourceFallbackText({
    required String sourceId,
    required String fallback,
    required String unknownText,
  }) {
    final normalizedFallback = fallback.trim();
    if (normalizedFallback.isEmpty || normalizedFallback == sourceId) {
      return unknownText;
    }
    return fallback;
  }

  String get sourceLoading => _t('sourceLoading');
  String get sourceUnknown => _t('sourceUnknown');
  String get schedule => _t('schedule');
  String get recommendations => _t('recommendations');
  String get loadingAnime => _t('loadingAnime');
  String get noRecommendations => _t('noRecommendations');
  String get searchHint => _t('searchHint');
  String get searchEmpty => _t('searchEmpty');
  String get searching => _t('searching');
  String get noMatchingAnime => _t('noMatchingAnime');
  String get back => _t('back');
  String get loadingSchedule => _t('loadingSchedule');
  String get noScheduleData => _t('noScheduleData');
  String dayLabel(int day) => '${_t('day')} $day';
  String get monday => _t('monday');
  String get tuesday => _t('tuesday');
  String get wednesday => _t('wednesday');
  String get thursday => _t('thursday');
  String get friday => _t('friday');
  String get saturday => _t('saturday');
  String get sunday => _t('sunday');
  String get noDescription => _t('noDescription');
  String get favorited => _t('favorited');
  String get favorite => _t('favorite');
  String get episodes => _t('episodes');
  String get download => _t('download');
  String get play => _t('play');
  String get downloads => _t('downloads');
  String get loadingDetail => _t('loadingDetail');
  String get noPlaySource => _t('noPlaySource');
  String get noDownloadSource => _t('noDownloadSource');
  String get selectPlaySource => _t('selectPlaySource');
  String get selectDownloadSource => _t('selectDownloadSource');
  String downloadTaskCreated(String taskId) =>
      '${_t('downloadTaskCreated')}: $taskId';
  String get playerNoPlayUrl => _t('playerNoPlayUrl');
  String get playerReadyHint => _t('playerReadyHint');
  String get playerPreparingPlayback => _t('playerPreparingPlayback');
  String get pause => _t('pause');
  String get playbackSpeed => _t('playbackSpeed');
  String get hideDanmaku => _t('hideDanmaku');
  String get showDanmaku => _t('showDanmaku');
  String get enterFullscreen => _t('enterFullscreen');
  String get exitFullscreen => _t('exitFullscreen');
  String get fullscreenPlaceholder => _t('fullscreenPlaceholder');
  String get fullscreenNotImplemented => _t('fullscreenNotImplemented');
  String get nextEpisode => _t('nextEpisode');
  String get loadingNextEpisode => _t('loadingNextEpisode');
  String get externalPlayer => _t('externalPlayer');
  String get openingExternalPlayer => _t('openingExternalPlayer');
  String get retryingPlayback => _t('retryingPlayback');
  String get playerExitBusy => _t('playerExitBusy');
  String get externalPlayerPlaceholder => _t('externalPlayerPlaceholder');
  String get nextEpisodeNotImplemented => _t('nextEpisodeNotImplemented');
  String get nextEpisodeUnavailable => _t('nextEpisodeUnavailable');
  String get externalPlayerHeadersUnsupported =>
      _t('externalPlayerHeadersUnsupported');
  String get externalPlayerUnavailable => _t('externalPlayerUnavailable');
  String get externalPlayerNotImplemented => _t('externalPlayerNotImplemented');
  String get playbackDiagnostics => _t('playbackDiagnostics');
  String get playbackDiagnosticAnime => _t('playbackDiagnosticAnime');
  String get playbackDiagnosticEpisode => _t('playbackDiagnosticEpisode');
  String get playbackDiagnosticRequestedSource =>
      _t('playbackDiagnosticRequestedSource');
  String get playbackDiagnosticSource => _t('playbackDiagnosticSource');
  String get playbackDiagnosticLine => _t('playbackDiagnosticLine');
  String get playbackDiagnosticUrlType => _t('playbackDiagnosticUrlType');
  String get playbackDiagnosticUrl => _t('playbackDiagnosticUrl');
  String get playbackDiagnosticHeaders => _t('playbackDiagnosticHeaders');
  String get playbackDiagnosticState => _t('playbackDiagnosticState');
  String get playbackDiagnosticStateLoading =>
      _t('playbackDiagnosticStateLoading');
  String get playbackDiagnosticStateReady => _t('playbackDiagnosticStateReady');
  String get playbackDiagnosticStatePlaying =>
      _t('playbackDiagnosticStatePlaying');
  String get playbackDiagnosticStateBuffering =>
      _t('playbackDiagnosticStateBuffering');
  String get playbackDiagnosticStateError => _t('playbackDiagnosticStateError');
  String get open => _t('open');
  String get loadingFavorites => _t('loadingFavorites');
  String get favoriteEmpty => _t('favoriteEmpty');
  String get removeFavorite => _t('removeFavorite');
  String get loadingHistory => _t('loadingHistory');
  String get historyEmpty => _t('historyEmpty');
  String get deleteHistory => _t('deleteHistory');
  String get loadingDownloads => _t('loadingDownloads');
  String get downloadsEmpty => _t('downloadsEmpty');
  String get clearEndedDownloads => _t('clearEndedDownloads');
  String clearEndedDownloadsResult(int count) =>
      '${_t('clearEndedDownloadsResultPrefix')}$count${_t('clearEndedDownloadsResultSuffix')}';
  String clearEndedDownloadsPartialResult(int clearedCount, int failedCount) =>
      '${_t('clearEndedDownloadsPartialResultPrefix')}$clearedCount${_t('clearEndedDownloadsPartialResultMiddle')}$failedCount${_t('clearEndedDownloadsPartialResultSuffix')}';
  String get mock => _t('mock');
  String mockDownloadTaskCreated(String taskId) =>
      '${_t('mockDownloadTaskCreated')}: $taskId';
  String get start => _t('start');
  String get cancel => _t('cancel');
  String get remove => _t('remove');
  String get downloadProgress => _t('downloadProgress');
  String get downloadLocalPath => _t('downloadLocalPath');
  String get downloadBasicPauseNote => _t('downloadBasicPauseNote');
  String get downloadKindDirectFile => _t('downloadKindDirectFile');
  String get downloadKindHls => _t('downloadKindHls');
  String get downloadKindBt => _t('downloadKindBt');
  String get downloadKindUnknown => _t('downloadKindUnknown');
  String get downloadFailureUnsupportedType =>
      _t('downloadFailureUnsupportedType');
  String get downloadFailurePermissionDenied =>
      _t('downloadFailurePermissionDenied');
  String get downloadFailureNetworkError => _t('downloadFailureNetworkError');
  String get downloadFailureSourceUnavailable =>
      _t('downloadFailureSourceUnavailable');
  String get downloadFailureInvalidUrl => _t('downloadFailureInvalidUrl');
  String get downloadFailureInvalidManifest =>
      _t('downloadFailureInvalidManifest');
  String get downloadFailureStorageUnavailable =>
      _t('downloadFailureStorageUnavailable');
  String get downloadFailureUnknown => _t('downloadFailureUnknown');
  String get playback => _t('playback');
  String get sourceSettings => _t('sourceSettings');
  String get sourceSettingsSubtitle => _t('sourceSettingsSubtitle');
  String get danmakuSettings => _t('danmakuSettings');
  String get appearance => _t('appearance');
  String get system => _t('system');
  String get light => _t('light');
  String get dark => _t('dark');
  String get about => _t('about');
  String get aboutAniDestiny => _t('aboutAniDestiny');
  String appVersion(String version) => '${_t('appVersionPrefix')}$version';
  String get appDescription => _t('appDescription');
  String get supportedPlatforms => _t('supportedPlatforms');
  String get supportedPlatformsValue => _t('supportedPlatformsValue');
  String get sourceStatus => _t('sourceStatus');
  String get sourceStatusValue => _t('sourceStatusValue');
  String get danmakuAbout => _t('danmakuAbout');
  String get danmakuAboutValue => _t('danmakuAboutValue');
  String get copyDiagnostics => _t('copyDiagnostics');
  String get diagnosticsCopied => _t('diagnosticsCopied');
  String get diagnosticsCopyFailed => _t('diagnosticsCopyFailed');
  String get diagnosticsPrivacyNote => _t('diagnosticsPrivacyNote');
  String get reportIssue => _t('reportIssue');
  String get githubRepository => _t('githubRepository');
  String get openSource => _t('openSource');
  String get releasePage => _t('releasePage');
  String get runtimeDiagnostics => _t('runtimeDiagnostics');
  String get runtimeDiagnosticsSubtitle => _t('runtimeDiagnosticsSubtitle');
  String get platform => _t('platform');
  String get currentSource => _t('currentSource');
  String get currentSourceId => _t('currentSourceId');
  String get latestSourceDiagnostics => _t('latestSourceDiagnostics');
  String get playbackDiagnosticsSummary => _t('playbackDiagnosticsSummary');
  String sourceFallbackPlayerNotice(
    String requestedSource,
    String activeSource,
  ) {
    final template = _t('sourceFallbackPlayerNotice');
    return template
        .replaceFirst('{requestedSource}', requestedSource)
        .replaceFirst('{activeSource}', activeSource);
  }

  String get playbackDiagnosticsDebugHint => _t('playbackDiagnosticsDebugHint');
  String get sourceTemporarilyUnavailable => _t('sourceTemporarilyUnavailable');
  String get sourceUnavailableSuggestion => _t('sourceUnavailableSuggestion');
  String get noPlayableSourceFound => _t('noPlayableSourceFound');
  String get playbackFailedSuggestion => _t('playbackFailedSuggestion');
  String get sources => _t('sources');
  String get loadingCurrentSource => _t('loadingCurrentSource');
  String sourceSetTo(String sourceId) => '${_t('sourceSetTo')} $sourceId';
  String get sourceV1Note => _t('sourceV1Note');
  String get sourceCurrent => _t('sourceCurrent');
  String get sourceDefaultBadge => _t('sourceDefaultBadge');
  String get sourceDiagnostics => _t('sourceDiagnostics');
  String get sourceDiagnosticsSubtitle => _t('sourceDiagnosticsSubtitle');
  String get sourceDiagnosticsEmpty => _t('sourceDiagnosticsEmpty');
  String get sourceDiagnosticsClear => _t('sourceDiagnosticsClear');
  String get sourceFallbackNotice => _t('sourceFallbackNotice');
  String get sourceHealth => _t('sourceHealth');
  String get sourceHealthHealthy => _t('sourceHealthHealthy');
  String get sourceHealthDegraded => _t('sourceHealthDegraded');
  String get sourceHealthUnavailable => _t('sourceHealthUnavailable');
  String sourceFailureCount(int count) => '${_t('sourceFailureCount')}: $count';
  String sourceLastError(String message) =>
      '${_t('sourceLastError')}: $message';
  String get sourceResetStatus => _t('sourceResetStatus');
  String get sourceStatusReset => _t('sourceStatusReset');
  String get sourceFallbackEvents => _t('sourceFallbackEvents');
  String get sourceFallbackEventsEmpty => _t('sourceFallbackEventsEmpty');
  String sourceTransitionLabel(String fromSourceId, String toSourceId) =>
      '${sourceDisplayLabel(fromSourceId)} -> ${sourceDisplayLabel(toSourceId)}';
  String get danmaku => _t('danmaku');
  String get danmakuStatusLoading => _t('danmakuStatusLoading');
  String get danmakuStatusDandanplay => _t('danmakuStatusDandanplay');
  String get danmakuStatusFallback => _t('danmakuStatusFallback');
  String get danmakuStatusEmpty => _t('danmakuStatusEmpty');
  String get danmakuStatusUnavailable => _t('danmakuStatusUnavailable');
  String get danmakuStatusAvailable => _t('danmakuStatusAvailable');
  String get enabled => _t('enabled');
  String opacityPercent(int percent) => '${_t('opacity')} $percent%';
  String fontSize(int size) => '${_t('fontSize')} $size';
  String speedValue(String value) => '${_t('speed')} ${value}x';
  String get pending => _t('pending');
  String get preparing => _t('preparing');
  String get downloading => _t('downloading');
  String get paused => _t('paused');
  String get completed => _t('completed');
  String get failed => _t('failed');
  String get canceled => _t('canceled');
  String get unsupported => _t('unsupported');
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(
      AppLocalizations.resolve(locale, AppLocalizations.supportedLocales),
    );
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

const _localizedValues = {
  'zh': {
    'appName': 'AniDestiny',
    'retry': '重试',
    'home': '首页',
    'search': '搜索',
    'favorites': '收藏',
    'history': '历史',
    'settings': '设置',
    'source': '数据源',
    'mockSourceName': 'Mock 动漫数据源',
    'mockSourceDescription': '本地 Mock 数据源，用来保证 AniDestiny 第一版可运行。',
    'sakuraSourceName': 'Sakura Anime',
    'sakuraSourceDescription': '默认网页解析数据源；如上游站点波动，可稍后重试或切换其他数据源。',
    'remoteProxySourceName': '远程数据源代理',
    'remoteProxySourceDescription': '预留给未来自建代理服务，第一版不强依赖。',
    'sourceUnknownName': '未知数据源',
    'sourceUnknownDescription': '暂未提供该数据源说明。',
    'sourceLoading': '数据源：加载中',
    'sourceUnknown': '数据源：未知',
    'schedule': '更新时间表',
    'recommendations': '推荐番剧',
    'loadingAnime': '正在加载番剧',
    'noRecommendations': '暂无推荐番剧',
    'searchHint': '番剧标题、标签或关键词',
    'searchEmpty': '搜索番剧、标签或关键词，开始浏览内容',
    'searching': '正在搜索',
    'noMatchingAnime': '没有匹配的番剧',
    'back': '返回',
    'loadingSchedule': '正在加载时间表',
    'noScheduleData': '暂无时间表数据',
    'day': '第',
    'monday': '周一',
    'tuesday': '周二',
    'wednesday': '周三',
    'thursday': '周四',
    'friday': '周五',
    'saturday': '周六',
    'sunday': '周日',
    'noDescription': '暂无简介',
    'favorited': '已收藏',
    'favorite': '收藏',
    'episodes': '剧集',
    'download': '下载',
    'play': '播放',
    'downloads': '下载',
    'loadingDetail': '正在加载详情',
    'noPlaySource': '未找到可播放线路，请稍后重试或切换数据源。',
    'noDownloadSource': '未找到可下载线路，请稍后重试或切换数据源。',
    'selectPlaySource': '选择播放线路',
    'selectDownloadSource': '选择下载线路',
    'downloadTaskCreated': '已创建下载任务',
    'playerNoPlayUrl': '未找到可播放线路',
    'playerReadyHint': '播放器预览已就绪',
    'playerPreparingPlayback': '正在准备播放…',
    'pause': '暂停',
    'playbackSpeed': '播放速度',
    'hideDanmaku': '隐藏弹幕',
    'showDanmaku': '显示弹幕',
    'enterFullscreen': '进入全屏',
    'exitFullscreen': '退出全屏',
    'fullscreenPlaceholder': '全屏',
    'fullscreenNotImplemented': '全屏暂未实现。',
    'nextEpisode': '下一集',
    'loadingNextEpisode': '正在切换到下一集…',
    'externalPlayer': '外部播放器',
    'openingExternalPlayer': '正在打开外部播放器…',
    'retryingPlayback': '正在重试播放…',
    'playerExitBusy': '当前播放操作尚未完成，请稍候后再离开。',
    'externalPlayerPlaceholder': '外部播放器占位',
    'nextEpisodeNotImplemented': '下一集暂未实现。',
    'nextEpisodeUnavailable': '当前已经是最后一集了。',
    'externalPlayerHeadersUnsupported': '当前播放线路依赖额外请求头，暂时无法直接交给外部播放器打开。',
    'externalPlayerUnavailable': '暂时无法交给外部播放器打开，请稍后重试。',
    'externalPlayerNotImplemented': '外部播放器暂未实现。',
    'playbackDiagnostics': '播放诊断',
    'playbackDiagnosticAnime': '番剧',
    'playbackDiagnosticEpisode': '剧集',
    'playbackDiagnosticRequestedSource': '原始数据源',
    'playbackDiagnosticSource': '数据源',
    'playbackDiagnosticLine': '线路',
    'playbackDiagnosticUrlType': 'URL 类型',
    'playbackDiagnosticUrl': 'URL',
    'playbackDiagnosticHeaders': 'Headers',
    'playbackDiagnosticState': '状态',
    'playbackDiagnosticStateLoading': '加载中',
    'playbackDiagnosticStateReady': '就绪',
    'playbackDiagnosticStatePlaying': '播放中',
    'playbackDiagnosticStateBuffering': '缓冲中',
    'playbackDiagnosticStateError': '播放失败',
    'open': '打开',
    'loadingFavorites': '正在加载收藏',
    'favoriteEmpty': '收藏的番剧会显示在这里',
    'removeFavorite': '移除收藏',
    'loadingHistory': '正在加载历史',
    'historyEmpty': '播放历史会显示在这里',
    'deleteHistory': '删除历史',
    'loadingDownloads': '正在加载下载',
    'downloadsEmpty': '下载任务会显示在这里',
    'clearEndedDownloads': '清理已结束任务',
    'clearEndedDownloadsResultPrefix': '已清理 ',
    'clearEndedDownloadsResultSuffix': ' 个已结束任务。',
    'clearEndedDownloadsPartialResultPrefix': '已清理 ',
    'clearEndedDownloadsPartialResultMiddle': ' 个已结束任务，',
    'clearEndedDownloadsPartialResultSuffix': ' 个清理失败。',
    'mock': 'Mock',
    'mockDownloadTaskCreated': '已创建 Mock 下载任务',
    'start': '开始',
    'cancel': '取消',
    'remove': '移除',
    'downloadProgress': '进度',
    'downloadLocalPath': '本地路径',
    'downloadBasicPauseNote': '暂停为基础能力，继续时可能重新下载。',
    'downloadKindDirectFile': '直链文件',
    'downloadKindHls': 'HLS / m3u8',
    'downloadKindBt': 'BT 占位',
    'downloadKindUnknown': '未知类型',
    'downloadFailureUnsupportedType': '暂不支持该类型',
    'downloadFailurePermissionDenied': '权限不足',
    'downloadFailureNetworkError': '网络错误',
    'downloadFailureSourceUnavailable': '数据源不可用',
    'downloadFailureInvalidUrl': 'URL 无效',
    'downloadFailureInvalidManifest': 'm3u8 无效',
    'downloadFailureStorageUnavailable': '存储不可用',
    'downloadFailureUnknown': '未知错误',
    'playback': '播放',
    'sourceSettings': '数据源设置',
    'sourceSettingsSubtitle': '默认使用 Sakura Anime，可按可用性切换数据源',
    'danmakuSettings': '弹幕设置',
    'appearance': '外观',
    'system': '跟随系统',
    'light': '浅色',
    'dark': '深色',
    'about': '关于',
    'aboutAniDestiny': 'AniDestiny',
    'appVersionPrefix': '非盈利学习项目 · v',
    'appDescription': '一个跨平台动漫发现与播放应用。',
    'supportedPlatforms': '支持平台',
    'supportedPlatformsValue': 'Android / Windows / macOS',
    'sourceStatus': '数据源状态',
    'sourceStatusValue': 'Sakura 数据源依赖上游站点可用性；解析波动时可稍后重试或切换其他数据源。',
    'danmakuAbout': '弹幕',
    'danmakuAboutValue': '弹弹play 为可选集成；不可用时使用 fallback。',
    'copyDiagnostics': '复制诊断信息',
    'diagnosticsCopied': '诊断信息已复制',
    'diagnosticsCopyFailed': '复制诊断信息失败',
    'diagnosticsPrivacyNote': '将生成已脱敏的反馈摘要，不包含敏感值。',
    'reportIssue': '反馈问题',
    'githubRepository': 'GitHub 仓库',
    'openSource': '开源地址',
    'releasePage': '发布地址',
    'runtimeDiagnostics': '运行诊断',
    'runtimeDiagnosticsSubtitle': 'Debug 模式下查看反馈用摘要，不展示敏感值。',
    'platform': '平台',
    'currentSource': '当前数据源',
    'currentSourceId': '当前数据源 ID',
    'latestSourceDiagnostics': '最近数据源诊断',
    'playbackDiagnosticsSummary': '播放诊断摘要',
    'sourceFallbackPlayerNotice':
        '当前所选数据源 {requestedSource} 暂时不可用，播放器正在使用 {activeSource} 的备用播放数据。',
    'playbackDiagnosticsDebugHint':
        '播放页 Debug 按钮可查看当前播放线路、URL 类型和 header keys。',
    'sourceTemporarilyUnavailable': '数据源暂时不可用',
    'sourceUnavailableSuggestion': '上游数据源可能已变化或暂时不可用，请稍后重试或切换数据源。',
    'noPlayableSourceFound': '未找到可播放线路，请稍后重试或切换数据源。',
    'playbackFailedSuggestion': '播放暂时失败，请稍后重试或尝试其他播放线路。',
    'sources': '数据源',
    'loadingCurrentSource': '正在加载当前数据源',
    'sourceSetTo': '数据源已切换为',
    'sourceV1Note': 'Sakura Anime 是当前默认数据源；如受上游站点变化影响，请切换其他数据源或稍后重试。',
    'sourceCurrent': '当前启用',
    'sourceDefaultBadge': '默认源',
    'sourceDiagnostics': '数据源诊断',
    'sourceDiagnosticsSubtitle': '查看最近的数据源请求和解析状态。',
    'sourceDiagnosticsEmpty': '暂无诊断记录',
    'sourceDiagnosticsClear': '清空',
    'sourceFallbackNotice': '当前数据源暂时不可用，正在显示备用数据。',
    'sourceHealth': '数据源健康状态',
    'sourceHealthHealthy': 'Healthy',
    'sourceHealthDegraded': 'Degraded',
    'sourceHealthUnavailable': 'Unavailable',
    'sourceFailureCount': '失败次数',
    'sourceLastError': '最近问题',
    'sourceResetStatus': '重置状态',
    'sourceStatusReset': '数据源状态已重置',
    'sourceFallbackEvents': '最近 fallback 事件',
    'sourceFallbackEventsEmpty': '暂无 fallback 事件',
    'danmaku': '弹幕',
    'danmakuStatusLoading': '弹幕：加载中',
    'danmakuStatusDandanplay': '弹幕：弹弹play',
    'danmakuStatusFallback': '弹幕：fallback',
    'danmakuStatusEmpty': '弹幕：空',
    'danmakuStatusUnavailable': '弹幕不可用',
    'danmakuStatusAvailable': '弹幕：可用',
    'enabled': '启用',
    'opacity': '不透明度',
    'fontSize': '字号',
    'speed': '速度',
    'pending': '等待中',
    'preparing': '准备中',
    'downloading': '下载中',
    'paused': '已暂停',
    'completed': '已完成',
    'failed': '失败',
    'canceled': '已取消',
    'unsupported': '暂不支持',
  },
  'en': {
    'appName': 'AniDestiny',
    'retry': 'Retry',
    'home': 'Home',
    'search': 'Search',
    'favorites': 'Favorites',
    'history': 'History',
    'settings': 'Settings',
    'source': 'Source',
    'mockSourceName': 'Mock Anime Source',
    'mockSourceDescription':
        'Local mock source used to keep AniDestiny runnable.',
    'sakuraSourceName': 'Sakura Anime',
    'sakuraSourceDescription':
        'Default web parser source. If upstream availability changes, retry later or switch sources.',
    'remoteProxySourceName': 'Remote Source Proxy',
    'remoteProxySourceDescription':
        'Future self-hosted proxy adapter. Not required for first version.',
    'sourceUnknownName': 'Unknown source',
    'sourceUnknownDescription':
        'No description is available for this source yet.',
    'sourceLoading': 'Source: loading',
    'sourceUnknown': 'Source: unknown',
    'schedule': 'Schedule',
    'recommendations': 'Recommendations',
    'loadingAnime': 'Loading anime',
    'noRecommendations': 'No recommendations yet',
    'searchHint': 'Anime title, tag, or mood',
    'searchEmpty': 'Search anime, tags, or keywords to start browsing',
    'searching': 'Searching',
    'noMatchingAnime': 'No matching anime',
    'back': 'Back',
    'loadingSchedule': 'Loading schedule',
    'noScheduleData': 'No schedule data',
    'day': 'Day',
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
    'noDescription': 'No description',
    'favorited': 'Favorited',
    'favorite': 'Favorite',
    'episodes': 'Episodes',
    'download': 'Download',
    'play': 'Play',
    'downloads': 'Downloads',
    'loadingDetail': 'Loading detail',
    'noPlaySource':
        'No playable source found. Try another source or retry later.',
    'noDownloadSource':
        'No downloadable source found. Try another source or retry later.',
    'selectPlaySource': 'Select playback line',
    'selectDownloadSource': 'Select download line',
    'downloadTaskCreated': 'Download task created',
    'playerNoPlayUrl': 'No playable source found',
    'playerReadyHint': 'Playback preview ready',
    'playerPreparingPlayback': 'Preparing playback...',
    'pause': 'Pause',
    'playbackSpeed': 'Playback speed',
    'hideDanmaku': 'Hide danmaku',
    'showDanmaku': 'Show danmaku',
    'enterFullscreen': 'Enter fullscreen',
    'exitFullscreen': 'Exit fullscreen',
    'fullscreenPlaceholder': 'Fullscreen',
    'fullscreenNotImplemented': 'Fullscreen is not implemented yet.',
    'nextEpisode': 'Next episode',
    'loadingNextEpisode': 'Loading next episode...',
    'externalPlayer': 'External player',
    'openingExternalPlayer': 'Opening external player...',
    'retryingPlayback': 'Retrying playback...',
    'playerExitBusy':
        'Please wait for the current playback action to finish before leaving.',
    'externalPlayerPlaceholder': 'External player placeholder',
    'nextEpisodeNotImplemented': 'Next episode is not implemented yet.',
    'nextEpisodeUnavailable':
        'You are already on the latest available episode.',
    'externalPlayerHeadersUnsupported':
        'This stream needs request headers, so it cannot be opened in an external player yet.',
    'externalPlayerUnavailable':
        'Could not open in an external player. Try again later.',
    'externalPlayerNotImplemented': 'External player is not implemented yet.',
    'playbackDiagnostics': 'Playback diagnostics',
    'playbackDiagnosticAnime': 'Anime',
    'playbackDiagnosticEpisode': 'Episode',
    'playbackDiagnosticRequestedSource': 'Requested source',
    'playbackDiagnosticSource': 'Source',
    'playbackDiagnosticLine': 'Line',
    'playbackDiagnosticUrlType': 'URL type',
    'playbackDiagnosticUrl': 'URL',
    'playbackDiagnosticHeaders': 'Headers',
    'playbackDiagnosticState': 'State',
    'playbackDiagnosticStateLoading': 'Loading',
    'playbackDiagnosticStateReady': 'Ready',
    'playbackDiagnosticStatePlaying': 'Playing',
    'playbackDiagnosticStateBuffering': 'Buffering',
    'playbackDiagnosticStateError': 'Failed',
    'open': 'Open',
    'loadingFavorites': 'Loading favorites',
    'favoriteEmpty': 'Favorite anime will appear here',
    'removeFavorite': 'Remove favorite',
    'loadingHistory': 'Loading history',
    'historyEmpty': 'Playback history will appear here',
    'deleteHistory': 'Delete history',
    'loadingDownloads': 'Loading downloads',
    'downloadsEmpty': 'Download tasks will appear here',
    'clearEndedDownloads': 'Clear ended tasks',
    'clearEndedDownloadsResultPrefix': 'Cleared ',
    'clearEndedDownloadsResultSuffix': ' ended tasks.',
    'clearEndedDownloadsPartialResultPrefix': 'Cleared ',
    'clearEndedDownloadsPartialResultMiddle': ' ended tasks, ',
    'clearEndedDownloadsPartialResultSuffix': ' failed.',
    'mock': 'Mock',
    'mockDownloadTaskCreated': 'Mock download task created',
    'start': 'Start',
    'cancel': 'Cancel',
    'remove': 'Remove',
    'downloadProgress': 'Progress',
    'downloadLocalPath': 'Local path',
    'downloadBasicPauseNote':
        'Pause support is basic and may restart the download.',
    'downloadKindDirectFile': 'Direct file',
    'downloadKindHls': 'HLS / m3u8',
    'downloadKindBt': 'BT placeholder',
    'downloadKindUnknown': 'Unknown type',
    'downloadFailureUnsupportedType': 'Unsupported type',
    'downloadFailurePermissionDenied': 'Permission denied',
    'downloadFailureNetworkError': 'Network error',
    'downloadFailureSourceUnavailable': 'Source unavailable',
    'downloadFailureInvalidUrl': 'Invalid URL',
    'downloadFailureInvalidManifest': 'Invalid m3u8',
    'downloadFailureStorageUnavailable': 'Storage unavailable',
    'downloadFailureUnknown': 'Unknown error',
    'playback': 'Playback',
    'sourceSettings': 'Source settings',
    'sourceSettingsSubtitle':
        'Sakura Anime is the default source. Switch sources when availability changes.',
    'danmakuSettings': 'Danmaku settings',
    'appearance': 'Appearance',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'about': 'About',
    'aboutAniDestiny': 'AniDestiny',
    'appVersionPrefix': 'Non-profit learning project · v',
    'appDescription': 'A cross-platform anime discovery and playback app.',
    'supportedPlatforms': 'Supported platforms',
    'supportedPlatformsValue': 'Android / Windows / macOS',
    'sourceStatus': 'Source status',
    'sourceStatusValue':
        'Sakura source depends on upstream availability. Retry later or switch sources if parsing changes.',
    'danmakuAbout': 'Danmaku',
    'danmakuAboutValue':
        'Dandanplay is optional; fallback is used when unavailable.',
    'copyDiagnostics': 'Copy diagnostics',
    'diagnosticsCopied': 'Diagnostics copied',
    'diagnosticsCopyFailed': 'Failed to copy diagnostics',
    'diagnosticsPrivacyNote':
        'Generates a sanitized feedback summary without sensitive values.',
    'reportIssue': 'Report issue',
    'githubRepository': 'GitHub repository',
    'openSource': 'Open source',
    'releasePage': 'Releases',
    'runtimeDiagnostics': 'Runtime diagnostics',
    'runtimeDiagnosticsSubtitle':
        'Debug-only feedback summary without sensitive values.',
    'platform': 'Platform',
    'currentSource': 'Current source',
    'currentSourceId': 'Current source ID',
    'latestSourceDiagnostics': 'Latest source diagnostics',
    'playbackDiagnosticsSummary': 'Playback diagnostics summary',
    'sourceFallbackPlayerNotice':
        'The selected source {requestedSource} is temporarily unavailable, so playback is using fallback data from {activeSource}.',
    'playbackDiagnosticsDebugHint':
        'Use the debug button on the player page to view the current line, URL type, and header keys.',
    'sourceTemporarilyUnavailable': 'Source temporarily unavailable',
    'sourceUnavailableSuggestion':
        'The upstream source changed or is temporarily unavailable. Try another source or retry later.',
    'noPlayableSourceFound':
        'No playable source found. Try another source or retry later.',
    'playbackFailedSuggestion':
        'Playback temporarily failed. Retry later or try another playback line.',
    'sources': 'Sources',
    'loadingCurrentSource': 'Loading current source',
    'sourceSetTo': 'Source set to',
    'sourceV1Note':
        'Sakura Anime is the current default source. If upstream changes affect parsing, switch sources or retry later.',
    'sourceCurrent': 'Current',
    'sourceDefaultBadge': 'Default source',
    'sourceDiagnostics': 'Source diagnostics',
    'sourceDiagnosticsSubtitle':
        'View recent source request and parser status.',
    'sourceDiagnosticsEmpty': 'No diagnostics yet',
    'sourceDiagnosticsClear': 'Clear',
    'sourceFallbackNotice':
        'The current source is temporarily unavailable. Showing fallback data.',
    'sourceHealth': 'Source health',
    'sourceHealthHealthy': 'Healthy',
    'sourceHealthDegraded': 'Degraded',
    'sourceHealthUnavailable': 'Unavailable',
    'sourceFailureCount': 'Failure count',
    'sourceLastError': 'Last issue',
    'sourceResetStatus': 'Reset status',
    'sourceStatusReset': 'Source status reset',
    'sourceFallbackEvents': 'Latest fallback events',
    'sourceFallbackEventsEmpty': 'No fallback events yet',
    'danmaku': 'Danmaku',
    'danmakuStatusLoading': 'Danmaku: loading',
    'danmakuStatusDandanplay': 'Danmaku: Dandanplay',
    'danmakuStatusFallback': 'Danmaku: fallback',
    'danmakuStatusEmpty': 'Danmaku: empty',
    'danmakuStatusUnavailable': 'Danmaku unavailable',
    'danmakuStatusAvailable': 'Danmaku: available',
    'enabled': 'Enabled',
    'opacity': 'Opacity',
    'fontSize': 'Font size',
    'speed': 'Speed',
    'pending': 'Pending',
    'preparing': 'Preparing',
    'downloading': 'Downloading',
    'paused': 'Paused',
    'completed': 'Completed',
    'failed': 'Failed',
    'canceled': 'Canceled',
    'unsupported': 'Unsupported',
  },
  'ja': {
    'appName': 'AniDestiny',
    'retry': '再試行',
    'home': 'ホーム',
    'search': '検索',
    'favorites': 'お気に入り',
    'history': '履歴',
    'settings': '設定',
    'source': 'ソース',
    'mockSourceName': 'Mock アニメソース',
    'mockSourceDescription': 'AniDestiny 初版を動作させるためのローカル Mock ソースです。',
    'sakuraSourceName': 'Sakura Anime',
    'sakuraSourceDescription':
        '既定のWeb解析ソースです。上流サイトの可用性が変わった場合は、後で再試行するか別のソースに切り替えてください。',
    'remoteProxySourceName': 'リモートソースプロキシ',
    'remoteProxySourceDescription': '将来の自前プロキシ用 Adapter です。初版では必須ではありません。',
    'sourceUnknownName': '不明なソース',
    'sourceUnknownDescription': 'このソースの説明はまだありません。',
    'sourceLoading': 'ソース: 読み込み中',
    'sourceUnknown': 'ソース: 不明',
    'schedule': '放送予定',
    'recommendations': 'おすすめ作品',
    'loadingAnime': '作品を読み込み中',
    'noRecommendations': 'おすすめはまだありません',
    'searchHint': '作品名、タグ、キーワード',
    'searchEmpty': '作品名やキーワードを検索して視聴を始めましょう',
    'searching': '検索中',
    'noMatchingAnime': '一致する作品がありません',
    'back': '戻る',
    'loadingSchedule': '予定を読み込み中',
    'noScheduleData': '予定データがありません',
    'day': 'Day',
    'monday': '月曜日',
    'tuesday': '火曜日',
    'wednesday': '水曜日',
    'thursday': '木曜日',
    'friday': '金曜日',
    'saturday': '土曜日',
    'sunday': '日曜日',
    'noDescription': '説明はありません',
    'favorited': 'お気に入り済み',
    'favorite': 'お気に入り',
    'episodes': 'エピソード',
    'download': 'ダウンロード',
    'play': '再生',
    'downloads': 'ダウンロード',
    'loadingDetail': '詳細を読み込み中',
    'noPlaySource': '再生可能なソースが見つかりません。別のソースを試すか、後で再試行してください。',
    'noDownloadSource': 'ダウンロード可能なソースが見つかりません。別のソースを試すか、後で再試行してください。',
    'selectPlaySource': '再生ラインを選択',
    'selectDownloadSource': 'ダウンロードラインを選択',
    'downloadTaskCreated': 'ダウンロードタスクを作成しました',
    'playerNoPlayUrl': '再生可能なソースが見つかりません',
    'playerReadyHint': '再生プレビューの準備完了',
    'playerPreparingPlayback': '再生を準備中…',
    'pause': '一時停止',
    'playbackSpeed': '再生速度',
    'hideDanmaku': '弾幕を隠す',
    'showDanmaku': '弾幕を表示',
    'enterFullscreen': '全画面で表示',
    'exitFullscreen': '全画面を終了',
    'fullscreenPlaceholder': '全画面',
    'fullscreenNotImplemented': '全画面はまだ実装されていません。',
    'nextEpisode': '次のエピソード',
    'loadingNextEpisode': '次のエピソードに切り替え中…',
    'externalPlayer': '外部プレイヤー',
    'openingExternalPlayer': '外部プレイヤーを起動中…',
    'retryingPlayback': '再生を再試行しています…',
    'playerExitBusy': '現在の再生操作が終わるまで、しばらく待ってから戻ってください。',
    'externalPlayerPlaceholder': '外部プレイヤー',
    'nextEpisodeNotImplemented': '次のエピソードはまだ実装されていません。',
    'nextEpisodeUnavailable': 'すでに最新の配信済みエピソードです。',
    'externalPlayerHeadersUnsupported':
        'この再生ラインは追加のリクエストヘッダーが必要なため、まだ外部プレイヤーでは開けません。',
    'externalPlayerUnavailable': '外部プレイヤーで開けませんでした。しばらくしてからもう一度お試しください。',
    'externalPlayerNotImplemented': '外部プレイヤーはまだ実装されていません。',
    'playbackDiagnostics': '再生診断',
    'playbackDiagnosticAnime': '作品',
    'playbackDiagnosticEpisode': 'エピソード',
    'playbackDiagnosticRequestedSource': '元のソース',
    'playbackDiagnosticSource': 'ソース',
    'playbackDiagnosticLine': 'ライン',
    'playbackDiagnosticUrlType': 'URL 種類',
    'playbackDiagnosticUrl': 'URL',
    'playbackDiagnosticHeaders': 'Headers',
    'playbackDiagnosticState': '状態',
    'playbackDiagnosticStateLoading': '読み込み中',
    'playbackDiagnosticStateReady': '準備完了',
    'playbackDiagnosticStatePlaying': '再生中',
    'playbackDiagnosticStateBuffering': 'バッファ中',
    'playbackDiagnosticStateError': '再生失敗',
    'open': '開く',
    'loadingFavorites': 'お気に入りを読み込み中',
    'favoriteEmpty': 'お気に入り作品がここに表示されます',
    'removeFavorite': 'お気に入りから削除',
    'loadingHistory': '履歴を読み込み中',
    'historyEmpty': '再生履歴がここに表示されます',
    'deleteHistory': '履歴を削除',
    'loadingDownloads': 'ダウンロードを読み込み中',
    'downloadsEmpty': 'ダウンロードタスクがここに表示されます',
    'clearEndedDownloads': '終了済みタスクを整理',
    'clearEndedDownloadsResultPrefix': '終了済みタスクを ',
    'clearEndedDownloadsResultSuffix': ' 件整理しました。',
    'clearEndedDownloadsPartialResultPrefix': '終了済みタスクを ',
    'clearEndedDownloadsPartialResultMiddle': ' 件整理し、',
    'clearEndedDownloadsPartialResultSuffix': ' 件は失敗しました。',
    'mock': 'Mock',
    'mockDownloadTaskCreated': 'Mock ダウンロードタスクを作成しました',
    'start': '開始',
    'cancel': 'キャンセル',
    'remove': '削除',
    'downloadProgress': '進捗',
    'downloadLocalPath': 'ローカルパス',
    'downloadBasicPauseNote': '一時停止は基本機能です。再開時に再ダウンロードされる場合があります。',
    'downloadKindDirectFile': '直接ファイル',
    'downloadKindHls': 'HLS / m3u8',
    'downloadKindBt': 'BT プレースホルダー',
    'downloadKindUnknown': '不明な種類',
    'downloadFailureUnsupportedType': '未対応の種類',
    'downloadFailurePermissionDenied': '権限がありません',
    'downloadFailureNetworkError': 'ネットワークエラー',
    'downloadFailureSourceUnavailable': 'ソースを利用できません',
    'downloadFailureInvalidUrl': 'URL が無効です',
    'downloadFailureInvalidManifest': 'm3u8 が無効です',
    'downloadFailureStorageUnavailable': 'ストレージを利用できません',
    'downloadFailureUnknown': '不明なエラー',
    'playback': '再生',
    'sourceSettings': 'ソース設定',
    'sourceSettingsSubtitle': 'Sakura Anime を既定ソースとして使用し、可用性に応じて切り替えられます',
    'danmakuSettings': '弾幕設定',
    'appearance': '外観',
    'system': 'システム',
    'light': 'ライト',
    'dark': 'ダーク',
    'about': '情報',
    'aboutAniDestiny': 'AniDestiny',
    'appVersionPrefix': '非営利の学習プロジェクト · v',
    'appDescription': 'クロスプラットフォームのアニメ検索・再生アプリです。',
    'supportedPlatforms': '対応プラットフォーム',
    'supportedPlatformsValue': 'Android / Windows / macOS',
    'sourceStatus': 'ソース状態',
    'sourceStatusValue':
        'Sakura ソースは上流サイトの可用性に依存します。解析結果が不安定な場合は、後で再試行するか別のソースに切り替えてください。',
    'danmakuAbout': '弾幕',
    'danmakuAboutValue': '弹弹play は任意連携です。利用できない場合は fallback を使用します。',
    'copyDiagnostics': '診断情報をコピー',
    'diagnosticsCopied': '診断情報をコピーしました',
    'diagnosticsCopyFailed': '診断情報のコピーに失敗しました',
    'diagnosticsPrivacyNote': '機密値を含まないフィードバック概要を生成します。',
    'reportIssue': '問題を報告',
    'githubRepository': 'GitHub リポジトリ',
    'openSource': 'オープンソース',
    'releasePage': 'リリース',
    'runtimeDiagnostics': '実行診断',
    'runtimeDiagnosticsSubtitle': 'Debug モード限定のフィードバック用概要です。機密値は表示しません。',
    'platform': 'プラットフォーム',
    'currentSource': '現在のソース',
    'currentSourceId': '現在のソース ID',
    'latestSourceDiagnostics': '最近のソース診断',
    'playbackDiagnosticsSummary': '再生診断の概要',
    'sourceFallbackPlayerNotice':
        '選択していたソース {requestedSource} は一時的に利用できないため、現在は {activeSource} の代替データで再生しています。',
    'playbackDiagnosticsDebugHint':
        'プレイヤー画面の Debug ボタンで現在のライン、URL 種類、header keys を確認できます。',
    'sourceTemporarilyUnavailable': 'ソースが一時的に利用できません',
    'sourceUnavailableSuggestion':
        '上流ソースが変更されたか、一時的に利用できません。別のソースを試すか、後で再試行してください。',
    'noPlayableSourceFound': '再生可能なソースが見つかりません。別のソースを試すか、後で再試行してください。',
    'playbackFailedSuggestion': '再生に一時的に失敗しました。後で再試行するか、別の再生ラインを試してください。',
    'sources': 'ソース',
    'loadingCurrentSource': '現在のソースを読み込み中',
    'sourceSetTo': 'ソースを切り替えました:',
    'sourceV1Note':
        'Sakura Anime が現在の既定ソースです。上流サイトの変更で解析に影響が出た場合は、別のソースに切り替えるか後でもう一度お試しください。',
    'sourceCurrent': '現在使用中',
    'sourceDefaultBadge': '既定ソース',
    'sourceDiagnostics': 'ソース診断',
    'sourceDiagnosticsSubtitle': '最近のソース要求と解析状態を確認します。',
    'sourceDiagnosticsEmpty': '診断記録はありません',
    'sourceDiagnosticsClear': 'クリア',
    'sourceFallbackNotice': '現在のソースは一時的に利用できません。代替データを表示しています。',
    'sourceHealth': 'ソース健康状態',
    'sourceHealthHealthy': 'Healthy',
    'sourceHealthDegraded': 'Degraded',
    'sourceHealthUnavailable': 'Unavailable',
    'sourceFailureCount': '失敗回数',
    'sourceLastError': '最近の問題',
    'sourceResetStatus': '状態をリセット',
    'sourceStatusReset': 'ソース状態をリセットしました',
    'sourceFallbackEvents': '最近の fallback イベント',
    'sourceFallbackEventsEmpty': 'fallback イベントはありません',
    'danmaku': '弾幕',
    'danmakuStatusLoading': '弾幕: 読み込み中',
    'danmakuStatusDandanplay': '弾幕: 弹弹play',
    'danmakuStatusFallback': '弾幕: fallback',
    'danmakuStatusEmpty': '弾幕: 空',
    'danmakuStatusUnavailable': '弾幕は利用できません',
    'danmakuStatusAvailable': '弾幕: 利用可能',
    'enabled': '有効',
    'opacity': '不透明度',
    'fontSize': '文字サイズ',
    'speed': '速度',
    'pending': '待機中',
    'preparing': '準備中',
    'downloading': 'ダウンロード中',
    'paused': '一時停止中',
    'completed': '完了',
    'failed': '失敗',
    'canceled': 'キャンセル済み',
    'unsupported': '未対応',
  },
};
