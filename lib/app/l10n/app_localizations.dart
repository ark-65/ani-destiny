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
  String get checkDownloadLines => _t('checkDownloadLines');
  String get downloadSelectionPendingNote => _t('downloadSelectionPendingNote');
  String get downloadTaskWillBeAdded => _t('downloadTaskWillBeAdded');
  String get downloadTaskAdded => _t('downloadTaskAdded');
  String get downloadFocusedTaskNotice => _t('downloadFocusedTaskNotice');
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
  String get playerExitBusyNextEpisode => _t('playerExitBusyNextEpisode');
  String get playerExitBusyExternalPlayer => _t('playerExitBusyExternalPlayer');
  String get playerExitBusyRetryingPlayback =>
      _t('playerExitBusyRetryingPlayback');
  String get externalPlayerPlaceholder => _t('externalPlayerPlaceholder');
  String get nextEpisodeNotImplemented => _t('nextEpisodeNotImplemented');
  String get nextEpisodeUnavailable => _t('nextEpisodeUnavailable');
  String get latestEpisode => _t('latestEpisode');
  String get nextEpisodeStayedOnCurrent => _t('nextEpisodeStayedOnCurrent');
  String externalPlayerHeadersUnsupported(String activeSource) =>
      _t('externalPlayerHeadersUnsupported').replaceFirst(
        '{activeSource}',
        activeSource,
      );
  String externalPlayerOpened(String activeSource) =>
      _t('externalPlayerOpened').replaceFirst('{activeSource}', activeSource);
  String externalPlayerUnavailable(String activeSource) =>
      _t('externalPlayerUnavailable').replaceFirst(
        '{activeSource}',
        activeSource,
      );
  String get externalPlayerNotImplemented => _t('externalPlayerNotImplemented');
  String get playbackDiagnostics => _t('playbackDiagnostics');
  String get playbackDiagnosticAnime => _t('playbackDiagnosticAnime');
  String get playbackDiagnosticEpisode => _t('playbackDiagnosticEpisode');
  String get playbackDiagnosticRequestedSource =>
      _t('playbackDiagnosticRequestedSource');
  String get playbackDiagnosticSource => _t('playbackDiagnosticSource');
  String get playbackDiagnosticSourceStatus =>
      _t('playbackDiagnosticSourceStatus');
  String get playbackDiagnosticLine => _t('playbackDiagnosticLine');
  String get playbackDiagnosticUrlType => _t('playbackDiagnosticUrlType');
  String get playbackDiagnosticUrl => _t('playbackDiagnosticUrl');
  String get playbackDiagnosticHeaders => _t('playbackDiagnosticHeaders');
  String get playbackDiagnosticState => _t('playbackDiagnosticState');
  String get playbackDiagnosticBuffering => _t('playbackDiagnosticBuffering');
  String get playbackDiagnosticBufferingDefault =>
      _t('playbackDiagnosticBufferingDefault');
  String get playbackDiagnosticBufferingStronger =>
      _t('playbackDiagnosticBufferingStronger');
  String get playbackDiagnosticStateLoading =>
      _t('playbackDiagnosticStateLoading');
  String get playbackDiagnosticStateReady => _t('playbackDiagnosticStateReady');
  String get playbackDiagnosticStatePlaying =>
      _t('playbackDiagnosticStatePlaying');
  String get playbackDiagnosticStateBuffering =>
      _t('playbackDiagnosticStateBuffering');
  String get playbackDiagnosticStateError => _t('playbackDiagnosticStateError');
  String get open => _t('open');
  String get openDownloads => _t('openDownloads');
  String get reviewInDownloads => _t('reviewInDownloads');
  String get loadingFavorites => _t('loadingFavorites');
  String get favoriteEmpty => _t('favoriteEmpty');
  String get removeFavorite => _t('removeFavorite');
  String get loadingHistory => _t('loadingHistory');
  String get historyEmpty => _t('historyEmpty');
  String get deleteHistory => _t('deleteHistory');
  String get loadingDownloads => _t('loadingDownloads');
  String get downloadsEmpty => _t('downloadsEmpty');
  String get clearEndedDownloads => _t('clearEndedDownloads');
  String clearEndedDownloadsCount(int count) {
    return switch (_languageCode) {
      'en' => 'Clear $count ended ${count == 1 ? 'task' : 'tasks'} from list',
      'ja' => '一覧から終了済みタスクを $count 件整理',
      _ => '从列表清理 $count 个已结束任务',
    };
  }

  String recheckLeftoverFilesCount(int count) {
    return switch (_languageCode) {
      'en' => 'Check $count leftover ${count == 1 ? 'file' : 'files'} again',
      'ja' => '残留ファイルを $count 件再確認',
      _ => '重新检查 $count 份残留文件',
    };
  }

  String clearEndedDownloadsResult(int count) =>
      '${_t('clearEndedDownloadsResultPrefix')}$count${_t('clearEndedDownloadsResultSuffix')}';
  String clearEndedDownloadsPartialResult(int clearedCount, int failedCount) =>
      '${_t('clearEndedDownloadsPartialResultPrefix')}$clearedCount${_t('clearEndedDownloadsPartialResultMiddle')}$failedCount${_t('clearEndedDownloadsPartialResultSuffix')}';
  String get mock => _t('mock');
  String mockDownloadTaskCreated(String taskId) =>
      '${_t('mockDownloadTaskCreated')}: $taskId';
  String get checkAgain => _t('checkAgain');
  String get start => _t('start');
  String get stopForNow => _t('stopForNow');
  String get downloadDiscardTooltip => _t('downloadDiscardTooltip');
  String get cancel => _t('cancel');
  String get removeFromList => _t('removeFromList');
  String get remove => _t('remove');
  String get downloadProgress => _t('downloadProgress');
  String get downloadPendingNote => _t('downloadPendingNote');
  String get downloadStartingNote => _t('downloadStartingNote');
  String get downloadPreparingNote => _t('downloadPreparingNote');
  String get downloadLocalPath => _t('downloadLocalPath');
  String get downloadRetryingNote => _t('downloadRetryingNote');
  String get downloadStoppingNote => _t('downloadStoppingNote');
  String get downloadStopMayRestartNote => _t('downloadStopMayRestartNote');
  String get downloadPausedRetryNote => _t('downloadPausedRetryNote');
  String get downloadFailedRetryOrRemoveNote =>
      _t('downloadFailedRetryOrRemoveNote');
  String get downloadFailedRetryOrDiscardPartialNote =>
      _t('downloadFailedRetryOrDiscardPartialNote');
  String get downloadDiscardingNote => _t('downloadDiscardingNote');
  String get downloadDiscardedNote => _t('downloadDiscardedNote');
  String get downloadRemovingNote => _t('downloadRemovingNote');
  String get downloadRemovingFailedPartialFileNote =>
      _t('downloadRemovingFailedPartialFileNote');
  String get downloadRemovingListOnlyNote => _t('downloadRemovingListOnlyNote');
  String get downloadUnsupportedRemoveNote =>
      _t('downloadUnsupportedRemoveNote');
  String get downloadUnsupportedListReviewNote =>
      _t('downloadUnsupportedListReviewNote');
  String get downloadDiscardedNeedsManualCleanupNote =>
      _t('downloadDiscardedNeedsManualCleanupNote');
  String get downloadActionFailedMessage => _t('downloadActionFailedMessage');
  String get downloadActionTaskNotFoundMessage =>
      _t('downloadActionTaskNotFoundMessage');
  String get downloadActionNotAllowedMessage =>
      _t('downloadActionNotAllowedMessage');
  String get downloadActionBusyMessage => _t('downloadActionBusyMessage');
  String get downloadFailureUnexpectedError =>
      _t('downloadFailureUnexpectedError');
  String get downloadPageLoadFailedMessage =>
      _t('downloadPageLoadFailedMessage');
  String downloadDiscardedNeedsManualCleanupGuidance({
    String? readyActionLabel,
    bool readyActionIsBatch = false,
    String? recheckActionLabel,
  }) {
    return switch ((
      _languageCode,
      readyActionLabel != null,
      readyActionIsBatch,
      recheckActionLabel != null,
    )) {
      ('en', true, true, true) =>
        'This download was discarded, but AniDestiny could not clear the partial file automatically. You can use "$readyActionLabel" above for the other ended tasks now. For the leftover partial files, remove them from your device if you no longer need them, then use "$recheckActionLabel" above or tap Check again here.',
      ('ja', true, true, true) =>
        'このダウンロードは破棄されましたが、AniDestiny は残留する途中ファイルを自動では削除できませんでした。ほかの終了済みタスクは今すぐ上の「$readyActionLabel」で整理できます。残留ファイルが不要なら端末から削除し、その後は上の「$recheckActionLabel」を使うか、このカードの「もう一度確認」を押してください。',
      (_, true, true, true) =>
        '这个下载已放弃，但 AniDestiny 没能自动清掉残留的未完成文件。上面的“$readyActionLabel”可以先清掉其他已经收尾的任务；这些残留文件如果你不再需要，请先在设备上手动删除，再点上面的“$recheckActionLabel”，或点这里的“重新检查”。',
      ('en', true, false, true) =>
        'This download was discarded, but AniDestiny could not clear the partial file automatically. You can use "$readyActionLabel" on the task that is already ready now. For the leftover partial files, remove them from your device if you no longer need them, then use "$recheckActionLabel" above or tap Check again here.',
      ('ja', true, false, true) =>
        'このダウンロードは破棄されましたが、AniDestiny は残留する途中ファイルを自動では削除できませんでした。すでに整理できるタスクは「$readyActionLabel」で片付けられます。残留ファイルが不要なら端末から削除し、その後は上の「$recheckActionLabel」を使うか、このカードの「もう一度確認」を押してください。',
      (_, true, false, true) =>
        '这个下载已放弃，但 AniDestiny 没能自动清掉残留的未完成文件。已经可以收尾的那条任务，现在可以直接点“$readyActionLabel”；这些残留文件如果你不再需要，请先在设备上手动删除，再点上面的“$recheckActionLabel”，或点这里的“重新检查”。',
      ('en', false, _, true) =>
        'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then use "$recheckActionLabel" above or tap Check again here.',
      ('ja', false, _, true) =>
        'このダウンロードは破棄されましたが、AniDestiny は残留する途中ファイルを自動では削除できませんでした。不要なら下のローカルパスを手がかりに端末から削除し、削除後は上の「$recheckActionLabel」を使うか、このカードの「もう一度確認」を押してください。',
      (_, false, _, true) =>
        '这个下载已放弃，但 AniDestiny 没能自动清掉残留的未完成文件；如果你不再需要它，请按下面的本地路径手动删除。删完后可以先点上面的“$recheckActionLabel”，也可以点这里的“重新检查”。',
      ('en', true, true, false) =>
        'This download was discarded, but AniDestiny could not clear the partial file automatically. You can use "$readyActionLabel" above for the other ended tasks now. For this leftover partial file, remove it from your device if you no longer need it, then return here and tap Check again.',
      ('ja', true, true, false) =>
        'このダウンロードは破棄されましたが、AniDestiny は残留する途中ファイルを自動では削除できませんでした。ほかの終了済みタスクは今すぐ上の「$readyActionLabel」で整理できます。この残留ファイルが不要なら端末から削除し、その後このカードの「もう一度確認」を押してください。',
      (_, true, true, false) =>
        '这个下载已放弃，但 AniDestiny 没能自动清掉残留的未完成文件。上面的“$readyActionLabel”可以先清掉其他已经收尾的任务；这份残留文件如果你不再需要，请先在设备上手动删除，再回来点这里的“重新检查”。',
      ('en', true, false, false) =>
        'This download was discarded, but AniDestiny could not clear the partial file automatically. You can use "$readyActionLabel" on the task that is already ready now. For this leftover partial file, remove it from your device if you no longer need it, then return here and tap Check again.',
      ('ja', true, false, false) =>
        'このダウンロードは破棄されましたが、AniDestiny は残留する途中ファイルを自動では削除できませんでした。すでに整理できるタスクは「$readyActionLabel」で片付けられます。この残留ファイルが不要なら端末から削除し、その後このカードの「もう一度確認」を押してください。',
      (_, true, false, false) =>
        '这个下载已放弃，但 AniDestiny 没能自动清掉残留的未完成文件。已经可以收尾的那条任务，现在可以直接点“$readyActionLabel”；这份残留文件如果你不再需要，请先在设备上手动删除，再回来点这里的“重新检查”。',
      _ => downloadDiscardedNeedsManualCleanupNote,
    };
  }

  String downloadDiscardedNeedsManualCleanupBatchNote(String actionLabel) {
    return downloadDiscardedNeedsManualCleanupGuidance(
      recheckActionLabel: actionLabel,
    );
  }

  String get downloadStartingStatus => _t('downloadStartingStatus');
  String get downloadRetryingStatus => _t('downloadRetryingStatus');
  String get downloadStoppingStatus => _t('downloadStoppingStatus');
  String get downloadDiscardingStatus => _t('downloadDiscardingStatus');
  String get downloadRemovingStatus => _t('downloadRemovingStatus');
  String get downloadDiscardedStatus => _t('downloadDiscardedStatus');
  String get downloadRemoveKeepsFileNote => _t('downloadRemoveKeepsFileNote');
  String get clearEndedDownloadsKeepsFilesNote =>
      _t('clearEndedDownloadsKeepsFilesNote');
  String get clearEndedDownloadsRetainedDiscardedNote =>
      _t('clearEndedDownloadsRetainedDiscardedNote');
  String clearEndedDownloadsRetainedDiscardedClearActionNote(
    String actionLabel,
  ) {
    return switch (_languageCode) {
      'en' =>
        'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. You can use "$actionLabel" above for the other ended tasks now. After you delete that file, return here and tap Check again on this task.',
      'ja' =>
        '「残留ファイルを要整理」と表示されているタスクは、その途中ファイルがなくなるまで一覧に残ります。ほかの終了済みタスクは今すぐ上の「$actionLabel」で整理できます。そのファイルを削除した後、このタスクに戻って「再確認」を押してください。',
      _ =>
        '标成“待清理残留文件”的任务会继续留在列表里，直到这份半截文件已经被手动删掉，或 AniDestiny 成功把它清掉。上面的“$actionLabel”可以先清掉其他已经收尾的任务；删完这份残留后，再回来点这条任务的“重新检查”。',
    };
  }

  String clearEndedDownloadsRetainedDiscardedRemoveActionNote(
    String actionLabel,
  ) {
    return switch (_languageCode) {
      'en' =>
        'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. You can use "$actionLabel" on the task that is already ready now. After you delete that file, return here and tap Check again on this task.',
      'ja' =>
        '「残留ファイルを要整理」と表示されているタスクは、その途中ファイルがなくなるまで一覧に残ります。すでに整理できるタスクは「$actionLabel」で片付けられます。そのファイルを削除した後、このタスクに戻って「再確認」を押してください。',
      _ =>
        '标成“待清理残留文件”的任务会继续留在列表里，直到这份半截文件已经被手动删掉，或 AniDestiny 成功把它清掉。已经可以收尾的那条任务，现在可以直接点“$actionLabel”；删完这份残留后，再回来点这条任务的“重新检查”。',
    };
  }

  String clearEndedDownloadsRetainedDiscardedBatchRecheckNote(
    String actionLabel,
  ) {
    return switch (_languageCode) {
      'en' =>
        'Tasks marked Needs cleanup stay in the list until those leftover partial files are gone. After you delete them, use "$actionLabel" above or tap Check again on each task.',
      'ja' =>
        '「残留ファイルを要整理」と表示されたタスクは、その途中ファイルがなくなるまで一覧に残ります。削除した後は上の「$actionLabel」を使うか、各タスクの「もう一度確認」を押してください。',
      _ =>
        '标成“待清理残留文件”的任务会继续留在列表里，直到这些半截文件已经被手动删掉，或 AniDestiny 成功把它们清掉。删完后可以先点上面的“$actionLabel”，也可以逐条点“重新检查”。',
    };
  }

  String clearEndedDownloadsRetainedDiscardedBatchClearActionNote(
    String clearActionLabel,
    String recheckActionLabel,
  ) {
    return switch (_languageCode) {
      'en' =>
        'Tasks marked Needs cleanup stay in the list until those leftover partial files are gone. You can use "$clearActionLabel" above for the other ended tasks now. After you delete the leftover files, use "$recheckActionLabel" above or tap Check again on each task.',
      'ja' =>
        '「残留ファイルを要整理」と表示されたタスクは、その途中ファイルがなくなるまで一覧に残ります。ほかの終了済みタスクは今すぐ上の「$clearActionLabel」で整理できます。残留ファイルを削除した後は、上の「$recheckActionLabel」を使うか、各タスクの「もう一度確認」を押してください。',
      _ =>
        '标成“待清理残留文件”的任务会继续留在列表里，直到这些半截文件已经被手动删掉，或 AniDestiny 成功把它们清掉。上面的“$clearActionLabel”可以先清掉其他已经收尾的任务；删完这些残留后，再点上面的“$recheckActionLabel”，或逐条点“重新检查”。',
    };
  }

  String clearEndedDownloadsRetainedDiscardedBatchRemoveActionNote(
    String removeActionLabel,
    String recheckActionLabel,
  ) {
    return switch (_languageCode) {
      'en' =>
        'Tasks marked Needs cleanup stay in the list until those leftover partial files are gone. You can use "$removeActionLabel" on the task that is already ready now. After you delete the leftover files, use "$recheckActionLabel" above or tap Check again on each task.',
      'ja' =>
        '「残留ファイルを要整理」と表示されたタスクは、その途中ファイルがなくなるまで一覧に残ります。すでに整理できるタスクは「$removeActionLabel」で片付けられます。残留ファイルを削除した後は、上の「$recheckActionLabel」を使うか、各タスクの「もう一度確認」を押してください。',
      _ =>
        '标成“待清理残留文件”的任务会继续留在列表里，直到这些半截文件已经被手动删掉，或 AniDestiny 成功把它们清掉。已经可以收尾的那条任务，现在可以直接点“$removeActionLabel”；删完这些残留后，再点上面的“$recheckActionLabel”，或逐条点“重新检查”。',
    };
  }

  String get clearEndedDownloadsManualCleanupRemaining =>
      _t('clearEndedDownloadsManualCleanupRemaining');
  String get downloadManualCleanupRequiredError =>
      _t('downloadManualCleanupRequiredError');
  String get downloadManualCleanupRecheckStillNeeded =>
      _t('downloadManualCleanupRecheckStillNeeded');
  String get downloadManualCleanupRecheckCleared =>
      _t('downloadManualCleanupRecheckCleared');
  String downloadManualCleanupFeedbackNextStep({
    String? readyActionLabel,
    bool readyActionIsBatch = false,
    String? recheckActionLabel,
  }) {
    return switch ((
      _languageCode,
      readyActionLabel != null,
      readyActionIsBatch,
      recheckActionLabel != null,
    )) {
      ('en', true, true, true) =>
        'You can use "$readyActionLabel" above for the other ended tasks now. For the leftover partial files, delete them from your device first. Then return to Downloads and use "$recheckActionLabel", or tap Check again on that task.',
      ('ja', true, true, true) =>
        'ほかの終了済みタスクは今すぐ上の「$readyActionLabel」で整理できます。残留ファイルは先に端末から削除し、その後ダウンロード画面に戻って上の「$recheckActionLabel」を使うか、そのタスクの「もう一度確認」を押してください。',
      (_, true, true, true) =>
        '上面的“$readyActionLabel”可以先清掉其他已经收尾的任务；这些残留文件请先在设备上删掉，再回到下载列表点“$recheckActionLabel”，或在对应任务上点“重新检查”。',
      ('en', true, false, true) =>
        'You can use "$readyActionLabel" on the task that is already ready now. For the leftover partial files, delete them from your device first. Then return to Downloads and use "$recheckActionLabel", or tap Check again on that task.',
      ('ja', true, false, true) =>
        'すでに整理できるタスクは「$readyActionLabel」で片付けられます。残留ファイルは先に端末から削除し、その後ダウンロード画面に戻って上の「$recheckActionLabel」を使うか、そのタスクの「もう一度確認」を押してください。',
      (_, true, false, true) =>
        '已经可以收尾的那条任务，现在可以直接点“$readyActionLabel”；这些残留文件请先在设备上删掉，再回到下载列表点“$recheckActionLabel”，或在对应任务上点“重新检查”。',
      ('en', false, _, true) =>
        'Delete the leftover partial file from your device first. Then return to Downloads and use "$recheckActionLabel", or tap Check again on that task.',
      ('ja', false, _, true) =>
        '先にその残留ファイルを端末から削除してから、ダウンロード画面に戻って上の「$recheckActionLabel」を使うか、そのタスクの「もう一度確認」を押してください。',
      (_, false, _, true) =>
        '先在设备上删掉这份残留文件，再回到下载列表点“$recheckActionLabel”，或在对应任务上点“重新检查”。',
      ('en', true, true, false) =>
        'You can use "$readyActionLabel" above for the other ended tasks now. For this leftover partial file, delete it from your device first. Then return to Downloads and tap Check again on that task.',
      ('ja', true, true, false) =>
        'ほかの終了済みタスクは今すぐ上の「$readyActionLabel」で整理できます。この残留ファイルは先に端末から削除し、その後ダウンロード画面に戻ってそのタスクの「もう一度確認」を押してください。',
      (_, true, true, false) =>
        '上面的“$readyActionLabel”可以先清掉其他已经收尾的任务；这份残留文件请先在设备上删掉，再回到下载列表，在对应任务上点“重新检查”。',
      ('en', true, false, false) =>
        'You can use "$readyActionLabel" on the task that is already ready now. For this leftover partial file, delete it from your device first. Then return to Downloads and tap Check again on that task.',
      ('ja', true, false, false) =>
        'すでに整理できるタスクは「$readyActionLabel」で片付けられます。この残留ファイルは先に端末から削除し、その後ダウンロード画面に戻ってそのタスクの「もう一度確認」を押してください。',
      (_, true, false, false) =>
        '已经可以收尾的那条任务，现在可以直接点“$readyActionLabel”；这份残留文件请先在设备上删掉，再回到下载列表，在对应任务上点“重新检查”。',
      ('en', false, _, false) =>
        'Delete the leftover partial file from your device first. Then return to Downloads and tap Check again on that task.',
      ('ja', false, _, false) =>
        '先にその残留ファイルを端末から削除してから、ダウンロード画面に戻ってそのタスクの「もう一度確認」を押してください。',
      _ => '先在设备上删掉这份残留文件，再回到下载列表，在对应任务上点“重新检查”。',
    };
  }

  String downloadManualCleanupRecheckClearedAction(String actionLabel) {
    return switch (_languageCode) {
      'en' =>
        'That leftover partial file is gone. You can use "$actionLabel" above now, or remove this task from the list.',
      'ja' => 'この残留ファイルはもうありません。今なら上の「$actionLabel」を使うか、このタスクを一覧から消せます。',
      _ => '这份残留文件已经不在了。现在可以直接点上面的“$actionLabel”，也可以把这条任务从列表移除。',
    };
  }

  String downloadManualCleanupBulkRecheckStillNeeded(int count) {
    return switch (_languageCode) {
      'en' =>
        'Those $count leftover partial ${count == 1 ? 'file is' : 'files are'} still on your device. Delete ${count == 1 ? 'it' : 'them'} first, then check again.',
      'ja' => 'この $count 件の残留ファイルはまだ端末に残っています。先に削除してから、もう一度確認してください。',
      _ => '这 $count 份残留文件还在。先在设备上删掉它们，再回来重新检查。',
    };
  }

  String downloadManualCleanupBulkRecheckCleared(
    int count, {
    String? actionLabel,
  }) {
    if (actionLabel != null) {
      return switch (_languageCode) {
        'en' =>
          'AniDestiny confirmed that all $count leftover partial ${count == 1 ? 'file is' : 'files are'} gone. You can use "$actionLabel" above now, or remove those tasks one by one.',
        'ja' =>
          'AniDestiny はこの $count 件の残留ファイルがすべてなくなったことを確認しました。今なら上の「$actionLabel」を使うか、対応するタスクを 1 件ずつ一覧から消せます。',
        _ =>
          'AniDestiny 已确认这 $count 份残留文件都不在了。现在可以直接点上面的“$actionLabel”，也可以逐条移除对应任务。',
      };
    }
    return switch (_languageCode) {
      'en' =>
        'AniDestiny confirmed that all $count leftover partial ${count == 1 ? 'file is' : 'files are'} gone. You can remove those tasks from the list now.',
      'ja' =>
        'AniDestiny はこの $count 件の残留ファイルがすべてなくなったことを確認しました。今なら対応するタスクを一覧から消せます。',
      _ => 'AniDestiny 已确认这 $count 份残留文件都不在了。现在可以把对应任务从列表移除了。',
    };
  }

  String downloadManualCleanupBulkRecheckPartial(
    int clearedCount,
    int remainingCount, {
    String? actionLabel,
    String? clearActionLabel,
    String? removeActionLabel,
  }) {
    return switch ((_languageCode, remainingCount > 1 && actionLabel != null)) {
      ('en', true) when removeActionLabel != null =>
        'AniDestiny confirmed that $clearedCount leftover partial ${clearedCount == 1 ? 'file is' : 'files are'} gone. You can use "$removeActionLabel" on the task that is already ready now. $remainingCount still need cleanup. After you delete them, use "$actionLabel" above or tap Check again on each task.',
      ('ja', true) when removeActionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。すでに整理できるタスクは「$removeActionLabel」で片付けられます。まだ $remainingCount 件は整理が必要です。削除したら、上の「$actionLabel」を使うか、各タスクで「もう一度確認」を押してください。',
      (_, true) when removeActionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。已经可以收尾的那条任务，现在可以直接点“$removeActionLabel”；还有 $remainingCount 份仍需清理。删完后可以先点上面的“$actionLabel”，也可以逐条点“重新检查”。',
      ('en', true) =>
        'AniDestiny confirmed that $clearedCount leftover partial ${clearedCount == 1 ? 'file is' : 'files are'} gone. $remainingCount still need cleanup. After you delete them, use "$actionLabel" above or tap Check again on each task.',
      ('ja', true) =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。まだ $remainingCount 件は整理が必要です。削除したら、上の「$actionLabel」を使うか、各タスクで「もう一度確認」を押してください。',
      (_, true) =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了；还有 $remainingCount 份仍需清理。删完后可以先点上面的“$actionLabel”，也可以逐条点“重新检查”。',
      ('en', false) when clearActionLabel != null =>
        'AniDestiny confirmed that $clearedCount leftover partial ${clearedCount == 1 ? 'file is' : 'files are'} gone. You can use "$clearActionLabel" above now to clear the tasks that are ready. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
      ('ja', false) when clearActionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。今なら上の「$clearActionLabel」を使って、先に片付けられるタスクを整理できます。まだ 1 件は整理が必要です。その残留ファイルを削除してから、そのタスクで「もう一度確認」を押してください。',
      (_, false) when clearActionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。现在可以直接点上面的“$clearActionLabel”，先把已经可以收尾的任务清掉；还有 1 份仍需清理。先删掉那份残留文件，再回到对应任务点“重新检查”。',
      ('en', false) when removeActionLabel != null =>
        'AniDestiny confirmed that $clearedCount leftover partial ${clearedCount == 1 ? 'file is' : 'files are'} gone. You can use "$removeActionLabel" on the task that is already ready now. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
      ('ja', false) when removeActionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。すでに整理できるタスクは「$removeActionLabel」で片付けられます。まだ 1 件は整理が必要です。その残留ファイルを削除してから、そのタスクで「もう一度確認」を押してください。',
      (_, false) when removeActionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。已经可以收尾的那条任务，现在可以直接点“$removeActionLabel”；还有 1 份仍需清理。先删掉那份残留文件，再回到对应任务点“重新检查”。',
      ('en', false) =>
        'AniDestiny confirmed that $clearedCount leftover partial ${clearedCount == 1 ? 'file is' : 'files are'} gone. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
      ('ja', false) =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。まだ 1 件は整理が必要です。その残留ファイルを削除してから、そのタスクで「もう一度確認」を押してください。',
      _ =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了；还有 1 份仍需清理。先删掉那份残留文件，再回到对应任务点“重新检查”。',
    };
  }

  String downloadManualCleanupResumeResult(
    int clearedCount,
    int remainingCount, {
    String? actionLabel,
    String? clearActionLabel,
    String? removeActionLabel,
  }) {
    assert(clearedCount > 0);
    return switch ((clearedCount, remainingCount, _languageCode)) {
      (1, 0, 'en') when actionLabel != null =>
        'AniDestiny confirmed that 1 leftover partial file is gone. You can use "$actionLabel" above now, or remove this task from the list.',
      (1, 0, 'ja') when actionLabel != null =>
        'AniDestiny はこの 1 件の残留ファイルがなくなったことを確認しました。今なら上の「$actionLabel」を使うか、このタスクを一覧から消せます。',
      (1, 0, _) when actionLabel != null =>
        'AniDestiny 已确认这 1 份残留文件不在了。现在可以直接点上面的“$actionLabel”，也可以把这条任务从列表移除。',
      (_, 0, 'en') when actionLabel != null =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. You can use "$actionLabel" above now, or remove ${clearedCount == 1 ? 'that task' : 'those tasks'} one by one.',
      (_, 0, 'ja') when actionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。今なら上の「$actionLabel」を使うか、対応するタスクを 1 件ずつ一覧から消せます。',
      (_, 0, _) when actionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。现在可以直接点上面的“$actionLabel”，也可以逐条移除对应任务。',
      (_, 0, 'en') =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. You can remove ${clearedCount == 1 ? 'that task' : 'those tasks'} from the list now.',
      (_, 0, 'ja') =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。今なら対応するタスクを一覧から消せます。',
      (_, _, 'en') when remainingCount > 1 && removeActionLabel != null =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. You can use "$removeActionLabel" on the task that is already ready now. $remainingCount still need cleanup. After you delete them, use "$actionLabel" above or tap Check again on each task.',
      (_, _, 'ja') when remainingCount > 1 && removeActionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。すでに整理できるタスクは「$removeActionLabel」で片付けられます。まだ $remainingCount 件は整理が必要です。削除したら、上の「$actionLabel」を使うか、各タスクで「もう一度確認」を押してください。',
      (_, _, 'en') when remainingCount > 1 && actionLabel != null =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. $remainingCount still need cleanup. After you delete them, use "$actionLabel" above or tap Check again on each task.',
      (_, _, 'ja') when remainingCount > 1 && actionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。まだ $remainingCount 件は整理が必要です。削除したら、上の「$actionLabel」を使うか、各タスクで「もう一度確認」を押してください。',
      (_, _, 'en') when clearActionLabel != null =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. You can use "$clearActionLabel" above now to clear the tasks that are ready. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
      (_, _, 'ja') when clearActionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。今なら上の「$clearActionLabel」を使って、先に片付けられるタスクを整理できます。まだ 1 件は整理が必要です。その残留ファイルを削除してから、そのタスクで「もう一度確認」を押してください。',
      (_, _, 'en') when removeActionLabel != null =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. You can use "$removeActionLabel" on the task that is already ready now. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
      (_, _, 'ja') when removeActionLabel != null =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。すでに整理できるタスクは「$removeActionLabel」で片付けられます。まだ 1 件は整理が必要です。その残留ファイルを削除してから、そのタスクで「もう一度確認」を押してください。',
      (_, _, 'en') =>
        'AniDestiny confirmed that ${clearedCount == 1 ? '1 leftover partial file is' : '$clearedCount leftover partial files are'} gone. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
      (_, _, 'ja') =>
        'AniDestiny は $clearedCount 件の残留ファイルがなくなったことを確認しました。まだ 1 件は整理が必要です。その残留ファイルを削除してから、そのタスクで「もう一度確認」を押してください。',
      (_, 0, _) => 'AniDestiny 已确认有 $clearedCount 份残留文件不在了。现在可以把对应任务从列表移除了。',
      _ when remainingCount > 1 && removeActionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。已经可以收尾的那条任务，现在可以直接点“$removeActionLabel”；还有 $remainingCount 份仍需清理。删完后可以先点上面的“$actionLabel”，也可以逐条点“重新检查”。',
      _ when remainingCount > 1 && actionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了；还有 $remainingCount 份仍需清理。删完后可以先点上面的“$actionLabel”，也可以逐条点“重新检查”。',
      _ when clearActionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。现在可以直接点上面的“$clearActionLabel”，先把已经可以收尾的任务清掉；还有 1 份仍需清理。先删掉那份残留文件，再回到对应任务点“重新检查”。',
      _ when removeActionLabel != null =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了。已经可以收尾的那条任务，现在可以直接点“$removeActionLabel”；还有 1 份仍需清理。先删掉那份残留文件，再回到对应任务点“重新检查”。',
      _ =>
        'AniDestiny 已确认有 $clearedCount 份残留文件不在了；还有 1 份仍需清理。先删掉那份残留文件，再回到对应任务点“重新检查”。',
    };
  }

  String get downloadManualCleanupStatus => _t('downloadManualCleanupStatus');
  String get downloadStoppedStatus => _t('downloadStoppedStatus');
  String get downloadKindDirectFile => _t('downloadKindDirectFile');
  String get downloadKindHls => _t('downloadKindHls');
  String get downloadKindBt => _t('downloadKindBt');
  String get downloadKindUnknown => _t('downloadKindUnknown');
  String get downloadUnsupportedHlsMessage =>
      _t('downloadUnsupportedHlsMessage');
  String get downloadUnsupportedBtMessage => _t('downloadUnsupportedBtMessage');
  String get downloadUnsupportedUnknownMessage =>
      _t('downloadUnsupportedUnknownMessage');
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
  String get forceAheadPlaybackBuffering => _t('forceAheadPlaybackBuffering');
  String get forceAheadPlaybackBufferingSubtitle =>
      _t('forceAheadPlaybackBufferingSubtitle');
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
  String get copyPlaybackDiagnostics => _t('copyPlaybackDiagnostics');
  String get diagnosticsCopied => _t('diagnosticsCopied');
  String get playbackDiagnosticsCopied => _t('playbackDiagnosticsCopied');
  String get diagnosticsCopyFailed => _t('diagnosticsCopyFailed');
  String get diagnosticsPrivacyNote => _t('diagnosticsPrivacyNote');
  String get playbackDiagnosticsPrivacyNote =>
      _t('playbackDiagnosticsPrivacyNote');
  String get copyPlaybackDiagnosticsPendingHint =>
      _t('copyPlaybackDiagnosticsPendingHint');
  String get copyDiagnosticsPlaybackPendingHint =>
      _t('copyDiagnosticsPlaybackPendingHint');
  String get reportIssue => _t('reportIssue');
  String get reportIssueSubtitle => _t('reportIssueSubtitle');
  String get issueReportTitle => _t('issueReportTitle');
  String get issueReportCopied => _t('issueReportCopied');
  String get issueReportCopyFailed => _t('issueReportCopyFailed');
  String get issueReportBodyIntro => _t('issueReportBodyIntro');
  String get issueReportBodyTruncatedNotice =>
      _t('issueReportBodyTruncatedNotice');
  String get githubRepository => _t('githubRepository');
  String get openSource => _t('openSource');
  String get releasePage => _t('releasePage');
  String get runtimeDiagnostics => _t('runtimeDiagnostics');
  String get runtimeDiagnosticsSubtitle => _t('runtimeDiagnosticsSubtitle');
  String get platform => _t('platform');
  String platformDisplayName(String platform) {
    return switch (platform) {
      'android' => _t('platformAndroid'),
      'iOS' => _t('platformIOS'),
      'linux' => _t('platformLinux'),
      'macOS' => _t('platformMacOS'),
      'windows' => _t('platformWindows'),
      'fuchsia' => _t('platformFuchsia'),
      'web' => _t('platformWeb'),
      _ => platform,
    };
  }

  String yesNo(bool value) => value ? _t('yes') : _t('no');
  String get feedbackPackageTitle => _t('feedbackPackageTitle');
  String get feedbackPackageSectionApp => _t('feedbackPackageSectionApp');
  String get feedbackPackageSectionPlatform =>
      _t('feedbackPackageSectionPlatform');
  String get feedbackPackageSectionSource => _t('feedbackPackageSectionSource');
  String get feedbackPackageSectionPlayback =>
      _t('feedbackPackageSectionPlayback');
  String get feedbackPackageSectionDanmaku =>
      _t('feedbackPackageSectionDanmaku');
  String get feedbackPackageSectionDownloads =>
      _t('feedbackPackageSectionDownloads');
  String get feedbackPackageSectionNotes => _t('feedbackPackageSectionNotes');
  String get feedbackPackageName => _t('feedbackPackageName');
  String get feedbackPackageVersion => _t('feedbackPackageVersion');
  String get feedbackPackageGeneratedAt => _t('feedbackPackageGeneratedAt');
  String get feedbackPackageUnavailable => _t('feedbackPackageUnavailable');
  String get feedbackPackageNone => _t('feedbackPackageNone');
  String get feedbackPackageReason => _t('feedbackPackageReason');
  String get feedbackPackageMessage => _t('feedbackPackageMessage');
  String get feedbackPackageTotalTasks => _t('feedbackPackageTotalTasks');
  String get feedbackPackageStatusCounts => _t('feedbackPackageStatusCounts');
  String get feedbackPackageKindCounts => _t('feedbackPackageKindCounts');
  String get feedbackPackageLatestIssue => _t('feedbackPackageLatestIssue');
  String get feedbackPackagePlaybackUnavailable =>
      _t('feedbackPackagePlaybackUnavailable');
  String get feedbackPackageNotesPlaceholder =>
      _t('feedbackPackageNotesPlaceholder');
  String get feedbackPackageDandanplayAppIdConfigured =>
      _t('feedbackPackageDandanplayAppIdConfigured');
  String get feedbackPackageDandanplayAppSecretConfigured =>
      _t('feedbackPackageDandanplayAppSecretConfigured');
  String get feedbackPackageDanmakuFallbackProvider =>
      _t('feedbackPackageDanmakuFallbackProvider');
  String get feedbackPackageAvailable => _t('feedbackPackageAvailable');
  String get selectedAppSource => _t('selectedAppSource');
  String get playbackDiagnosticSelectedAppSource =>
      _t('playbackDiagnosticSelectedAppSource');
  String get currentSource => _t('currentSource');
  String get currentSourceId => _t('currentSourceId');
  String get latestSourceDiagnostics => _t('latestSourceDiagnostics');
  String get playbackDiagnosticsLatestPlayback =>
      _t('playbackDiagnosticsLatestPlayback');
  String get playbackDiagnosticsSummary => _t('playbackDiagnosticsSummary');
  String get playbackDiagnosticsRequestDetails =>
      _t('playbackDiagnosticsRequestDetails');
  String get playbackDiagnosticsRequestDetailsHint =>
      _t('playbackDiagnosticsRequestDetailsHint');
  String get playbackDiagnosticsEmptyHint => _t('playbackDiagnosticsEmptyHint');
  String get playbackDiagnosticsSnapshotHint =>
      _t('playbackDiagnosticsSnapshotHint');
  String playbackDiagnosticsSnapshotPreview(
    String animeTitle,
    String episodeTitle,
    String playbackContext,
    String capturedAt,
  ) {
    final template = _t('playbackDiagnosticsSnapshotPreview');
    return template
        .replaceFirst('{animeTitle}', animeTitle)
        .replaceFirst('{episodeTitle}', episodeTitle)
        .replaceFirst('{playbackContext}', playbackContext)
        .replaceFirst('{capturedAt}', capturedAt);
  }

  String sourceFallbackPlayerNotice(
    String requestedSource,
    String activeSource,
  ) {
    final template = _t('sourceFallbackPlayerNotice');
    return template
        .replaceFirst('{requestedSource}', requestedSource)
        .replaceFirst('{activeSource}', activeSource);
  }

  String sourceFallbackDownloadNotice(
    String requestedSource,
    String activeSource,
  ) {
    final template = _t('sourceFallbackDownloadNotice');
    return template
        .replaceFirst('{requestedSource}', requestedSource)
        .replaceFirst('{activeSource}', activeSource);
  }

  String get playbackDiagnosticCapturedAt => _t('playbackDiagnosticCapturedAt');
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
  String get sourceHealthDegradedHint => _t('sourceHealthDegradedHint');
  String get sourceHealthUnavailableHint => _t('sourceHealthUnavailableHint');
  String sourceFailureCount(int count) => '${_t('sourceFailureCount')}: $count';
  String sourceLastError(String message) =>
      '${_t('sourceLastError')}: $message';
  String get sourceResetStatus => _t('sourceResetStatus');
  String get sourceStatusReset => _t('sourceStatusReset');
  String get sourceFallbackEvents => _t('sourceFallbackEvents');
  String get sourceFallbackEventsEmpty => _t('sourceFallbackEventsEmpty');
  String sourceTransitionLabel(String fromSourceId, String toSourceId) =>
      '${sourceDisplayLabel(fromSourceId)} -> ${sourceDisplayLabel(toSourceId)}';
  String sourceOperationLabel(String operation) {
    final normalizedOperation = operation
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return switch (normalizedOperation) {
      'home' => _t('sourceOperationHome'),
      'search' => _t('sourceOperationSearch'),
      'detail' => _t('sourceOperationDetail'),
      'play' => _t('sourceOperationPlay'),
      'play_sources' => _t('sourceOperationPlaySources'),
      'play_line' => _t('sourceOperationPlaySources'),
      'playline' => _t('sourceOperationPlaySources'),
      'playback_queue' => _t('sourceOperationPlaybackQueue'),
      'schedule' => _t('sourceOperationSchedule'),
      'match' => _t('sourceOperationMatch'),
      'comments' => _t('sourceOperationComments'),
      _ => _t('sourceOperationUnknown'),
    };
  }

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
    'noPlaySource': '未找到可播放线路。请先切换到其他数据源再重试。',
    'noDownloadSource': '未找到可下载线路。请先切换到其他数据源再重试。',
    'selectPlaySource': '选择播放线路',
    'selectDownloadSource': '选择下载线路',
    'checkDownloadLines': '查看下载线路',
    'downloadSelectionPendingNote': '选择这条线路后，会先加入下载列表。',
    'downloadTaskWillBeAdded': '点这里后，会先加入下载列表。',
    'downloadTaskAdded': '已加入下载列表。打开下载列表后再开始。',
    'downloadFocusedTaskNotice': '这里先展示你刚刚加入下载列表的那一条，方便你继续处理。',
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
    'playerExitBusyNextEpisode': '请先等下一集加载完成，再离开当前播放页。',
    'playerExitBusyExternalPlayer': '请先等外部播放器打开完成，再离开当前播放页。',
    'playerExitBusyRetryingPlayback': '请先等这次重试播放完成，再离开当前播放页。',
    'externalPlayerPlaceholder': '外部播放器占位',
    'nextEpisodeNotImplemented': '下一集暂未实现。',
    'nextEpisodeUnavailable': '当前已经是最后一集了。',
    'latestEpisode': '最后一集',
    'nextEpisodeStayedOnCurrent': '下一集暂时无法打开，已保留当前这一集。',
    'externalPlayerHeadersUnsupported':
        '当前这条 {activeSource} 播放暂时只能留在 AniDestiny 内播放，还不能直接交给外部播放器。',
    'externalPlayerOpened': '已在外部播放器中打开 {activeSource} 的播放。',
    'externalPlayerUnavailable':
        '暂时无法把 {activeSource} 的播放交给外部播放器，当前播放会继续留在 AniDestiny。',
    'externalPlayerNotImplemented': '外部播放器暂未实现。',
    'playbackDiagnostics': '播放诊断',
    'playbackDiagnosticAnime': '番剧',
    'playbackDiagnosticEpisode': '剧集',
    'playbackDiagnosticRequestedSource': '所选播放源',
    'playbackDiagnosticSource': '当前播放源',
    'playbackDiagnosticSourceStatus': '播放源状态',
    'playbackDiagnosticLine': '线路',
    'playbackDiagnosticUrlType': 'URL 类型',
    'playbackDiagnosticUrl': 'URL',
    'playbackDiagnosticHeaders': '请求头名称',
    'playbackDiagnosticState': '状态',
    'playbackDiagnosticBuffering': '播放缓存',
    'playbackDiagnosticBufferingDefault': '默认省流量',
    'playbackDiagnosticBufferingStronger': '强化预读',
    'playbackDiagnosticStateLoading': '加载中',
    'playbackDiagnosticStateReady': '就绪',
    'playbackDiagnosticStatePlaying': '播放中',
    'playbackDiagnosticStateBuffering': '缓冲中',
    'playbackDiagnosticStateError': '播放失败',
    'open': '打开',
    'openDownloads': '打开下载列表',
    'reviewInDownloads': '去下载列表查看',
    'loadingFavorites': '正在加载收藏',
    'favoriteEmpty': '收藏的番剧会显示在这里',
    'removeFavorite': '移除收藏',
    'loadingHistory': '正在加载历史',
    'historyEmpty': '播放历史会显示在这里',
    'deleteHistory': '删除历史',
    'loadingDownloads': '正在加载下载',
    'downloadsEmpty': '下载任务会显示在这里',
    'clearEndedDownloads': '从列表清理已结束任务',
    'clearEndedDownloadsResultPrefix': '已从列表清理 ',
    'clearEndedDownloadsResultSuffix': ' 个已结束任务。',
    'clearEndedDownloadsPartialResultPrefix': '已从列表清理 ',
    'clearEndedDownloadsPartialResultMiddle': ' 个已结束任务，',
    'clearEndedDownloadsPartialResultSuffix': ' 个清理失败。',
    'clearEndedDownloadsKeepsFilesNote': '这里只会清掉列表里的已结束任务；已经下载完成的文件会继续保留在设备上。',
    'clearEndedDownloadsRetainedDiscardedNote':
        '标成“待清理残留文件”的任务会继续留在列表里，直到这份半截文件已经被手动删掉，或 AniDestiny 成功把它清掉。删完后回到这里点一下“重新检查”。',
    'clearEndedDownloadsManualCleanupRemaining':
        '标成“待清理残留文件”的任务会继续留在列表里，直到这些半截文件已经被手动删掉，或 AniDestiny 成功把它们清掉。',
    'mock': 'Mock',
    'mockDownloadTaskCreated': '已创建 Mock 下载任务',
    'checkAgain': '重新检查',
    'start': '开始',
    'stopForNow': '先停一下',
    'downloadDiscardTooltip': '放弃这个下载',
    'cancel': '取消',
    'removeFromList': '从列表移除',
    'remove': '移除',
    'downloadProgress': '进度',
    'downloadPendingNote': '这个下载已经准备好开始；等文件真正开始传输后，这里才会显示进度。',
    'downloadStartingNote': 'AniDestiny 正在开始这个下载；等文件真正开始传输后，这里就会显示进度。',
    'downloadPreparingNote': 'AniDestiny 正在为这个下载做开始前准备；等文件真正开始传输后，这里才会显示进度。',
    'downloadLocalPath': '本地路径',
    'downloadRetryingNote': 'AniDestiny 正在重新开始这个下载；等文件真正重新传输后，这里就会显示进度。',
    'downloadStoppingNote':
        'AniDestiny 还在停下这个下载，并清理这次未完成内容；清理完成后，这里会更新成可重试的已停下状态。',
    'downloadStopMayRestartNote':
        '当前下载只能先停下；下次重试时可能会从头开始。放弃这个任务会丢掉未完成内容，并清掉临时文件。',
    'downloadPausedRetryNote':
        '这个下载已先停下；再次开始会按重试处理，可能从头开始。放弃这个任务会丢掉未完成内容，并清掉临时文件。',
    'downloadFailedRetryOrRemoveNote':
        '这个下载这次没能完成；如果你还想继续，可以直接重试。确认不再需要这条记录后，也可以把它从列表移除。',
    'downloadFailedRetryOrDiscardPartialNote':
        '这个下载这次没能完成；如果你不再需要这次失败留下的未完成文件，可以直接放弃这个下载，把这次残局一起清掉。',
    'downloadDiscardingNote': 'AniDestiny 还在放弃这个下载，并清理这次未完成内容；清理完成后，这里会更新最终结果。',
    'downloadDiscardedNote': '这个下载已放弃；未完成内容和临时文件都已清掉。确认无误后，你可以把这条记录从列表移除。',
    'downloadRemovingNote': 'AniDestiny 正在把这条任务从列表移除；这个动作不会改动设备上已有的文件。',
    'downloadRemovingFailedPartialFileNote':
        'AniDestiny 正在移除这条失败的下载记录，并清掉这次失败留下的未完成文件。',
    'downloadRemovingListOnlyNote': 'AniDestiny 正在把这条任务从列表移除，请稍候片刻。',
    'downloadUnsupportedRemoveNote': 'AniDestiny 还不能接管这类下载；确认后可以先把这条任务从列表移除。',
    'downloadUnsupportedListReviewNote':
        '这条记录会留在下载列表，方便你先查看问题，再尝试其他下载源后决定是否移除。',
    'downloadDiscardedNeedsManualCleanupNote':
        '这个下载已放弃，但 AniDestiny 没能自动清掉残留的未完成文件；如果你不再需要它，请按下面的本地路径手动删除，删完后回到这里点一下“重新检查”。',
    'downloadActionFailedMessage': 'AniDestiny 暂时没能完成这一步下载操作；请稍后再试。',
    'downloadActionTaskNotFoundMessage': '该下载任务不存在或已从列表移除，请稍后再试。',
    'downloadActionNotAllowedMessage': '该下载仍在进行中，请先停下后再移除，或稍后再试。',
    'downloadActionBusyMessage': '该下载操作仍在进行中，请稍等后再试。',
    'downloadPageLoadFailedMessage': '下载列表暂时不可用；请稍后再试。',
    'downloadStartingStatus': '正在开始',
    'downloadRetryingStatus': '正在重试',
    'downloadStoppingStatus': '正在停下',
    'downloadDiscardingStatus': '正在放弃',
    'downloadRemovingStatus': '正在移除',
    'downloadDiscardedStatus': '已放弃',
    'downloadRemoveKeepsFileNote': '从列表移除这个任务不会删除已下载文件；文件会继续保留在设备上。',
    'downloadManualCleanupRequiredError':
        'AniDestiny 还没能清掉这份残留文件；请先在设备上手动删除它，之后再把这条任务从列表里移除。',
    'downloadManualCleanupRecheckStillNeeded': '这份残留文件还在。先在设备上删掉它，再回来重新检查。',
    'downloadManualCleanupRecheckCleared': '这份残留文件已经不在了。现在可以把这条任务从列表移除了。',
    'downloadManualCleanupStatus': '待清理残留文件',
    'downloadStoppedStatus': '已停下',
    'downloadKindDirectFile': '直链文件',
    'downloadKindHls': 'HLS / m3u8',
    'downloadKindBt': 'BT / magnet',
    'downloadKindUnknown': '未知类型',
    'downloadUnsupportedHlsMessage':
        '这条下载目前是 HLS / m3u8 流，AniDestiny 还不能直接离线保存这种类型。',
    'downloadUnsupportedBtMessage':
        '这条下载目前是 BT / magnet 链接，AniDestiny 还不能直接处理这种下载。',
    'downloadUnsupportedUnknownMessage': '这条下载链接目前还不是 AniDestiny 能直接保存的类型。',
    'downloadFailureUnsupportedType': '暂不支持该类型',
    'downloadFailurePermissionDenied': '权限不足',
    'downloadFailureNetworkError': '网络错误',
    'downloadFailureUnexpectedError': '下载时发生意外异常',
    'downloadFailureSourceUnavailable': '数据源不可用',
    'downloadFailureInvalidUrl': 'URL 无效',
    'downloadFailureInvalidManifest': 'm3u8 无效',
    'downloadFailureStorageUnavailable': '存储不可用',
    'downloadFailureUnknown': '未知错误',
    'playback': '播放',
    'sourceSettings': '数据源设置',
    'sourceSettingsSubtitle': '默认使用 Sakura Anime，可按可用性切换数据源',
    'danmakuSettings': '弹幕设置',
    'forceAheadPlaybackBuffering': '强化播放缓存',
    'forceAheadPlaybackBufferingSubtitle':
        '开启后会在播放时向前多加载内容，弱网更不容易追上缓存边界，但会消耗更多流量。',
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
    'danmakuAboutValue': '弹弹play 为可选集成；不可用时会改用备用来源。',
    'copyDiagnostics': '复制诊断信息',
    'copyPlaybackDiagnostics': '复制播放诊断',
    'diagnosticsCopied': '诊断信息已复制',
    'playbackDiagnosticsCopied': '播放诊断已复制',
    'diagnosticsCopyFailed': '复制诊断信息失败',
    'diagnosticsPrivacyNote': '将生成已脱敏的反馈摘要，不包含敏感值。',
    'playbackDiagnosticsPrivacyNote': '将复制最近一次播放的已脱敏摘要，不包含敏感值。',
    'copyPlaybackDiagnosticsPendingHint': '先在当前会话里播放一次后，才能复制最近一次播放诊断。',
    'copyDiagnosticsPlaybackPendingHint':
        '将生成已脱敏的反馈摘要；当前还没有播放快照，播放部分会在当前会话先播放一次后补上。',
    'reportIssue': '反馈问题',
    'reportIssueSubtitle': '复制已脱敏诊断并打开预填 GitHub issue；未登录时也可直接粘贴到其他反馈渠道。',
    'issueReportTitle': 'AniDestiny 问题反馈',
    'issueReportCopied': '已复制诊断信息，并打开 GitHub 反馈页。未登录时可直接粘贴到其他反馈渠道。',
    'issueReportCopyFailed': '暂时没能准备反馈报告；请先复制诊断信息后再反馈。',
    'issueReportBodyIntro':
        '下面是 AniDestiny 自动生成的已脱敏诊断摘要。请在提交前补充复现步骤、预期结果和实际结果。',
    'issueReportBodyTruncatedNotice': '诊断摘要较长，已在这里截断；完整内容已复制到剪贴板。',
    'githubRepository': 'GitHub 仓库',
    'openSource': '开源地址',
    'releasePage': '发布地址',
    'runtimeDiagnostics': '运行诊断',
    'runtimeDiagnosticsSubtitle': '用于反馈问题的运行摘要，不展示敏感值。',
    'platform': '平台',
    'platformAndroid': 'Android',
    'platformIOS': 'iOS',
    'platformLinux': 'Linux',
    'platformMacOS': 'macOS',
    'platformWindows': 'Windows',
    'platformFuchsia': 'Fuchsia',
    'platformWeb': 'Web',
    'yes': '是',
    'no': '否',
    'feedbackPackageTitle': 'AniDestiny 反馈摘要',
    'feedbackPackageSectionApp': '应用',
    'feedbackPackageSectionPlatform': '平台',
    'feedbackPackageSectionSource': '数据源',
    'feedbackPackageSectionPlayback': '播放',
    'feedbackPackageSectionDanmaku': '弹幕',
    'feedbackPackageSectionDownloads': '下载',
    'feedbackPackageSectionNotes': '补充说明',
    'feedbackPackageName': '名称',
    'feedbackPackageVersion': '版本',
    'feedbackPackageGeneratedAt': '生成时间',
    'feedbackPackageUnavailable': '暂不可用',
    'feedbackPackageNone': '无',
    'feedbackPackageReason': '原因',
    'feedbackPackageMessage': '说明',
    'feedbackPackageTotalTasks': '任务总数',
    'feedbackPackageStatusCounts': '状态统计',
    'feedbackPackageKindCounts': '任务类型统计',
    'feedbackPackageLatestIssue': '最近问题',
    'feedbackPackagePlaybackUnavailable': '当前会话里还没有采集到播放诊断信息。',
    'feedbackPackageNotesPlaceholder': '提交前可在这里补充稳定复现步骤、预期结果和实际结果。',
    'feedbackPackageDandanplayAppIdConfigured': 'Dandanplay App ID 已配置',
    'feedbackPackageDandanplayAppSecretConfigured': 'Dandanplay 次级凭据已配置',
    'feedbackPackageDanmakuFallbackProvider': '备用提供元',
    'feedbackPackageAvailable': '可用',
    'selectedAppSource': '应用所选数据源',
    'playbackDiagnosticSelectedAppSource': '播放时应用所选数据源',
    'currentSource': '当前数据源',
    'currentSourceId': '当前数据源 ID',
    'latestSourceDiagnostics': '最近数据源诊断',
    'playbackDiagnosticsLatestPlayback': '最近一次播放',
    'playbackDiagnosticsSummary': '播放诊断摘要',
    'playbackDiagnosticsRequestDetails': '播放请求细节',
    'playbackDiagnosticsRequestDetailsHint':
        '下面这些是最近一次播放的已脱敏请求细节，主要用于确认线路和请求是否正常。',
    'playbackDiagnosticsEmptyHint': '当前会话还没有播放快照；先播放一次后，这里会显示最近一次播放现场。',
    'playbackDiagnosticsSnapshotHint':
        '这里展示的是当前会话里捕获的最近一次播放现场；先确认作品、播放源、状态、线路和采集时间。',
    'playbackDiagnosticsSnapshotPreview':
        '{animeTitle} · {episodeTitle}\n{playbackContext}\n{capturedAt}',
    'sourceFallbackPlayerNotice':
        '当前所选数据源 {requestedSource} 暂时不可用，已改用 {activeSource} 继续播放。',
    'sourceFallbackDownloadNotice':
        '当前所选数据源 {requestedSource} 暂时不可用，下面这些下载线路来自 {activeSource}。',
    'playbackDiagnosticCapturedAt': '采集时间',
    'sourceTemporarilyUnavailable': '数据源暂时不可用',
    'sourceUnavailableSuggestion': '上游数据源可能已变化或暂时不可用，请先切换到其他数据源再重试。',
    'noPlayableSourceFound': '未找到可播放线路。请先切换到其他数据源再重试。',
    'playbackFailedSuggestion': '播放暂时失败，请重试或尝试其他播放线路。',
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
    'sourceFallbackNotice':
        '当前数据源暂时不可用，AniDestiny 已改为显示其他数据源的内容。若仍异常，请先切换到其他数据源再重试。',
    'sourceHealth': '数据源健康状态',
    'sourceHealthHealthy': '正常',
    'sourceHealthDegraded': '不稳定',
    'sourceHealthUnavailable': '不可用',
    'sourceHealthDegradedHint': '最近有请求失败；如果浏览或播放持续异常，请稍后重试或切换数据源。',
    'sourceHealthUnavailableHint': '最近请求持续失败；请先切换其他数据源，稍后再回来重试。',
    'sourceFailureCount': '失败次数',
    'sourceLastError': '最近问题',
    'sourceResetStatus': '重置状态',
    'sourceStatusReset': '数据源状态已重置',
    'sourceFallbackEvents': '最近备用切换记录',
    'sourceFallbackEventsEmpty': '暂无备用切换记录',
    'sourceOperationHome': '首页',
    'sourceOperationSearch': '搜索',
    'sourceOperationDetail': '详情',
    'sourceOperationPlay': '播放',
    'sourceOperationPlaySources': '播放线路',
    'sourceOperationPlaybackQueue': '播放队列',
    'sourceOperationSchedule': '时间表',
    'sourceOperationMatch': '匹配',
    'sourceOperationComments': '弹幕',
    'sourceOperationUnknown': '其他操作',
    'danmaku': '弹幕',
    'danmakuStatusLoading': '弹幕：加载中',
    'danmakuStatusDandanplay': '弹幕：弹弹play',
    'danmakuStatusFallback': '弹幕：备用来源',
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
        'No playable source found. Switch to another source before retrying.',
    'noDownloadSource':
        'No downloadable source found. Switch to another source before retrying.',
    'selectPlaySource': 'Select playback line',
    'selectDownloadSource': 'Select download line',
    'checkDownloadLines': 'Check download lines',
    'downloadSelectionPendingNote':
        'Choosing this line adds it to Downloads first.',
    'downloadTaskWillBeAdded': 'This adds it to Downloads first.',
    'downloadTaskAdded': 'Added to Downloads. Open Downloads to start it.',
    'downloadFocusedTaskNotice':
        'Showing the download you just added first so you can keep going.',
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
    'playerExitBusyNextEpisode':
        'Please wait until the next episode finishes loading before leaving.',
    'playerExitBusyExternalPlayer':
        'Please wait until the external player finishes opening before leaving.',
    'playerExitBusyRetryingPlayback':
        'Please wait until playback finishes retrying before leaving.',
    'externalPlayerPlaceholder': 'External player placeholder',
    'nextEpisodeNotImplemented': 'Next episode is not implemented yet.',
    'nextEpisodeUnavailable':
        'You are already on the latest available episode.',
    'latestEpisode': 'Latest episode',
    'nextEpisodeStayedOnCurrent':
        "Couldn't open the next episode. Staying on the current one.",
    'externalPlayerHeadersUnsupported':
        'This {activeSource} playback needs to stay in AniDestiny for now, so it cannot be opened in another player yet.',
    'externalPlayerOpened':
        'Opened {activeSource} playback in your external player.',
    'externalPlayerUnavailable':
        'Could not open {activeSource} playback in your external player. Staying in AniDestiny.',
    'externalPlayerNotImplemented': 'External player is not implemented yet.',
    'playbackDiagnostics': 'Playback diagnostics',
    'playbackDiagnosticAnime': 'Anime',
    'playbackDiagnosticEpisode': 'Episode',
    'playbackDiagnosticRequestedSource': 'Selected playback source',
    'playbackDiagnosticSource': 'Active playback source',
    'playbackDiagnosticSourceStatus': 'Playback source status',
    'playbackDiagnosticLine': 'Line',
    'playbackDiagnosticUrlType': 'URL type',
    'playbackDiagnosticUrl': 'URL',
    'playbackDiagnosticHeaders': 'Request header names',
    'playbackDiagnosticState': 'State',
    'playbackDiagnosticBuffering': 'Playback buffer',
    'playbackDiagnosticBufferingDefault': 'Default data saving',
    'playbackDiagnosticBufferingStronger': 'Stronger preloading',
    'playbackDiagnosticStateLoading': 'Loading',
    'playbackDiagnosticStateReady': 'Ready',
    'playbackDiagnosticStatePlaying': 'Playing',
    'playbackDiagnosticStateBuffering': 'Buffering',
    'playbackDiagnosticStateError': 'Failed',
    'open': 'Open',
    'openDownloads': 'Open Downloads',
    'reviewInDownloads': 'Review in Downloads',
    'loadingFavorites': 'Loading favorites',
    'favoriteEmpty': 'Favorite anime will appear here',
    'removeFavorite': 'Remove favorite',
    'loadingHistory': 'Loading history',
    'historyEmpty': 'Playback history will appear here',
    'deleteHistory': 'Delete history',
    'loadingDownloads': 'Loading downloads',
    'downloadsEmpty': 'Download tasks will appear here',
    'clearEndedDownloads': 'Clear ended tasks from list',
    'clearEndedDownloadsResultPrefix': 'Cleared ',
    'clearEndedDownloadsResultSuffix': ' ended tasks from the list.',
    'clearEndedDownloadsPartialResultPrefix': 'Cleared ',
    'clearEndedDownloadsPartialResultMiddle': ' ended tasks from the list, ',
    'clearEndedDownloadsPartialResultSuffix': ' failed.',
    'clearEndedDownloadsKeepsFilesNote':
        'This only clears ended tasks from the list. Completed files stay on your device.',
    'clearEndedDownloadsRetainedDiscardedNote':
        'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. After you delete it, return here and tap Check again on that task.',
    'clearEndedDownloadsManualCleanupRemaining':
        'Tasks marked Needs cleanup stay visible until those leftover partial files are gone.',
    'mock': 'Mock',
    'mockDownloadTaskCreated': 'Mock download task created',
    'checkAgain': 'Check again',
    'start': 'Start',
    'stopForNow': 'Stop for now',
    'downloadDiscardTooltip': 'Discard download',
    'cancel': 'Cancel',
    'removeFromList': 'Remove from list',
    'remove': 'Remove',
    'downloadProgress': 'Progress',
    'downloadPendingNote':
        'This download is ready to start. AniDestiny will show progress after the file transfer begins.',
    'downloadStartingNote':
        'AniDestiny is starting this download. Progress will appear here after the file transfer begins.',
    'downloadPreparingNote':
        'AniDestiny is preparing this download. Progress will appear here after the file transfer begins.',
    'downloadLocalPath': 'Local path',
    'downloadRetryingNote':
        'AniDestiny is retrying this download. Progress will appear here after the file transfer resumes.',
    'downloadStoppingNote':
        'AniDestiny is still stopping this download and clearing its partial file. This task will show Stopped when that cleanup finishes.',
    'downloadStopMayRestartNote':
        'Stopping this download keeps the task, but the next retry may restart from the beginning. Discarding it clears any partial file.',
    'downloadPausedRetryNote':
        'This download is stopped for now. Retrying may restart it from the beginning. Discarding it clears any partial file.',
    'downloadFailedRetryOrRemoveNote':
        'This download did not finish successfully. You can retry it now, or remove it from the list if you no longer need this record.',
    'downloadFailedRetryOrDiscardPartialNote':
        'This download did not finish successfully. You can retry it now, or discard this download to clear the partial file from this failed attempt.',
    'downloadDiscardingNote':
        'AniDestiny is still discarding this download and clearing its partial file. The final cleanup result will appear here when it finishes.',
    'downloadDiscardedNote':
        'This download was discarded. Any partial file was cleared. You can remove this task from the list when you are done.',
    'downloadRemovingNote':
        'AniDestiny is still removing this task from the list. Any file already on your device will stay there.',
    'downloadRemovingFailedPartialFileNote':
        'AniDestiny is still removing this failed task and clearing its partial file from the device.',
    'downloadRemovingListOnlyNote':
        'AniDestiny is still removing this task from the list. Please give it a moment.',
    'downloadUnsupportedRemoveNote':
        'AniDestiny cannot take over this type of download yet. You can remove this task from the list for now.',
    'downloadUnsupportedListReviewNote':
        'This entry stays in Downloads so you can review it, try another download source, and decide whether to keep or remove it.',
    'downloadDiscardedNeedsManualCleanupNote':
        'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then return here and tap Check again.',
    'downloadActionFailedMessage':
        'AniDestiny could not finish that download action right now. Try again in a moment.',
    'downloadActionTaskNotFoundMessage':
        'This download task was not found or was already removed. Please try again later.',
    'downloadActionNotAllowedMessage':
        'This download is still active. Please stop it first or try again a moment later.',
    'downloadActionBusyMessage':
        'This download action is still in progress. Please try again in a moment.',
    'downloadPageLoadFailedMessage':
        'Downloads are temporarily unavailable. Try again in a moment.',
    'downloadStartingStatus': 'Starting...',
    'downloadRetryingStatus': 'Retrying...',
    'downloadStoppingStatus': 'Stopping...',
    'downloadDiscardingStatus': 'Discarding...',
    'downloadRemovingStatus': 'Removing...',
    'downloadDiscardedStatus': 'Discarded',
    'downloadRemoveKeepsFileNote':
        'Removing this task only clears it from the list. The downloaded file stays on your device.',
    'downloadManualCleanupRequiredError':
        'AniDestiny still could not clear that leftover partial file. Remove it from your device first, then clear this task from the list.',
    'downloadManualCleanupRecheckStillNeeded':
        'That leftover partial file is still on your device. Delete it first, then check again.',
    'downloadManualCleanupRecheckCleared':
        'That leftover partial file is gone. You can remove this task from the list now.',
    'downloadManualCleanupStatus': 'Needs cleanup',
    'downloadStoppedStatus': 'Stopped',
    'downloadKindDirectFile': 'Direct file',
    'downloadKindHls': 'HLS / m3u8',
    'downloadKindBt': 'BT / magnet',
    'downloadKindUnknown': 'Unknown type',
    'downloadUnsupportedHlsMessage':
        'This download currently uses an HLS / m3u8 stream, and AniDestiny cannot save that type offline yet.',
    'downloadUnsupportedBtMessage':
        'This download currently uses a BT / magnet link, and AniDestiny cannot handle that type directly yet.',
    'downloadUnsupportedUnknownMessage':
        'This download link is not a type AniDestiny can save directly yet.',
    'downloadFailureUnsupportedType': 'Unsupported type',
    'downloadFailurePermissionDenied': 'Permission denied',
    'downloadFailureNetworkError': 'Network error',
    'downloadFailureUnexpectedError': 'Unexpected download error',
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
    'forceAheadPlaybackBuffering': 'Stronger playback buffering',
    'forceAheadPlaybackBufferingSubtitle':
        'Loads farther ahead during playback to reduce stalls on slower networks. This can use more data.',
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
        'Dandanplay is optional; a backup provider is used when unavailable.',
    'copyDiagnostics': 'Copy diagnostics',
    'copyPlaybackDiagnostics': 'Copy playback diagnostics',
    'diagnosticsCopied': 'Diagnostics copied',
    'playbackDiagnosticsCopied': 'Playback diagnostics copied',
    'diagnosticsCopyFailed': 'Failed to copy diagnostics',
    'diagnosticsPrivacyNote':
        'Generates a sanitized feedback summary without sensitive values.',
    'playbackDiagnosticsPrivacyNote':
        'Copies a sanitized summary of the latest playback without sensitive values.',
    'copyPlaybackDiagnosticsPendingHint':
        'Start playback once in this session to copy the latest playback diagnostics.',
    'copyDiagnosticsPlaybackPendingHint':
        'A sanitized feedback summary will be copied. The playback section stays unavailable until playback runs once in this session.',
    'reportIssue': 'Report issue',
    'reportIssueSubtitle':
        'Copy sanitized diagnostics and open a prefilled GitHub issue. If GitHub asks you to sign in, paste the report anywhere you contact support.',
    'issueReportTitle': 'AniDestiny issue report',
    'issueReportCopied':
        'Diagnostics copied and GitHub issue page opened. If you are not signed in, paste the report into any support channel.',
    'issueReportCopyFailed':
        'Could not prepare the issue report. Copy diagnostics first, then report the issue.',
    'issueReportBodyIntro':
        'AniDestiny generated the sanitized diagnostics below. Before submitting, add reproduction steps, expected result, and actual result.',
    'issueReportBodyTruncatedNotice':
        'The diagnostics were long, so this issue body was shortened. The full report was copied to the clipboard.',
    'githubRepository': 'GitHub repository',
    'openSource': 'Open source',
    'releasePage': 'Releases',
    'runtimeDiagnostics': 'Runtime diagnostics',
    'runtimeDiagnosticsSubtitle': 'Feedback summary without sensitive values.',
    'platform': 'Platform',
    'platformAndroid': 'Android',
    'platformIOS': 'iOS',
    'platformLinux': 'Linux',
    'platformMacOS': 'macOS',
    'platformWindows': 'Windows',
    'platformFuchsia': 'Fuchsia',
    'platformWeb': 'Web',
    'yes': 'Yes',
    'no': 'No',
    'feedbackPackageTitle': 'AniDestiny Feedback Summary',
    'feedbackPackageSectionApp': 'App',
    'feedbackPackageSectionPlatform': 'Platform',
    'feedbackPackageSectionSource': 'Source',
    'feedbackPackageSectionPlayback': 'Playback',
    'feedbackPackageSectionDanmaku': 'Danmaku',
    'feedbackPackageSectionDownloads': 'Downloads',
    'feedbackPackageSectionNotes': 'Notes',
    'feedbackPackageName': 'Name',
    'feedbackPackageVersion': 'Version',
    'feedbackPackageGeneratedAt': 'Generated at',
    'feedbackPackageUnavailable': 'Unavailable',
    'feedbackPackageNone': 'None',
    'feedbackPackageReason': 'Reason',
    'feedbackPackageMessage': 'Message',
    'feedbackPackageTotalTasks': 'Total tasks',
    'feedbackPackageStatusCounts': 'Status counts',
    'feedbackPackageKindCounts': 'Kind counts',
    'feedbackPackageLatestIssue': 'Latest issue',
    'feedbackPackagePlaybackUnavailable':
        'No playback diagnostics were captured in this session.',
    'feedbackPackageNotesPlaceholder':
        'Add stable reproduction steps, expected behavior, and actual behavior before submitting.',
    'feedbackPackageDandanplayAppIdConfigured': 'Dandanplay App ID configured',
    'feedbackPackageDandanplayAppSecretConfigured':
        'Dandanplay secondary credential configured',
    'feedbackPackageDanmakuFallbackProvider': 'Fallback provider',
    'feedbackPackageAvailable': 'Available',
    'selectedAppSource': 'Selected app source',
    'playbackDiagnosticSelectedAppSource': 'Selected app source at playback',
    'currentSource': 'Current source',
    'currentSourceId': 'Current source ID',
    'latestSourceDiagnostics': 'Latest source diagnostics',
    'playbackDiagnosticsLatestPlayback': 'Latest playback',
    'playbackDiagnosticsSummary': 'Playback diagnostics summary',
    'playbackDiagnosticsRequestDetails': 'Playback request details',
    'playbackDiagnosticsRequestDetailsHint':
        'These sanitized request details help confirm how the latest playback was requested.',
    'playbackDiagnosticsEmptyHint':
        'No playback snapshot has been captured in this session yet. Start playback once and the latest playback moment will appear here.',
    'playbackDiagnosticsSnapshotHint':
        'This is the latest playback snapshot captured in this session. Confirm the title, playback source, state, line, and capture time first.',
    'playbackDiagnosticsSnapshotPreview':
        '{animeTitle} · {episodeTitle}\n{playbackContext}\n{capturedAt}',
    'sourceFallbackPlayerNotice':
        '{requestedSource} is temporarily unavailable. AniDestiny is playing from {activeSource} instead.',
    'sourceFallbackDownloadNotice':
        '{requestedSource} is temporarily unavailable. These download lines are coming from {activeSource} instead.',
    'playbackDiagnosticCapturedAt': 'Captured at',
    'sourceTemporarilyUnavailable': 'Source temporarily unavailable',
    'sourceUnavailableSuggestion':
        'The source changed or is temporarily unavailable. Switch to another source before retrying.',
    'noPlayableSourceFound':
        'No playable source found. Switch to another source before retrying.',
    'playbackFailedSuggestion':
        'Playback temporarily failed. Retry now or try another playback line.',
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
        'The current source is temporarily unavailable. AniDestiny is showing content from another source instead. If this still fails, switch to another source and retry.',
    'sourceHealth': 'Source health',
    'sourceHealthHealthy': 'Healthy',
    'sourceHealthDegraded': 'Degraded',
    'sourceHealthUnavailable': 'Unavailable',
    'sourceHealthDegradedHint':
        'Recent requests failed. Retry later or switch sources if browsing or playback keeps failing.',
    'sourceHealthUnavailableHint':
        'Recent requests keep failing. Switch to another source for now and try this one again later.',
    'sourceFailureCount': 'Failure count',
    'sourceLastError': 'Last issue',
    'sourceResetStatus': 'Reset status',
    'sourceStatusReset': 'Source status reset',
    'sourceFallbackEvents': 'Latest backup switches',
    'sourceFallbackEventsEmpty': 'No backup switch recorded yet',
    'sourceOperationHome': 'Home',
    'sourceOperationSearch': 'Search',
    'sourceOperationDetail': 'Details',
    'sourceOperationPlay': 'Playback',
    'sourceOperationPlaySources': 'Playback lines',
    'sourceOperationPlaybackQueue': 'Playback queue',
    'sourceOperationSchedule': 'Schedule',
    'sourceOperationMatch': 'Matching',
    'sourceOperationComments': 'Danmaku',
    'sourceOperationUnknown': 'Other operation',
    'danmaku': 'Danmaku',
    'danmakuStatusLoading': 'Danmaku: loading',
    'danmakuStatusDandanplay': 'Danmaku: Dandanplay',
    'danmakuStatusFallback': 'Danmaku: backup provider',
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
    'noPlaySource': '再生可能なソースが見つかりません。先に別のソースへ切り替えてから再試行してください。',
    'noDownloadSource': 'ダウンロード可能なソースが見つかりません。先に別のソースへ切り替えてから再試行してください。',
    'selectPlaySource': '再生ラインを選択',
    'selectDownloadSource': 'ダウンロードラインを選択',
    'checkDownloadLines': 'ダウンロードラインを確認',
    'downloadSelectionPendingNote': 'このラインを選ぶと、先にダウンロード一覧へ追加されます。',
    'downloadTaskWillBeAdded': 'ここを押すと、先にダウンロード一覧へ追加されます。',
    'downloadTaskAdded': 'ダウンロード一覧に追加しました。開始するには一覧を開いてください。',
    'downloadFocusedTaskNotice': '今追加したダウンロードを先頭に表示しているので、そのまま続けられます。',
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
    'playerExitBusyNextEpisode': '次のエピソードの読み込みが終わってから戻ってください。',
    'playerExitBusyExternalPlayer': '外部プレイヤーが開き終わってから戻ってください。',
    'playerExitBusyRetryingPlayback': '再生の再試行が終わってから戻ってください。',
    'externalPlayerPlaceholder': '外部プレイヤー',
    'nextEpisodeNotImplemented': '次のエピソードはまだ実装されていません。',
    'nextEpisodeUnavailable': 'すでに最新の配信済みエピソードです。',
    'latestEpisode': '最新話',
    'nextEpisodeStayedOnCurrent': '次のエピソードを開けなかったため、現在のエピソードに留まります。',
    'externalPlayerHeadersUnsupported':
        'この {activeSource} の再生は、いまは AniDestiny 内に留める必要があります。まだ外部プレイヤーには渡せません。',
    'externalPlayerOpened': '外部プレイヤーで {activeSource} の再生を開きました。',
    'externalPlayerUnavailable':
        '{activeSource} の再生を外部プレイヤーで開けませんでした。現在の再生は AniDestiny に残ります。',
    'externalPlayerNotImplemented': '外部プレイヤーはまだ実装されていません。',
    'playbackDiagnostics': '再生診断',
    'playbackDiagnosticAnime': '作品',
    'playbackDiagnosticEpisode': 'エピソード',
    'playbackDiagnosticRequestedSource': '選択した再生ソース',
    'playbackDiagnosticSource': '現在の再生ソース',
    'playbackDiagnosticSourceStatus': '再生ソース状態',
    'playbackDiagnosticLine': 'ライン',
    'playbackDiagnosticUrlType': 'URL 種類',
    'playbackDiagnosticUrl': 'URL',
    'playbackDiagnosticHeaders': 'リクエストヘッダー名',
    'playbackDiagnosticState': '状態',
    'playbackDiagnosticBuffering': '再生バッファ',
    'playbackDiagnosticBufferingDefault': '標準のデータ節約',
    'playbackDiagnosticBufferingStronger': '強化プリロード',
    'playbackDiagnosticStateLoading': '読み込み中',
    'playbackDiagnosticStateReady': '準備完了',
    'playbackDiagnosticStatePlaying': '再生中',
    'playbackDiagnosticStateBuffering': 'バッファ中',
    'playbackDiagnosticStateError': '再生失敗',
    'open': '開く',
    'openDownloads': 'ダウンロード一覧を開く',
    'reviewInDownloads': 'ダウンロード一覧で確認',
    'loadingFavorites': 'お気に入りを読み込み中',
    'favoriteEmpty': 'お気に入り作品がここに表示されます',
    'removeFavorite': 'お気に入りから削除',
    'loadingHistory': '履歴を読み込み中',
    'historyEmpty': '再生履歴がここに表示されます',
    'deleteHistory': '履歴を削除',
    'loadingDownloads': 'ダウンロードを読み込み中',
    'downloadsEmpty': 'ダウンロードタスクがここに表示されます',
    'clearEndedDownloads': '一覧から終了済みタスクを整理',
    'clearEndedDownloadsResultPrefix': '一覧から終了済みタスクを ',
    'clearEndedDownloadsResultSuffix': ' 件整理しました。',
    'clearEndedDownloadsPartialResultPrefix': '一覧から終了済みタスクを ',
    'clearEndedDownloadsPartialResultMiddle': ' 件整理し、',
    'clearEndedDownloadsPartialResultSuffix': ' 件は失敗しました。',
    'clearEndedDownloadsKeepsFilesNote':
        'ここでは一覧上の終了済みタスクだけを整理します。ダウンロード済みのファイルは端末に残ります。',
    'clearEndedDownloadsRetainedDiscardedNote':
        '「残留ファイルを要整理」と表示されているタスクは、その途中ファイルがなくなるまで一覧に残ります。削除したらここに戻って「再確認」を押してください。',
    'clearEndedDownloadsManualCleanupRemaining':
        '「残留ファイルを要整理」と表示されているタスクは、その途中ファイルがなくなるまで一覧に残ります。',
    'mock': 'Mock',
    'mockDownloadTaskCreated': 'Mock ダウンロードタスクを作成しました',
    'checkAgain': '再確認',
    'start': '開始',
    'stopForNow': 'いったん止める',
    'downloadDiscardTooltip': 'このダウンロードを破棄',
    'cancel': 'キャンセル',
    'removeFromList': '一覧から削除',
    'remove': '削除',
    'downloadProgress': '進捗',
    'downloadPendingNote': 'このダウンロードは開始できる状態です。実際に転送が始まってから、ここに進捗を表示します。',
    'downloadStartingNote':
        'AniDestiny はこのダウンロードを開始中です。実際に転送が始まってから、ここに進捗を表示します。',
    'downloadPreparingNote':
        'AniDestiny はこのダウンロードを開始する準備中です。実際に転送が始まってから、ここに進捗を表示します。',
    'downloadLocalPath': 'ローカルパス',
    'downloadRetryingNote':
        'AniDestiny はこのダウンロードを再試行中です。実際に転送が再開してから、ここに進捗を表示します。',
    'downloadStoppingNote':
        'AniDestiny はこのダウンロードをまだ停止中で、未完了ファイルも整理しています。整理が終わると、ここは再試行できる停止状態に切り替わります。',
    'downloadStopMayRestartNote':
        'いったん止めることはできますが、次の再試行では最初からやり直す場合があります。破棄すると未完了の内容と一時ファイルが消えます。',
    'downloadPausedRetryNote':
        'このダウンロードはいったん停止しています。再試行時は最初からやり直す場合があります。破棄すると未完了の内容と一時ファイルが消えます。',
    'downloadFailedRetryOrRemoveNote':
        'このダウンロードは完了できませんでした。続けたい場合は今すぐ再試行でき、もう不要ならこの記録を一覧から削除できます。',
    'downloadFailedRetryOrDiscardPartialNote':
        'このダウンロードは完了できませんでした。続けたい場合は今すぐ再試行でき、不要ならこのダウンロードを破棄して、この失敗で残った途中ファイルも整理できます。',
    'downloadDiscardingNote':
        'AniDestiny はこのダウンロードをまだ破棄中で、未完了ファイルも整理しています。終わったらここに最終結果を表示します。',
    'downloadDiscardedNote':
        'このダウンロードは破棄され、未完了の内容と一時ファイルは削除されました。確認できたら、このタスクを一覧から消せます。',
    'downloadRemovingNote':
        'AniDestiny はこのタスクを一覧からまだ削除中です。この操作で端末上の既存ファイルは変更されません。',
    'downloadRemovingFailedPartialFileNote':
        'AniDestiny はこの失敗したタスクを一覧から削除中で、端末に残った途中ファイルも整理しています。',
    'downloadRemovingListOnlyNote': 'AniDestiny はこのタスクを一覧からまだ削除中です。少しお待ちください。',
    'downloadUnsupportedRemoveNote':
        'AniDestiny はまだこの種類のダウンロードを引き継げません。今はこのタスクを一覧から消せます。',
    'downloadUnsupportedListReviewNote':
        'この記録はダウンロード一覧に残るため、内容を確認し、別のダウンロードソースを試したうえで、保持するか削除するかを決められます。',
    'downloadDiscardedNeedsManualCleanupNote':
        'このダウンロードは破棄されましたが、AniDestiny は未完了ファイルを自動で削除できませんでした。不要なら下のローカルパスをもとに手動で削除し、戻ってきたら「再確認」を押してください。',
    'downloadActionFailedMessage':
        'AniDestiny はこのダウンロード操作を今は完了できませんでした。少し待ってからもう一度お試しください。',
    'downloadActionBusyMessage':
        'このダウンロード操作はまだ進行中です。少し待ってからもう一度お試しください。',
    'downloadPageLoadFailedMessage': 'ダウンロード一覧は一時的に利用できません。少し待ってからもう一度お試しください。',
    'downloadStartingStatus': '開始中...',
    'downloadRetryingStatus': '再試行中...',
    'downloadStoppingStatus': '停止中...',
    'downloadDiscardingStatus': '破棄中',
    'downloadRemovingStatus': '削除中...',
    'downloadDiscardedStatus': '破棄済み',
    'downloadRemoveKeepsFileNote': 'このタスクを一覧から削除しても、ダウンロード済みファイルは端末に残ります。',
    'downloadManualCleanupRequiredError':
        'AniDestiny はこの残留ファイルをまだ削除できませんでした。先に端末上で削除してから、このタスクを一覧から整理してください。',
    'downloadManualCleanupRecheckStillNeeded':
        'この残留ファイルはまだ端末に残っています。先に削除してから、もう一度確認してください。',
    'downloadManualCleanupRecheckCleared':
        'この残留ファイルはもうありません。今ならこのタスクを一覧から消せます。',
    'downloadManualCleanupStatus': '残留ファイルを要整理',
    'downloadStoppedStatus': '停止済み',
    'downloadKindDirectFile': '直接ファイル',
    'downloadKindHls': 'HLS / m3u8',
    'downloadKindBt': 'BT / magnet',
    'downloadKindUnknown': '不明な種類',
    'downloadUnsupportedHlsMessage':
        'このダウンロードは現在 HLS / m3u8 ストリームのため、AniDestiny ではまだこの種類をオフライン保存できません。',
    'downloadUnsupportedBtMessage':
        'このダウンロードは現在 BT / magnet リンクのため、AniDestiny ではまだこの種類を直接処理できません。',
    'downloadUnsupportedUnknownMessage':
        'このダウンロードリンクは、AniDestiny がまだ直接保存できる種類ではありません。',
    'downloadFailureUnsupportedType': '未対応の種類',
    'downloadFailurePermissionDenied': '権限がありません',
    'downloadFailureNetworkError': 'ネットワークエラー',
    'downloadFailureUnexpectedError': 'ダウンロード中に予期しないエラーが発生しました',
    'downloadFailureSourceUnavailable': 'ソースを利用できません',
    'downloadFailureInvalidUrl': 'URL が無効です',
    'downloadFailureInvalidManifest': 'm3u8 が無効です',
    'downloadFailureStorageUnavailable': 'ストレージを利用できません',
    'downloadFailureUnknown': '不明なエラー',
    'playback': '再生',
    'sourceSettings': 'ソース設定',
    'sourceSettingsSubtitle': 'Sakura Anime を既定ソースとして使用し、可用性に応じて切り替えられます',
    'danmakuSettings': '弾幕設定',
    'forceAheadPlaybackBuffering': '再生バッファを強化',
    'forceAheadPlaybackBufferingSubtitle':
        '再生中に先の内容を多めに読み込み、低速回線での停止を減らします。通信量は増える場合があります。',
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
    'danmakuAboutValue': '弹弹play は任意連携です。利用できない場合は代替提供元を使います。',
    'copyDiagnostics': '診断情報をコピー',
    'copyPlaybackDiagnostics': '再生診断をコピー',
    'diagnosticsCopied': '診断情報をコピーしました',
    'playbackDiagnosticsCopied': '再生診断をコピーしました',
    'diagnosticsCopyFailed': '診断情報のコピーに失敗しました',
    'diagnosticsPrivacyNote': '機密値を含まないフィードバック概要を生成します。',
    'playbackDiagnosticsPrivacyNote': '最新の再生を機密値なしで要約した内容をコピーします。',
    'copyPlaybackDiagnosticsPendingHint': 'このセッションで一度再生すると、最新の再生診断をコピーできます。',
    'copyDiagnosticsPlaybackPendingHint':
        '機密値を含まないフィードバック概要をコピーします。このセッションで一度再生するまでは再生欄は利用できません。',
    'reportIssue': '問題を報告',
    'reportIssueSubtitle':
        '診断情報をコピーし、入力済みの GitHub issue を開きます。未ログインの場合は、任意の連絡先に貼り付けてください。',
    'issueReportTitle': 'AniDestiny 問題報告',
    'issueReportCopied':
        '診断情報をコピーし、GitHub の報告ページを開きました。未ログインの場合は任意の連絡先に貼り付けられます。',
    'issueReportCopyFailed': '報告内容を準備できませんでした。先に診断情報をコピーしてから報告してください。',
    'issueReportBodyIntro':
        '以下は AniDestiny が生成した、機密値を含まない診断概要です。送信前に再現手順、期待結果、実際の結果を追記してください。',
    'issueReportBodyTruncatedNotice':
        '診断概要が長いため、ここでは一部のみ表示しています。完全な内容はクリップボードにコピー済みです。',
    'githubRepository': 'GitHub リポジトリ',
    'openSource': 'オープンソース',
    'releasePage': 'リリース',
    'runtimeDiagnostics': '実行診断',
    'runtimeDiagnosticsSubtitle': '不具合報告向けの実行概要です。機密値は表示しません。',
    'platform': 'プラットフォーム',
    'platformAndroid': 'Android',
    'platformIOS': 'iOS',
    'platformLinux': 'Linux',
    'platformMacOS': 'macOS',
    'platformWindows': 'Windows',
    'platformFuchsia': 'Fuchsia',
    'platformWeb': 'Web',
    'yes': 'はい',
    'no': 'いいえ',
    'feedbackPackageTitle': 'AniDestiny フィードバック概要',
    'feedbackPackageSectionApp': 'アプリ',
    'feedbackPackageSectionPlatform': 'プラットフォーム',
    'feedbackPackageSectionSource': 'ソース',
    'feedbackPackageSectionPlayback': '再生',
    'feedbackPackageSectionDanmaku': '弾幕',
    'feedbackPackageSectionDownloads': 'ダウンロード',
    'feedbackPackageSectionNotes': '補足メモ',
    'feedbackPackageName': '名称',
    'feedbackPackageVersion': 'バージョン',
    'feedbackPackageGeneratedAt': '生成時刻',
    'feedbackPackageUnavailable': '利用不可',
    'feedbackPackageNone': 'なし',
    'feedbackPackageReason': '理由',
    'feedbackPackageMessage': 'メモ',
    'feedbackPackageTotalTasks': 'タスク総数',
    'feedbackPackageStatusCounts': '状態ごとの件数',
    'feedbackPackageKindCounts': '種類ごとの件数',
    'feedbackPackageLatestIssue': '直近の問題',
    'feedbackPackagePlaybackUnavailable': 'このセッションでは再生診断情報をまだ取得できていません。',
    'feedbackPackageNotesPlaceholder': '送信前に、安定した再現手順・期待結果・実際の結果をここへ補足してください。',
    'feedbackPackageDandanplayAppIdConfigured': 'Dandanplay App ID 設定済み',
    'feedbackPackageDandanplayAppSecretConfigured': 'Dandanplay 二次認証情報 設定済み',
    'feedbackPackageDanmakuFallbackProvider': '代替提供元',
    'feedbackPackageAvailable': '利用可能',
    'selectedAppSource': '選択中のアプリソース',
    'playbackDiagnosticSelectedAppSource': '再生時のアプリソース',
    'currentSource': '現在のソース',
    'currentSourceId': '現在のソース ID',
    'latestSourceDiagnostics': '最近のソース診断',
    'playbackDiagnosticsLatestPlayback': '最新の再生',
    'playbackDiagnosticsSummary': '再生診断の概要',
    'playbackDiagnosticsRequestDetails': '再生リクエストの詳細',
    'playbackDiagnosticsRequestDetailsHint':
        '以下は最新の再生で使われた、機密値を除いたリクエスト詳細です。ラインやリクエストの状態確認に使えます。',
    'playbackDiagnosticsEmptyHint':
        'このセッションではまだ再生スナップショットがありません。一度再生すると、ここに最新の再生状況が表示されます。',
    'playbackDiagnosticsSnapshotHint':
        'ここには、このセッションで取得した最新の再生状況を表示します。作品名、再生ソース、状態、ライン、取得時刻を先に確認できます。',
    'playbackDiagnosticsSnapshotPreview':
        '{animeTitle} · {episodeTitle}\n{playbackContext}\n{capturedAt}',
    'sourceFallbackPlayerNotice':
        '選択していたソース {requestedSource} は一時的に利用できないため、現在は {activeSource} に切り替えて再生しています。',
    'sourceFallbackDownloadNotice':
        '選択していたソース {requestedSource} は一時的に利用できないため、以下のダウンロードラインは {activeSource} から取得しています。',
    'playbackDiagnosticCapturedAt': '取得時刻',
    'sourceTemporarilyUnavailable': 'ソースが一時的に利用できません',
    'sourceUnavailableSuggestion':
        '上流ソースが変更されたか、一時的に利用できません。先に別のソースへ切り替えてから再試行してください。',
    'noPlayableSourceFound': '再生可能なソースが見つかりません。別のソースに切り替えてから再試行してください。',
    'playbackFailedSuggestion': '再生に一時的に失敗しました。再試行するか、別の再生ラインを試してください。',
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
    'sourceFallbackNotice':
        '現在のソースは一時的に利用できません。AniDestiny は別のソースの内容を表示しています。引き続き問題がある場合は、別のソースに切り替えて再試行してください。',
    'sourceHealth': 'ソース健康状態',
    'sourceHealthHealthy': '正常',
    'sourceHealthDegraded': '不安定',
    'sourceHealthUnavailable': '利用不可',
    'sourceHealthDegradedHint':
        '最近のリクエストに失敗しています。閲覧や再生が不安定なら、時間をおいて再試行するかソースを切り替えてください。',
    'sourceHealthUnavailableHint':
        '最近のリクエストが継続して失敗しています。いったん別のソースへ切り替え、時間をおいてから再試行してください。',
    'sourceFailureCount': '失敗回数',
    'sourceLastError': '最近の問題',
    'sourceResetStatus': '状態をリセット',
    'sourceStatusReset': 'ソース状態をリセットしました',
    'sourceFallbackEvents': '最近の代替切り替え',
    'sourceFallbackEventsEmpty': '代替切り替え履歴はありません',
    'sourceOperationHome': 'ホーム',
    'sourceOperationSearch': '検索',
    'sourceOperationDetail': '詳細',
    'sourceOperationPlay': '再生',
    'sourceOperationPlaySources': '再生ライン',
    'sourceOperationPlaybackQueue': '再生キュー',
    'sourceOperationSchedule': '放送予定',
    'sourceOperationMatch': 'マッチ',
    'sourceOperationComments': '弾幕',
    'sourceOperationUnknown': 'その他の操作',
    'danmaku': '弾幕',
    'danmakuStatusLoading': '弾幕: 読み込み中',
    'danmakuStatusDandanplay': '弾幕: 弹弹play',
    'danmakuStatusFallback': '弾幕: 代替提供元',
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
