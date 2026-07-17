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
  final rawMessage = error is AppException
      ? error.message
      : error is String
          ? error
          : null;

  if (rawMessage == null) {
    return l10n.downloadActionFailedMessage;
  }

  final appError = error is AppException;
  if (error is AppException && error.code != null) {
    final byCode = _downloadActionErrorMessageByCode(l10n, error.code!);
    if (byCode != null) {
      return byCode;
    }
  }
  if (!appError) {
    final parsedPlainMessage = _extractDownloadActionErrorCodeAndMessage(rawMessage);
    final plainMessageByCode = parsedPlainMessage?.code == null
        ? null
        : _downloadActionErrorMessageByCode(l10n, parsedPlainMessage!.code!);
    if (plainMessageByCode != null) {
      return plainMessageByCode;
    }
  }
  final parsedError = _extractDownloadActionErrorCodeAndMessage(rawMessage);
  final messageByCode = parsedError?.code == null
      ? null
      : _downloadActionErrorMessageByCode(l10n, parsedError!.code!);
  if (messageByCode != null) {
    return messageByCode;
  }
  final fallbackMessage = parsedError?.message ?? rawMessage;
  if (fallbackMessage.trim().isNotEmpty &&
      !looksLikeRawDownloadFailureMessage(fallbackMessage)) {
    return fallbackMessage;
  }
  return l10n.downloadActionFailedMessage;
}

String? downloadActionErrorCode(Object error) {
  if (error is AppException &&
      error.code != null &&
      error.code!.trim().isNotEmpty) {
    return error.code;
  }

  final rawMessage = error is AppException
      ? error.message
      : error is String
          ? error
          : null;
  if (rawMessage == null) {
    return null;
  }

  return _extractDownloadActionErrorCodeAndMessage(rawMessage)?.code;
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

_DownloadErrorCodeAndMessage? _extractDownloadActionErrorCodeAndMessage(
  String message,
) {
  var trimmed = message.trimLeft();
  if (trimmed.startsWith('AppException')) {
    trimmed = trimmed.substring('AppException'.length).trimLeft();
    if (trimmed.startsWith(':')) {
      trimmed = trimmed.substring(1).trimLeft();
    }
  }
  if (!trimmed.startsWith('[')) {
    final plainCodeMatch = RegExp(r'^(download_[a-zA-Z0-9_]+)\s*:?\s*(.*)$')
        .firstMatch(trimmed);
    if (plainCodeMatch != null) {
      final code = plainCodeMatch.group(1)!;
      final remainder = plainCodeMatch.group(2)!.trim();
      return _DownloadErrorCodeAndMessage(
        code,
        remainder.isEmpty ? null : remainder,
      );
    }
    return null;
  }
  final closingBracket = trimmed.indexOf(']');
  if (closingBracket < 1) {
    return _DownloadErrorCodeAndMessage(null, trimmed);
  }
  final code = trimmed.substring(1, closingBracket).trim();
  final remainder = trimmed.substring(closingBracket + 1).trimLeft();
  return _DownloadErrorCodeAndMessage(
    code.isEmpty ? null : code,
    remainder.isEmpty ? null : remainder,
  );
}

class _DownloadErrorCodeAndMessage {
  const _DownloadErrorCodeAndMessage(this.code, this.message);

  final String? code;
  final String? message;
}
