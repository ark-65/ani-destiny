import '../../app/l10n/app_localizations.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
import 'playback_diagnostic_time_formatter.dart';

String buildPlaybackDiagnosticSummary({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
}) {
  final lineTitle = diagnostics.playSourceTitle?.trim();
  final headers =
      diagnostics.headerKeys.isEmpty ? '-' : diagnostics.headerKeys.join(', ');
  final summary = <String>[
    l10n.playbackDiagnosticsSummary,
    '${l10n.playbackDiagnosticAnime}: '
        '${_diagnosticContextValue(diagnostics.animeTitle)}',
    '${l10n.playbackDiagnosticEpisode}: '
        '${_diagnosticContextValue(diagnostics.episodeTitle)}',
  ];

  if (diagnostics.divergentSelectedAppSourceId()
      case final selectedAppSourceId?) {
    summary.add(
      '${l10n.playbackDiagnosticSelectedAppSource}: '
      '${l10n.sourceDisplayLabel(selectedAppSourceId)}',
    );
  }

  if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null) {
    summary.add(
      '${l10n.playbackDiagnosticRequestedSource}: '
      '${l10n.sourceDisplayLabel(diagnostics.requestedSourceId!)}',
    );
    summary.add(
      '${l10n.playbackDiagnosticSourceStatus}: '
      '${l10n.sourceFallbackPlayerNotice(
        l10n.sourceDisplayLabel(diagnostics.requestedSourceId!),
        l10n.sourceDisplayLabel(diagnostics.sourceId),
      )}',
    );
  }

  summary.addAll([
    '${l10n.playbackDiagnosticCapturedAt}: '
        '${formatPlaybackDiagnosticCapturedAt(
      diagnostics.capturedAt,
      localeName: localeName,
      includeExactIso: true,
    )}',
    '${l10n.playbackDiagnosticSource}: '
        '${l10n.sourceDisplayLabel(diagnostics.sourceId)}',
    '${l10n.playbackDiagnosticLine}: '
        '${lineTitle == null || lineTitle.isEmpty ? '-' : lineTitle}',
    '${l10n.playbackDiagnosticUrlType}: ${diagnostics.urlType}',
    '${l10n.playbackDiagnosticUrl}: ${diagnostics.sanitizedUrl}',
    '${l10n.playbackDiagnosticHeaders}: $headers',
    '${l10n.playbackDiagnosticState}: '
        '${_playbackDiagnosticStateLabel(l10n, diagnostics.state)}',
  ]);

  return summary.join('\n');
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
