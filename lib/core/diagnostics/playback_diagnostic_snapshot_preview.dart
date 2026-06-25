import '../../app/l10n/app_localizations.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
import 'playback_diagnostic_summary.dart';
import 'playback_diagnostic_time_formatter.dart';

String buildPlaybackDiagnosticSnapshotPreview({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
}) {
  final capturedAtLine =
      '${l10n.playbackDiagnosticCapturedAt}: ${formatPlaybackDiagnosticCapturedAt(diagnostics.capturedAt, localeName: localeName)}';
  return l10n.playbackDiagnosticsSnapshotPreview(
    _diagnosticContextValue(diagnostics.animeTitle),
    _diagnosticContextValue(diagnostics.episodeTitle),
    _playbackContextLines(l10n, diagnostics).join('\n'),
    capturedAtLine,
  );
}

List<String> _playbackContextLines(
  AppLocalizations l10n,
  PlaybackDiagnostics diagnostics,
) {
  const previewFields = {
    PlaybackDiagnosticDetailField.source,
    PlaybackDiagnosticDetailField.sourceStatus,
    PlaybackDiagnosticDetailField.selectedAppSource,
    PlaybackDiagnosticDetailField.line,
    PlaybackDiagnosticDetailField.state,
  };

  return buildPlaybackDiagnosticDetailEntries(
    l10n: l10n,
    localeName: l10n.locale.toLanguageTag(),
    diagnostics: diagnostics,
    sourceLabelForId: l10n.sourceDisplayLabel,
  )
      .where((entry) {
        if (!previewFields.contains(entry.field)) {
          return false;
        }
        return entry.field != PlaybackDiagnosticDetailField.line ||
            entry.value != '-';
      })
      .map((entry) => '${entry.label}: ${entry.value}')
      .toList(growable: false);
}

String _diagnosticContextValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '-';
  }
  return trimmed;
}
