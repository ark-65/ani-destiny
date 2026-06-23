import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/diagnostics/diagnostic_sanitizer.dart';
import '../../../../core/diagnostics/playback_diagnostic_snapshot_preview.dart';
import '../../../../core/diagnostics/playback_diagnostic_summary.dart';
import '../../../../core/diagnostics/playback_diagnostic_time_formatter.dart';
import '../../../../core/utils/url_sanitizer.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../danmaku/presentation/providers/danmaku_providers.dart';
import '../../../player/domain/services/playback_diagnostics.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../source/domain/entities/source_diagnostic.dart';
import '../../../source/domain/entities/source_fallback_event.dart';
import '../../../source/domain/entities/source_health.dart';
import '../../../source/presentation/providers/source_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_section.dart';

class RuntimeDiagnosticsPage extends ConsumerWidget {
  const RuntimeDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionLabelProvider);
    final currentSourceId = ref.watch(currentSourceIdProvider).valueOrNull;
    final diagnostics = ref
        .watch(sourceDiagnosticsControllerProvider)
        .toList(growable: false)
        .reversed
        .take(8)
        .toList(growable: false);
    final health = ref.watch(sourceHealthControllerProvider);
    final fallbackEvents = ref
        .watch(sourceFallbackEventsProvider)
        .toList(growable: false)
        .reversed
        .take(6)
        .toList(growable: false);
    final danmakuSettings = ref.watch(danmakuSettingsProvider);
    final playbackDiagnostics = ref.watch(lastPlaybackDiagnosticsProvider);

    return SafeArea(
      child: AdaptivePage(
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.runtimeDiagnostics,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: context.l10n.about,
              children: [
                _DiagnosticTile(
                  label: context.l10n.appVersion(version),
                  value: version,
                  icon: Icons.info_outline,
                ),
                _DiagnosticTile(
                  label: context.l10n.platform,
                  value: context.l10n.platformDisplayName(
                    defaultTargetPlatform.name,
                  ),
                  icon: Icons.devices_outlined,
                ),
                _DiagnosticTile(
                  label: context.l10n.selectedAppSource,
                  value: currentSourceId == null
                      ? '-'
                      : context.l10n.sourceDisplayLabel(currentSourceId),
                  icon: Icons.source_outlined,
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.danmaku,
              children: [
                _DiagnosticTile(
                  label: context.l10n.enabled,
                  value: context.l10n.yesNo(danmakuSettings.enabled),
                  icon: Icons.subtitles_outlined,
                ),
                _DiagnosticTile(
                  label: context.l10n.danmakuAbout,
                  value: context.l10n.danmakuAboutValue,
                  icon: Icons.shield_outlined,
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.playbackDiagnosticsSummary,
              children: [
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(context.l10n.playbackDiagnosticsSummary),
                  subtitle: Text(
                    _playbackSnapshotSubtitle(context, playbackDiagnostics),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add_check_circle_outlined),
                  title: Text(context.l10n.copyPlaybackDiagnostics),
                  subtitle: Text(context.l10n.diagnosticsPrivacyNote),
                  onTap: playbackDiagnostics == null
                      ? null
                      : () => _copyPlaybackDiagnostics(
                            context,
                            playbackDiagnostics,
                          ),
                ),
                ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: Text(context.l10n.copyDiagnostics),
                  subtitle: Text(
                    playbackDiagnostics == null
                        ? context.l10n.copyDiagnosticsPlaybackPendingHint
                        : context.l10n.runtimeDiagnosticsSubtitle,
                  ),
                  onTap: () => _copyDiagnostics(context, ref),
                ),
                if (playbackDiagnostics == null)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(context.l10n.feedbackPackageUnavailable),
                    subtitle: Text(
                      context.l10n.feedbackPackagePlaybackUnavailable,
                    ),
                  )
                else
                  ..._playbackDiagnosticTiles(
                    context,
                    playbackDiagnostics,
                  ),
              ],
            ),
            SettingsSection(
              title: context.l10n.sourceHealth,
              children: health.isEmpty
                  ? [
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(context.l10n.sourceDiagnosticsEmpty),
                      ),
                    ]
                  : health
                      .map((item) => _SourceHealthTile(health: item))
                      .toList(growable: false),
            ),
            SettingsSection(
              title: context.l10n.sourceFallbackEvents,
              children: fallbackEvents.isEmpty
                  ? [
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(context.l10n.sourceFallbackEventsEmpty),
                      ),
                    ]
                  : fallbackEvents
                      .map((item) => _FallbackEventTile(event: item))
                      .toList(growable: false),
            ),
            SettingsSection(
              title: context.l10n.latestSourceDiagnostics,
              children: diagnostics.isEmpty
                  ? [
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(context.l10n.sourceDiagnosticsEmpty),
                      ),
                    ]
                  : diagnostics
                      .map((item) => _SourceDiagnosticTile(diagnostic: item))
                      .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _playbackDiagnosticTiles(
  BuildContext context,
  PlaybackDiagnostics diagnostics,
) {
  final lineTitle = diagnostics.playSourceTitle?.trim();
  final lineValue = lineTitle == null || lineTitle.isEmpty ? '-' : lineTitle;
  final headers =
      diagnostics.headerKeys.isEmpty ? '-' : diagnostics.headerKeys.join(', ');
  final selectedAppSourceId = diagnostics.divergentSelectedAppSourceId();

  return [
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticCapturedAt,
      value: _formatCapturedAt(context, diagnostics.capturedAt),
      icon: Icons.schedule_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticAnime,
      value: _diagnosticContextValue(diagnostics.animeTitle),
      icon: Icons.movie_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticEpisode,
      value: _diagnosticContextValue(diagnostics.episodeTitle),
      icon: Icons.live_tv_outlined,
    ),
    if (selectedAppSourceId != null)
      _DiagnosticTile(
        label: context.l10n.playbackDiagnosticSelectedAppSource,
        value: context.l10n.sourceDisplayLabel(selectedAppSourceId),
        icon: Icons.route_outlined,
      ),
    if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null)
      _DiagnosticTile(
        label: context.l10n.playbackDiagnosticRequestedSource,
        value: context.l10n.sourceDisplayLabel(diagnostics.requestedSourceId!),
        icon: Icons.compare_arrows_outlined,
      ),
    if (diagnostics.usedSourceFallback && diagnostics.requestedSourceId != null)
      _DiagnosticTile(
        label: context.l10n.playbackDiagnosticSourceStatus,
        value: context.l10n.sourceFallbackPlayerNotice(
          context.l10n.sourceDisplayLabel(diagnostics.requestedSourceId!),
          context.l10n.sourceDisplayLabel(diagnostics.sourceId),
        ),
        icon: Icons.swap_horiz_outlined,
      ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticSource,
      value: context.l10n.sourceDisplayLabel(diagnostics.sourceId),
      icon: Icons.source_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticLine,
      value: lineValue,
      icon: Icons.playlist_play_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticUrlType,
      value: diagnostics.urlType,
      icon: Icons.link_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticUrl,
      value: diagnostics.sanitizedUrl,
      icon: Icons.language_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticHeaders,
      value: headers,
      icon: Icons.key_outlined,
    ),
    _DiagnosticTile(
      label: context.l10n.playbackDiagnosticState,
      value: _playbackDiagnosticStateLabel(context, diagnostics.state),
      icon: Icons.monitor_heart_outlined,
    ),
  ];
}

