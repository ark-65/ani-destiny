import '../../app/l10n/app_localizations.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
import 'playback_diagnostic_time_formatter.dart';

enum PlaybackDiagnosticDetailField {
  anime,
  episode,
  selectedAppSource,
  requestedSource,
  source,
  sourceStatus,
  line,
  state,
  capturedAt,
  urlType,
  url,
  headers,
}

class PlaybackDiagnosticDetailEntry {
  const PlaybackDiagnosticDetailEntry({
    required this.field,
    required this.label,
    required this.value,
  });

  final PlaybackDiagnosticDetailField field;
  final String label;
  final String value;
}

const _requestDetailFields = {
  PlaybackDiagnosticDetailField.urlType,
  PlaybackDiagnosticDetailField.url,
  PlaybackDiagnosticDetailField.headers,
};

String buildPlaybackDiagnosticSummary({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
}) {
  return [
    l10n.playbackDiagnosticsSummary,
    ...buildPlaybackDiagnosticDetailEntries(
      l10n: l10n,
      localeName: localeName,
      diagnostics: diagnostics,
      sourceLabelForId: l10n.sourceDisplayLabel,
      includeExactIso: true,
    ).map((entry) => '${entry.label}: ${entry.value}'),
  ].join('\n');
}

List<PlaybackDiagnosticDetailEntry> buildPlaybackDiagnosticDetailEntries({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
  required String Function(String sourceId) sourceLabelForId,
  bool includeExactIso = false,
}) {
  final lineTitle = diagnostics.playSourceTitle?.trim();
  final headers =
      diagnostics.headerKeys.isEmpty ? '-' : diagnostics.headerKeys.join(', ');
  final selectedAppSourceId = diagnostics.divergentSelectedAppSourceId();
  final lines = <PlaybackDiagnosticDetailEntry>[
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.anime,
      label: l10n.playbackDiagnosticAnime,
      value: _diagnosticContextValue(diagnostics.animeTitle),
    ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.episode,
      label: l10n.playbackDiagnosticEpisode,
      value: _diagnosticContextValue(diagnostics.episodeTitle),
    ),
    if (selectedAppSourceId != null)
      PlaybackDiagnosticDetailEntry(
        field: PlaybackDiagnosticDetailField.selectedAppSource,
        label: l10n.playbackDiagnosticSelectedAppSource,
        value: sourceLabelForId(selectedAppSourceId),
      ),
    if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null)
      PlaybackDiagnosticDetailEntry(
        field: PlaybackDiagnosticDetailField.requestedSource,
        label: l10n.playbackDiagnosticRequestedSource,
        value: sourceLabelForId(diagnostics.requestedSourceId!),
      ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.source,
      label: l10n.playbackDiagnosticSource,
      value: sourceLabelForId(diagnostics.sourceId),
    ),
    if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null)
      PlaybackDiagnosticDetailEntry(
        field: PlaybackDiagnosticDetailField.sourceStatus,
        label: l10n.playbackDiagnosticSourceStatus,
        value: l10n.sourceFallbackPlayerNotice(
          sourceLabelForId(diagnostics.requestedSourceId!),
          sourceLabelForId(diagnostics.sourceId),
        ),
      ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.line,
      label: l10n.playbackDiagnosticLine,
      value: lineTitle == null || lineTitle.isEmpty ? '-' : lineTitle,
    ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.state,
      label: l10n.playbackDiagnosticState,
      value: _playbackDiagnosticStateLabel(l10n, diagnostics.state),
    ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.capturedAt,
      label: l10n.playbackDiagnosticCapturedAt,
      value: formatPlaybackDiagnosticCapturedAt(
        diagnostics.capturedAt,
        localeName: localeName,
        includeExactIso: includeExactIso,
      ),
    ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.urlType,
      label: l10n.playbackDiagnosticUrlType,
      value: diagnostics.urlType,
    ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.url,
      label: l10n.playbackDiagnosticUrl,
      value: diagnostics.sanitizedUrl,
    ),
    PlaybackDiagnosticDetailEntry(
      field: PlaybackDiagnosticDetailField.headers,
      label: l10n.playbackDiagnosticHeaders,
      value: headers,
    ),
  ];

  return lines
      .where(_shouldIncludePlaybackDiagnosticDetailEntry)
      .toList(growable: false);
}

List<String> buildPlaybackDiagnosticDetailLines({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
  required String Function(String sourceId) sourceLabelForId,
  bool includeExactIso = false,
}) {
  return buildPlaybackDiagnosticDetailEntries(
    l10n: l10n,
    localeName: localeName,
    diagnostics: diagnostics,
    sourceLabelForId: sourceLabelForId,
    includeExactIso: includeExactIso,
  ).map((entry) => '${entry.label}: ${entry.value}').toList(growable: false);
}

List<PlaybackDiagnosticDetailEntry>
    buildPlaybackDiagnosticRequestDetailEntries({
  required AppLocalizations l10n,
  required String localeName,
  required PlaybackDiagnostics diagnostics,
  required String Function(String sourceId) sourceLabelForId,
}) {
  return buildPlaybackDiagnosticDetailEntries(
    l10n: l10n,
    localeName: localeName,
    diagnostics: diagnostics,
    sourceLabelForId: sourceLabelForId,
  ).where((entry) => _requestDetailFields.contains(entry.field)).toList(
        growable: false,
      );
}

bool _shouldIncludePlaybackDiagnosticDetailEntry(
  PlaybackDiagnosticDetailEntry entry,
) {
  if (!_requestDetailFields.contains(entry.field)) {
    return true;
  }

  return switch (entry.field) {
    PlaybackDiagnosticDetailField.urlType => entry.value != 'unknown',
    PlaybackDiagnosticDetailField.url =>
      entry.value.trim().isNotEmpty && entry.value != '-',
    PlaybackDiagnosticDetailField.headers => entry.value != '-',
    _ => true,
  };
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
