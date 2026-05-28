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
      _ => fallback,
    };
  }

  String sourceDisplayDescription(String sourceId, String fallback) {
    return switch (sourceId) {
      'mock' => _t('mockSourceDescription'),
      'sakura' => _t('sakuraSourceDescription'),
      'remote-proxy' => _t('remoteProxySourceDescription'),
      _ => fallback,
    };
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
  String get playerMockReady => _t('playerMockReady');
  String get pause => _t('pause');
  String get playbackSpeed => _t('playbackSpeed');
  String get hideDanmaku => _t('hideDanmaku');
  String get showDanmaku => _t('showDanmaku');
  String get fullscreenPlaceholder => _t('fullscreenPlaceholder');
  String get fullscreenNotImplemented => _t('fullscreenNotImplemented');
  String get nextEpisodePlaceholder => _t('nextEpisodePlaceholder');
  String get externalPlayerPlaceholder => _t('externalPlayerPlaceholder');
  String get nextEpisodeNotImplemented => _t('nextEpisodeNotImplemented');
  String get externalPlayerNotImplemented => _t('externalPlayerNotImplemented');
  String get open => _t('open');
  String get loadingFavorites => _t('loadingFavorites');
  String get favoriteEmpty => _t('favoriteEmpty');
  String get removeFavorite => _t('removeFavorite');
  String get loadingHistory => _t('loadingHistory');
  String get historyEmpty => _t('historyEmpty');
  String get deleteHistory => _t('deleteHistory');
  String get loadingDownloads => _t('loadingDownloads');
  String get downloadsEmpty => _t('downloadsEmpty');
  String get mock => _t('mock');
  String mockDownloadTaskCreated(String taskId) =>
      '${_t('mockDownloadTaskCreated')}: $taskId';
  String get start => _t('start');
  String get cancel => _t('cancel');
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
  String get openSource => _t('openSource');
  String get releasePage => _t('releasePage');
  String get sources => _t('sources');
  String get loadingCurrentSource => _t('loadingCurrentSource');
  String sourceSetTo(String sourceId) => '${_t('sourceSetTo')} $sourceId';
  String get sourceV1Note => _t('sourceV1Note');
  String get sourceCurrent => _t('sourceCurrent');
  String get sourceExperimentalBadge => _t('sourceExperimentalBadge');
  String get sourceDiagnostics => _t('sourceDiagnostics');
  String get sourceDiagnosticsSubtitle => _t('sourceDiagnosticsSubtitle');
  String get sourceDiagnosticsEmpty => _t('sourceDiagnosticsEmpty');
  String get sourceDiagnosticsClear => _t('sourceDiagnosticsClear');
  String get danmaku => _t('danmaku');
  String get enabled => _t('enabled');
  String opacityPercent(int percent) => '${_t('opacity')} $percent%';
  String fontSize(int size) => '${_t('fontSize')} $size';
  String speedValue(String value) => '${_t('speed')} ${value}x';
  String get queued => _t('queued');
  String get running => _t('running');
  String get paused => _t('paused');
  String get completed => _t('completed');
  String get failed => _t('failed');
  String get canceled => _t('canceled');
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
    'sakuraSourceDescription':
        'Website parser source. Experimental source. It may fail if the upstream site changes.',
    'remoteProxySourceName': '远程数据源代理',
    'remoteProxySourceDescription': '预留给未来自建代理服务，第一版不强依赖。',
    'sourceLoading': '数据源：加载中',
    'sourceUnknown': '数据源：未知',
    'schedule': '更新时间表',
    'recommendations': '推荐番剧',
    'loadingAnime': '正在加载番剧',
    'noRecommendations': '暂无推荐番剧',
    'searchHint': '番剧标题、标签或关键词',
    'searchEmpty': '搜索 Mock 数据源里的番剧',
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
    'noPlaySource': '暂无播放源。',
    'noDownloadSource': '暂无可下载播放源。',
    'selectPlaySource': '选择播放线路',
    'selectDownloadSource': '选择下载线路',
    'downloadTaskCreated': '已创建下载任务',
    'playerNoPlayUrl': '暂无播放地址',
    'playerMockReady': 'Mock 播放器就绪',
    'pause': '暂停',
    'playbackSpeed': '播放速度',
    'hideDanmaku': '隐藏弹幕',
    'showDanmaku': '显示弹幕',
    'fullscreenPlaceholder': '全屏占位',
    'fullscreenNotImplemented': '全屏暂未实现。',
    'nextEpisodePlaceholder': '下一集占位',
    'externalPlayerPlaceholder': '外部播放器占位',
    'nextEpisodeNotImplemented': '下一集暂未实现。',
    'externalPlayerNotImplemented': '外部播放器暂未实现。',
    'open': '打开',
    'loadingFavorites': '正在加载收藏',
    'favoriteEmpty': '收藏的番剧会显示在这里',
    'removeFavorite': '移除收藏',
    'loadingHistory': '正在加载历史',
    'historyEmpty': '播放历史会显示在这里',
    'deleteHistory': '删除历史',
    'loadingDownloads': '正在加载下载',
    'downloadsEmpty': '下载任务会显示在这里',
    'mock': 'Mock',
    'mockDownloadTaskCreated': '已创建 Mock 下载任务',
    'start': '开始',
    'cancel': '取消',
    'playback': '播放',
    'sourceSettings': '数据源设置',
    'sourceSettingsSubtitle': 'Mock 最稳定，Sakura Anime 可用于实验性真实解析',
    'danmakuSettings': '弹幕设置',
    'appearance': '外观',
    'system': '跟随系统',
    'light': '浅色',
    'dark': '深色',
    'about': '关于',
    'aboutAniDestiny': 'AniDestiny',
    'appVersionPrefix': '非盈利学习项目 · v',
    'openSource': '开源地址',
    'releasePage': '发布地址',
    'sources': '数据源',
    'loadingCurrentSource': '正在加载当前数据源',
    'sourceSetTo': '数据源已切换为',
    'sourceV1Note': 'Mock 数据源最稳定；Sakura Anime 已接入基础解析，但可能受站点结构变化影响。',
    'sourceCurrent': '当前启用',
    'sourceExperimentalBadge': 'Experimental',
    'sourceDiagnostics': '数据源诊断',
    'sourceDiagnosticsSubtitle': '查看最近的数据源请求和解析状态。',
    'sourceDiagnosticsEmpty': '暂无诊断记录',
    'sourceDiagnosticsClear': '清空',
    'danmaku': '弹幕',
    'enabled': '启用',
    'opacity': '不透明度',
    'fontSize': '字号',
    'speed': '速度',
    'queued': '等待中',
    'running': '下载中',
    'paused': '已暂停',
    'completed': '已完成',
    'failed': '失败',
    'canceled': '已取消',
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
        'Website parser source. Experimental source. It may fail if the upstream site changes.',
    'remoteProxySourceName': 'Remote Source Proxy',
    'remoteProxySourceDescription':
        'Future self-hosted proxy adapter. Not required for first version.',
    'sourceLoading': 'Source: loading',
    'sourceUnknown': 'Source: unknown',
    'schedule': 'Schedule',
    'recommendations': 'Recommendations',
    'loadingAnime': 'Loading anime',
    'noRecommendations': 'No recommendations yet',
    'searchHint': 'Anime title, tag, or mood',
    'searchEmpty': 'Search the mock source to find anime',
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
    'noPlaySource': 'No play source available.',
    'noDownloadSource': 'No download source available.',
    'selectPlaySource': 'Select playback line',
    'selectDownloadSource': 'Select download line',
    'downloadTaskCreated': 'Download task created',
    'playerNoPlayUrl': 'No play URL',
    'playerMockReady': 'Mock player ready',
    'pause': 'Pause',
    'playbackSpeed': 'Playback speed',
    'hideDanmaku': 'Hide danmaku',
    'showDanmaku': 'Show danmaku',
    'fullscreenPlaceholder': 'Fullscreen placeholder',
    'fullscreenNotImplemented': 'Fullscreen is not implemented yet.',
    'nextEpisodePlaceholder': 'Next episode placeholder',
    'externalPlayerPlaceholder': 'External player placeholder',
    'nextEpisodeNotImplemented': 'Next episode is not implemented yet.',
    'externalPlayerNotImplemented': 'External player is not implemented yet.',
    'open': 'Open',
    'loadingFavorites': 'Loading favorites',
    'favoriteEmpty': 'Favorite anime will appear here',
    'removeFavorite': 'Remove favorite',
    'loadingHistory': 'Loading history',
    'historyEmpty': 'Playback history will appear here',
    'deleteHistory': 'Delete history',
    'loadingDownloads': 'Loading downloads',
    'downloadsEmpty': 'Download tasks will appear here',
    'mock': 'Mock',
    'mockDownloadTaskCreated': 'Mock download task created',
    'start': 'Start',
    'cancel': 'Cancel',
    'playback': 'Playback',
    'sourceSettings': 'Source settings',
    'sourceSettingsSubtitle':
        'Mock is most stable. Sakura Anime is available as an experimental parser',
    'danmakuSettings': 'Danmaku settings',
    'appearance': 'Appearance',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'about': 'About',
    'aboutAniDestiny': 'AniDestiny',
    'appVersionPrefix': 'Non-profit learning project · v',
    'openSource': 'Open source',
    'releasePage': 'Releases',
    'sources': 'Sources',
    'loadingCurrentSource': 'Loading current source',
    'sourceSetTo': 'Source set to',
    'sourceV1Note':
        'Mock is the most stable source. Sakura Anime has basic parsing, but site changes can still break it.',
    'sourceCurrent': 'Current',
    'sourceExperimentalBadge': 'Experimental',
    'sourceDiagnostics': 'Source diagnostics',
    'sourceDiagnosticsSubtitle':
        'View recent source request and parser status.',
    'sourceDiagnosticsEmpty': 'No diagnostics yet',
    'sourceDiagnosticsClear': 'Clear',
    'danmaku': 'Danmaku',
    'enabled': 'Enabled',
    'opacity': 'Opacity',
    'fontSize': 'Font size',
    'speed': 'Speed',
    'queued': 'Queued',
    'running': 'Running',
    'paused': 'Paused',
    'completed': 'Completed',
    'failed': 'Failed',
    'canceled': 'Canceled',
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
        'Website parser source. Experimental source. It may fail if the upstream site changes.',
    'remoteProxySourceName': 'リモートソースプロキシ',
    'remoteProxySourceDescription': '将来の自前プロキシ用 Adapter です。初版では必須ではありません。',
    'sourceLoading': 'ソース: 読み込み中',
    'sourceUnknown': 'ソース: 不明',
    'schedule': '放送予定',
    'recommendations': 'おすすめ作品',
    'loadingAnime': '作品を読み込み中',
    'noRecommendations': 'おすすめはまだありません',
    'searchHint': '作品名、タグ、キーワード',
    'searchEmpty': 'Mock ソースから作品を検索',
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
    'noPlaySource': '再生ソースがありません。',
    'noDownloadSource': 'ダウンロード可能なソースがありません。',
    'selectPlaySource': '再生ラインを選択',
    'selectDownloadSource': 'ダウンロードラインを選択',
    'downloadTaskCreated': 'ダウンロードタスクを作成しました',
    'playerNoPlayUrl': '再生 URL がありません',
    'playerMockReady': 'Mock プレイヤー準備完了',
    'pause': '一時停止',
    'playbackSpeed': '再生速度',
    'hideDanmaku': '弾幕を隠す',
    'showDanmaku': '弾幕を表示',
    'fullscreenPlaceholder': '全画面プレースホルダー',
    'fullscreenNotImplemented': '全画面はまだ実装されていません。',
    'nextEpisodePlaceholder': '次のエピソード',
    'externalPlayerPlaceholder': '外部プレイヤー',
    'nextEpisodeNotImplemented': '次のエピソードはまだ実装されていません。',
    'externalPlayerNotImplemented': '外部プレイヤーはまだ実装されていません。',
    'open': '開く',
    'loadingFavorites': 'お気に入りを読み込み中',
    'favoriteEmpty': 'お気に入り作品がここに表示されます',
    'removeFavorite': 'お気に入りから削除',
    'loadingHistory': '履歴を読み込み中',
    'historyEmpty': '再生履歴がここに表示されます',
    'deleteHistory': '履歴を削除',
    'loadingDownloads': 'ダウンロードを読み込み中',
    'downloadsEmpty': 'ダウンロードタスクがここに表示されます',
    'mock': 'Mock',
    'mockDownloadTaskCreated': 'Mock ダウンロードタスクを作成しました',
    'start': '開始',
    'cancel': 'キャンセル',
    'playback': '再生',
    'sourceSettings': 'ソース設定',
    'sourceSettingsSubtitle': 'Mock が最も安定しています。Sakura Anime は実験的な解析ソースです',
    'danmakuSettings': '弾幕設定',
    'appearance': '外観',
    'system': 'システム',
    'light': 'ライト',
    'dark': 'ダーク',
    'about': '情報',
    'aboutAniDestiny': 'AniDestiny',
    'appVersionPrefix': '非営利の学習プロジェクト · v',
    'openSource': 'オープンソース',
    'releasePage': 'リリース',
    'sources': 'ソース',
    'loadingCurrentSource': '現在のソースを読み込み中',
    'sourceSetTo': 'ソースを切り替えました:',
    'sourceV1Note':
        'Mock が最も安定しています。Sakura Anime は基本解析に対応しましたが、サイト構造の変更で壊れる可能性があります。',
    'sourceCurrent': '現在使用中',
    'sourceExperimentalBadge': 'Experimental',
    'sourceDiagnostics': 'ソース診断',
    'sourceDiagnosticsSubtitle': '最近のソース要求と解析状態を確認します。',
    'sourceDiagnosticsEmpty': '診断記録はありません',
    'sourceDiagnosticsClear': 'クリア',
    'danmaku': '弾幕',
    'enabled': '有効',
    'opacity': '不透明度',
    'fontSize': '文字サイズ',
    'speed': '速度',
    'queued': '待機中',
    'running': 'ダウンロード中',
    'paused': '一時停止中',
    'completed': '完了',
    'failed': '失敗',
    'canceled': 'キャンセル済み',
  },
};