String _playbackDiagnosticStateLabel(
  BuildContext context,
  PlaybackDiagnosticState state,
) {
  return switch (state) {
    PlaybackDiagnosticState.loading =>
      context.l10n.playbackDiagnosticStateLoading,
    PlaybackDiagnosticState.ready => context.l10n.playbackDiagnosticStateReady,
    PlaybackDiagnosticState.playing =>
      context.l10n.playbackDiagnosticStatePlaying,
    PlaybackDiagnosticState.buffering =>
      context.l10n.playbackDiagnosticStateBuffering,
    PlaybackDiagnosticState.error => context.l10n.playbackDiagnosticStateError,
  };
}

String _diagnosticContextValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '-';
  }
  return trimmed;
}

String _playbackSnapshotSubtitle(
  BuildContext context,
  PlaybackDiagnostics? diagnostics,
) {
  if (diagnostics == null) {
    return context.l10n.playbackDiagnosticsEmptyHint;
  }
  final preview = buildPlaybackDiagnosticSnapshotPreview(
    l10n: context.l10n,
    localeName: Localizations.localeOf(context).toLanguageTag(),
    diagnostics: diagnostics,
  );
  return '${context.l10n.playbackDiagnosticsSummaryHint}\n\n$preview';
}

String _formatCapturedAt(BuildContext context, DateTime capturedAt) {
  return formatPlaybackDiagnosticCapturedAt(
    capturedAt,
    localeName: Localizations.localeOf(context).toLanguageTag(),
  );
}

