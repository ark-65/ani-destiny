import '../../../core/error/app_exception.dart';
import '../../../app/l10n/app_localizations.dart';
import '../domain/entities/download_kind.dart';
import '../domain/entities/download_task.dart';

String downloadEntryFeedbackMessage(
  AppLocalizations l10n,
  DownloadKind kind,
) {
  if (kind == DownloadKind.directFile) {
    return l10n.downloadTaskAdded;
  }
  final unsupportedMessage = switch (kind) {
    DownloadKind.hls => l10n.downloadUnsupportedHlsMessage,
    DownloadKind.bt => l10n.downloadUnsupportedBtMessage,
    DownloadKind.unknown => l10n.downloadUnsupportedUnknownMessage,
    DownloadKind.directFile => l10n.downloadTaskAdded,
  };
  return '$unsupportedMessage ${l10n.downloadUnsupportedListReviewNote}';
}

String downloadEntryFeedbackActionLabel(
  AppLocalizations l10n,
  DownloadKind kind,
) {
  return kind == DownloadKind.directFile
      ? l10n.openDownloads
      : l10n.reviewInDownloads;
}

String downloadEntryFeedbackErrorMessage(
  AppLocalizations l10n,
  Object error,
) {
  return downloadActionErrorMessage(l10n, error);
}

String downloadActionErrorMessage(
  AppLocalizations l10n,
  Object error,
) {
  if (error is AppException && error.code != null) {
    final byCode = _downloadActionErrorMessageByCode(l10n, error.code!);
    if (byCode != null) {
      return byCode;
    }
  }
  if (error is AppException &&
      error.message.trim().isNotEmpty &&
      !looksLikeRawDownloadFailureMessage(error.message)) {
    return error.message;
  }
  return l10n.downloadActionFailedMessage;
}

String? _downloadActionErrorMessageByCode(
  AppLocalizations l10n,
  String code,
) {
  return switch (code) {
    'download_network_error' =>
      '${l10n.downloadFailureNetworkError}. ${l10n.downloadActionFailedMessage}',
    'download_busy' => l10n.downloadActionBusyMessage,
    'download_unexpected_error' =>
      '${l10n.downloadFailureUnexpectedError}. ${l10n.downloadActionFailedMessage}',
    'download_storage_unavailable' =>
      '${l10n.downloadFailureStorageUnavailable}. ${l10n.downloadActionFailedMessage}',
    'download_unsupported_type' =>
      '${l10n.downloadFailureUnsupportedType}. ${l10n.downloadActionFailedMessage}',
    'download_not_found' => l10n.downloadActionTaskNotFoundMessage,
    'download_remove_not_allowed' => l10n.downloadActionNotAllowedMessage,
    'download_manual_cleanup_required' =>
      l10n.downloadManualCleanupRequiredError,
    _ => null,
  };
}
