import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/presentation/download_entry_feedback.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct downloads keep the calmer open-downloads action', () {
    const l10n = AppLocalizations(Locale('en'));

    expect(
      downloadEntryFeedbackMessage(l10n, DownloadKind.directFile),
      'Added to Downloads. Open Downloads to start it.',
    );
    expect(
      downloadEntryFeedbackActionLabel(l10n, DownloadKind.directFile),
      'Open Downloads',
    );
  });

  test('unsupported downloads point directly at review in Downloads', () {
    const l10n = AppLocalizations(Locale('en'));

    expect(
      downloadEntryFeedbackMessage(l10n, DownloadKind.hls),
      'This download currently uses an HLS / m3u8 stream, and AniDestiny cannot save that type offline yet. This entry stays in Downloads so you can review it, try another download source, and decide whether to keep or remove it.',
    );
    expect(
      downloadEntryFeedbackActionLabel(l10n, DownloadKind.hls),
      'Review in Downloads',
    );
  });

  test('download action errors keep raw app-exception wrappers out of copy',
      () {
    const l10n = AppLocalizations(Locale('en'));

    expect(
      downloadActionErrorMessage(
        l10n,
        const AppException(
          'AppException: [download_failed] DioException: socket closed',
        ),
      ),
      'AniDestiny could not finish that download action right now. Try again in a moment.',
    );
    expect(
      downloadActionErrorMessage(
        l10n,
        const AppException('The selected download source is unavailable.'),
      ),
      'The selected download source is unavailable.',
    );
  });

  test('download action errors fallback to readable reason for known codes', () {
    const l10n = AppLocalizations(Locale('en'));

    expect(
      downloadActionErrorMessage(
        l10n,
        const AppException(
          'AppException: [download_failed] DioException: socket closed',
          code: 'download_network_error',
        ),
      ),
      '${l10n.downloadFailureNetworkError}. ${l10n.downloadActionFailedMessage}',
    );
    expect(
      downloadActionErrorMessage(
        l10n,
        const AppException(
          'AppException: [download_failed] file write error',
          code: 'download_storage_unavailable',
        ),
      ),
      '${l10n.downloadFailureStorageUnavailable}. ${l10n.downloadActionFailedMessage}',
    );
    expect(
      downloadActionErrorMessage(
        l10n,
        const AppException('unsupported download type', code: 'download_unsupported_type'),
      ),
      '${l10n.downloadFailureUnsupportedType}. ${l10n.downloadActionFailedMessage}',
    );
  });
}
