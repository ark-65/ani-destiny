import 'package:ani_destiny/app/l10n/app_localizations.dart';
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
}

String _sourceLabelForId(String sourceId) {
  return switch (sourceId) {
    'sakura' => 'Sakura Anime',
    'mock' => 'Mock Anime Source',
    'remote-proxy' => 'Remote Source Proxy',
    _ => sourceId,
  };
}
