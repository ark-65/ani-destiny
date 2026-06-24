import '../../app/l10n/app_localizations.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
import 'playback_diagnostic_time_formatter.dart';

String buildPlaybackDiagnosticSummary({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
}) {
  return [
    l10n.playbackDiagnosticsSummary,
    ...buildPlaybackDiagnosticDetailLines(
      l10n: l10n,
      localeName: localeName,
      diagnostics: diagnostics,
      sourceLabelForId: l10n.sourceDisplayLabel,
      includeExactIso: true,
    ),
  ].join('\n');
}

List<String> buildPlaybackDiagnosticDetailLines({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
  required String Function(String sourceId) sourceLabelForId,
  bool includeExactIso = false,
}) {
  final lineTitle = diagnostics.playSourceTitle?.trim();
  final headers =
      diagnostics.headerKeys.isEmpty ? '-' : diagnostics.headerKeys.join(', ');
  final lines = <String>[
    '${l10n.playbackDiagnosticAnime}: '
        '${_diagnosticContextValue(diagnostics.animeTitle)}',
    '${l10n.playbackDiagnosticEpisode}: '
        '${_diagnosticContextValue(diagnostics.episodeTitle)}',
    '${l10n.playbackDiagnosticSource}: '
        '${sourceLabelForId(diagnostics.sourceId)}',
    '${l10n.playbackDiagnosticLine}: '
        '${lineTitle == null || lineTitle.isEmpty ? '-' : lineTitle}',
    '${l10n.playbackDiagnosticState}: '
        '${_playbackDiagnosticStateLabel(l10n, diagnostics.state)}',
    '${l10n.playbackDiagnosticCapturedAt}: '
        '${formatPlaybackDiagnosticCapturedAt(
      diagnostics.capturedAt,
      localeName: localeName,
      includeExactIso: includeExactIso,
    )}',
  ];

  if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null) {
    lines.add(
      '${l10n.playbackDiagnosticRequestedSource}: '
      '${sourceLabelForId(diagnostics.requestedSourceId!)}',
    );
    lines.add(
      '${l10n.playbackDiagnosticSourceStatus}: '
      '${l10n.sourceFallbackPlayerNotice(
        sourceLabelForId(diagnostics.requestedSourceId!),
        sourceLabelForId(diagnostics.sourceId),
      )}',
    );
  }

  if (diagnostics.divergentSelectedAppSourceId()
      case final selectedAppSourceId?) {
    lines.add(
      '${l10n.playbackDiagnosticSelectedAppSource}: '
      '${sourceLabelForId(selectedAppSourceId)}',
    );
  }

  lines.addAll([
    '${l10n.playbackDiagnosticUrlType}: ${diagnostics.urlType}',
    '${l10n.playbackDiagnosticUrl}: ${diagnostics.sanitizedUrl}',
    '${l10n.playbackDiagnosticHeaders}: $headers',
  ]);

  return lines;
}

String _playbackDiagnosticStateLabel(
  AppLocalizations l10n,
  PlaybackDiagnosticState state,
) {
  return switch (state) {
    PlaybackDiagnosticState.loading => l10n.playbackDiagnosticStateLoading,
    PlaybackDiagnosticState.ready => l10n.playbackDiagnosticStateReady,
    PlaybackDiagnosticState.playing => l10n.playbackDiagnosticStatePlaying,
    PlaybackDiagnosticState.buffering => l10n.playbackDiagnosticStateBuffering,
    PlaybackDiagnosticState.error => l10n.playbackDiagnosticStateError,
  };
}

String _diagnosticContextValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '-';
  }
  return trimmed;
}
