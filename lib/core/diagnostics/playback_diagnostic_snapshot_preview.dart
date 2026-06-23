import '../../app/l10n/app_localizations.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
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
  final lines = <String>[
    '${l10n.playbackDiagnosticSource}: ${_playbackSourceValue(l10n, diagnostics)}',
  ];

  if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null) {
    lines.add(
      '${l10n.playbackDiagnosticSourceStatus}: ${l10n.sourceFallbackPlayerNotice(
        l10n.sourceDisplayLabel(diagnostics.requestedSourceId!),
        l10n.sourceDisplayLabel(diagnostics.sourceId),
      )}',
    );
  }

  if (diagnostics.divergentSelectedAppSourceId()
      case final selectedAppSourceId?) {
    lines.add(
      '${l10n.playbackDiagnosticSelectedAppSource}: ${l10n.sourceDisplayLabel(selectedAppSourceId)}',
    );
  }

  return lines;
}

String _playbackSourceValue(
  AppLocalizations l10n,
  PlaybackDiagnostics diagnostics,
) {
  final lineTitle = diagnostics.playSourceTitle?.trim();
  final parts = <String>[
    l10n.sourceDisplayLabel(diagnostics.sourceId),
    if (lineTitle != null && lineTitle.isNotEmpty) lineTitle,
  ];
  return parts.join(' · ');
}

String _diagnosticContextValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '-';
  }
  return trimmed;
}