class _SourceHealthTile extends StatelessWidget {
  const _SourceHealthTile({required this.health});

  final SourceHealth health;

  @override
  Widget build(BuildContext context) {
    return _DiagnosticTile(
      label:
          '${context.l10n.sourceDisplayLabel(health.sourceId)} · ${_statusLabel(context)}',
      value: [
        context.l10n.sourceFailureCount(health.failureCount),
        if (health.lastErrorMessage != null)
          context.l10n.sourceLastError(sanitizeError(health.lastErrorMessage!)),
        if (_recoveryHint(context) case final recoveryHint?) recoveryHint,
      ].join('\n'),
      icon: Icons.monitor_heart_outlined,
    );
  }

  String _statusLabel(BuildContext context) {
    return switch (health.status) {
      SourceHealthStatus.healthy => context.l10n.sourceHealthHealthy,
      SourceHealthStatus.degraded => context.l10n.sourceHealthDegraded,
      SourceHealthStatus.unavailable => context.l10n.sourceHealthUnavailable,
    };
  }

  String? _recoveryHint(BuildContext context) {
    return switch (health.status) {
      SourceHealthStatus.healthy => null,
      SourceHealthStatus.degraded => context.l10n.sourceHealthDegradedHint,
      SourceHealthStatus.unavailable =>
        context.l10n.sourceHealthUnavailableHint,
    };
  }
}

class _FallbackEventTile extends StatelessWidget {
  const _FallbackEventTile({required this.event});

  final SourceFallbackEvent event;

  @override
  Widget build(BuildContext context) {
    return _DiagnosticTile(
      label:
          '${context.l10n.sourceOperationLabel(event.operation)}: ${context.l10n.sourceTransitionLabel(event.fromSourceId, event.toSourceId)}',
      value: sanitizeError(event.reason),
      icon: Icons.swap_horiz_outlined,
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: SelectableText(value),
    );
  }
}

class _SourceDiagnosticTile extends StatelessWidget {
  const _SourceDiagnosticTile({required this.diagnostic});

  final SourceDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (diagnostic.url != null) sanitizeUrlForDiagnostics(diagnostic.url!),
      if (diagnostic.statusCode != null) 'HTTP ${diagnostic.statusCode}',
      if (diagnostic.exceptionType != null) diagnostic.exceptionType!,
      if (diagnostic.usedFallback &&
          diagnostic.fromSourceId != null &&
          diagnostic.toSourceId != null)
        context.l10n.sourceTransitionLabel(
          diagnostic.fromSourceId!,
          diagnostic.toSourceId!,
        ),
      if (diagnostic.reason != null) sanitizeError(diagnostic.reason!),
    ];

    return ListTile(
      leading: Icon(_iconForLevel(diagnostic.level)),
      title: Text(
        '${context.l10n.sourceDisplayLabel(diagnostic.sourceId)} · ${context.l10n.sourceOperationLabel(diagnostic.operation)}',
      ),
      subtitle: SelectableText(
        [
          sanitizeError(diagnostic.message),
          if (details.isNotEmpty) details.join(' · '),
        ].join('\n'),
      ),
    );
  }

  IconData _iconForLevel(SourceDiagnosticLevel level) {
    return switch (level) {
      SourceDiagnosticLevel.info => Icons.info_outline,
      SourceDiagnosticLevel.warning => Icons.warning_amber_outlined,
      SourceDiagnosticLevel.error => Icons.error_outline,
    };
  }
}

Future<void> _copyDiagnostics(BuildContext context, WidgetRef ref) async {
  try {
    final markdown = await ref.read(feedbackPackageMarkdownProvider.future);
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.diagnosticsCopied)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.diagnosticsCopyFailed)),
    );
  }
}

Future<void> _copyPlaybackDiagnostics(
  BuildContext context,
  PlaybackDiagnostics diagnostics,
) async {
  final summary = buildPlaybackDiagnosticSummary(
    l10n: context.l10n,
    localeName: Localizations.localeOf(context).toLanguageTag(),
    diagnostics: diagnostics,
  );

  try {
    await Clipboard.setData(ClipboardData(text: summary));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.playbackDiagnosticsCopied)),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.diagnosticsCopyFailed)),
    );
  }
}
