import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/diagnostics/playback_diagnostic_snapshot_preview.dart';
import 'package:ani_destiny/core/diagnostics/playback_diagnostic_summary.dart';
import 'package:ani_destiny/features/player/domain/services/playback_diagnostics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail entries keep playback context ahead of transport details', () {
    const l10n = AppLocalizations(Locale('en'));
    final entries = buildPlaybackDiagnosticDetailEntries(
      l10n: l10n,
      localeName: 'en',
      diagnostics: PlaybackDiagnostics(
        capturedAt: DateTime.utc(2026, 6, 24, 12, 0),
        animeTitle: 'Anime 1',
        episodeTitle: 'Episode 2',
        selectedAppSourceId: 'remote-proxy',
        sourceId: 'mock',
        requestedSourceId: 'sakura',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
        headerKeys: const ['Referer', 'User-Agent'],
        state: PlaybackDiagnosticState.buffering,
      ),
      sourceLabelForId: _sourceLabelForId,
      includeExactIso: true,
    );

    expect(
      entries.map((entry) => entry.field).toList(growable: false),
      [
        PlaybackDiagnosticDetailField.anime,
        PlaybackDiagnosticDetailField.episode,
        PlaybackDiagnosticDetailField.selectedAppSource,
        PlaybackDiagnosticDetailField.requestedSource,
        PlaybackDiagnosticDetailField.source,
        PlaybackDiagnosticDetailField.sourceStatus,
        PlaybackDiagnosticDetailField.line,
        PlaybackDiagnosticDetailField.state,
        PlaybackDiagnosticDetailField.capturedAt,
        PlaybackDiagnosticDetailField.urlType,
        PlaybackDiagnosticDetailField.url,
        PlaybackDiagnosticDetailField.headers,
      ],
    );
    expect(entries[2].value, 'Remote Source Proxy');
    expect(entries[3].value, 'Sakura Anime');
    expect(entries[4].value, 'Mock Anime Source');
  });

  test('detail entries hide redundant selected app source context', () {
    const l10n = AppLocalizations(Locale('en'));
    final entries = buildPlaybackDiagnosticDetailEntries(
      l10n: l10n,
      localeName: 'en',
      diagnostics: PlaybackDiagnostics(
        capturedAt: DateTime.utc(2026, 6, 24, 12, 0),
        animeTitle: 'Anime 1',
        episodeTitle: 'Episode 2',
        selectedAppSourceId: 'sakura',
        sourceId: 'mock',
        requestedSourceId: 'sakura',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
        headerKeys: const ['Referer'],
        state: PlaybackDiagnosticState.buffering,
      ),
      sourceLabelForId: _sourceLabelForId,
    );

    expect(
      entries.any(
        (entry) =>
            entry.field == PlaybackDiagnosticDetailField.selectedAppSource,
      ),
      isFalse,
    );
    expect(
      entries.any(
        (entry) => entry.field == PlaybackDiagnosticDetailField.requestedSource,
      ),
      isTrue,
    );
  });

  test('snapshot preview keeps line separate from the active source', () {
    const l10n = AppLocalizations(Locale('en'));
    final preview = buildPlaybackDiagnosticSnapshotPreview(
      l10n: l10n,
      localeName: 'en',
      diagnostics: PlaybackDiagnostics(
        capturedAt: DateTime.utc(2026, 6, 24, 12, 0),
        animeTitle: 'Anime 1',
        episodeTitle: 'Episode 2',
        selectedAppSourceId: 'remote-proxy',
        sourceId: 'mock',
        requestedSourceId: 'sakura',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
        headerKeys: const ['Referer', 'User-Agent'],
        state: PlaybackDiagnosticState.buffering,
      ),
    );

    expect(
      preview,
      contains('Active playback source: Mock Anime Source\n'),
    );
    expect(preview, contains('Line: Line 1\n'));
    expect(
      preview,
      isNot(contains('Active playback source: Mock Anime Source · Line 1')),
    );
  });

  test('surface detail entries keep only transport details below the preview',
      () {
    const l10n = AppLocalizations(Locale('en'));
    final entries = buildPlaybackDiagnosticRequestDetailEntries(
      l10n: l10n,
      localeName: 'en',
      diagnostics: PlaybackDiagnostics(
        capturedAt: DateTime.utc(2026, 6, 24, 12, 0),
        animeTitle: 'Anime 1',
        episodeTitle: 'Episode 2',
        selectedAppSourceId: 'remote-proxy',
        sourceId: 'mock',
        requestedSourceId: 'sakura',
        playSourceTitle: 'Line 1',
        urlType: 'm3u8',
        sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
        headerKeys: const ['Referer', 'User-Agent'],
        state: PlaybackDiagnosticState.buffering,
      ),
      sourceLabelForId: _sourceLabelForId,
    );

    expect(
      entries.map((entry) => entry.field).toList(growable: false),
      [
        PlaybackDiagnosticDetailField.urlType,
        PlaybackDiagnosticDetailField.url,
        PlaybackDiagnosticDetailField.headers,
      ],
    );
  });

  test('request detail outputs drop low-signal transport placeholders', () {
    const l10n = AppLocalizations(Locale('en'));
    const url = 'https://cdn.example.test/.../episode-2';
    final diagnostics = PlaybackDiagnostics(
      capturedAt: DateTime.utc(2026, 6, 24, 12, 0),
      animeTitle: 'Anime 1',
      episodeTitle: 'Episode 2',
      selectedAppSourceId: 'mock',
      sourceId: 'mock',
      requestedSourceId: null,
      playSourceTitle: 'Line 1',
      urlType: 'unknown',
      sanitizedUrl: url,
      headerKeys: const [],
      state: PlaybackDiagnosticState.ready,
    );

    final entries = buildPlaybackDiagnosticRequestDetailEntries(
      l10n: l10n,
      localeName: 'en',
      diagnostics: diagnostics,
      sourceLabelForId: _sourceLabelForId,
    );
    final summary = buildPlaybackDiagnosticSummary(
      l10n: l10n,
      localeName: 'en',
      diagnostics: diagnostics,
    );

    expect(
      entries.map((entry) => entry.field).toList(growable: false),
      [PlaybackDiagnosticDetailField.url],
    );
    expect(summary, contains('URL: $url'));
    expect(summary, isNot(contains('URL type: unknown')));
    expect(summary, isNot(contains('Request header names')));
  });

  test('shared playback diagnostics drop empty line placeholders', () {
    const l10n = AppLocalizations(Locale('en'));
    final diagnostics = PlaybackDiagnostics(
      capturedAt: DateTime.utc(2026, 6, 24, 12, 0),
      animeTitle: 'Anime 1',
      episodeTitle: 'Episode 2',
      selectedAppSourceId: 'mock',
      sourceId: 'mock',
      requestedSourceId: null,
      playSourceTitle: '   ',
      urlType: 'm3u8',
      sanitizedUrl: 'https://cdn.example.test/.../episode-2.m3u8',
      headerKeys: const ['Referer'],
      state: PlaybackDiagnosticState.ready,
    );

    final entries = buildPlaybackDiagnosticDetailEntries(
      l10n: l10n,
      localeName: 'en',
      diagnostics: diagnostics,
      sourceLabelForId: _sourceLabelForId,
    );
    final summary = buildPlaybackDiagnosticSummary(
      l10n: l10n,
      localeName: 'en',
      diagnostics: diagnostics,
    );
    final preview = buildPlaybackDiagnosticSnapshotPreview(
      l10n: l10n,
      localeName: 'en',
      diagnostics: diagnostics,
    );

    expect(
      entries.any((entry) => entry.field == PlaybackDiagnosticDetailField.line),
      isFalse,
    );
    expect(summary, isNot(contains('Line:')));
    expect(preview, isNot(contains('Line:')));
  });
}

String _sourceLabelForId(String sourceId) {
  return switch (sourceId) {
    'sakura' => 'Sakura Anime',
    'mock' => 'Mock Anime Source',
    'remote-proxy' => 'Remote Source Proxy',
    _ => sourceId,
  };
}
