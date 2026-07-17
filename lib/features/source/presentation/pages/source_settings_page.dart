import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/diagnostics/diagnostic_sanitizer.dart';
import '../../../../core/utils/url_sanitizer.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/source_diagnostic.dart';
import '../../domain/entities/source_fallback_event.dart';
import '../../domain/entities/source_health.dart';
import '../providers/source_providers.dart';
import '../widgets/source_selector.dart';

class SourceSettingsPage extends ConsumerWidget {
  const SourceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourceListProvider);
    final currentSource = ref.watch(currentSourceIdProvider);
    final healthBySourceId = {
      for (final health in ref.watch(sourceHealthControllerProvider))
        health.sourceId: health,
    };

    return SafeArea(
      child: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.sources,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: currentSource.when(
                loading: () =>
                    AppLoadingView(message: context.l10n.loadingCurrentSource),
                error: (error, stackTrace) => AppErrorView(
                  message: '${context.l10n.sourceTemporarilyUnavailable}\n'
                      '${context.l10n.sourceUnavailableSuggestion}',
                ),
                data: (currentSourceId) => ListView(
                  children: [
                    SourceSelector(
                      sources: sources,
                      currentSourceId: currentSourceId,
                      healthBySourceId: healthBySourceId,
                      onSelected: (sourceId) async {
                        await ref
                            .read(currentSourceIdProvider.notifier)
                            .setSource(sourceId);
                        ref.invalidate(homeRecommendationsProvider);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n.sourceSetTo(
                                context.l10n.sourceDisplayName(
                                  sourceId,
                                  sourceId,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      onResetHealth: (sourceId) {
                        ref
                            .read(sourceHealthControllerProvider.notifier)
                            .reset(sourceId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.sourceStatusReset),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text(context.l10n.sourceDiagnostics),
                      subtitle: Text(context.l10n.sourceDiagnosticsSubtitle),
                      trailing: const Icon(Icons.tune_outlined),
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (_) => const _SourceDiagnosticsSheet(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.sourceV1Note,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceDiagnosticsSheet extends ConsumerWidget {
  const _SourceDiagnosticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref
        .watch(sourceDiagnosticsControllerProvider)
        .toList(growable: false)
        .reversed
        .take(20)
        .toList(growable: false);
    final fallbackEvents = ref
        .watch(sourceFallbackEventsProvider)
        .toList(growable: false)
        .reversed
        .take(8)
        .toList(growable: false);
    final health = ref.watch(sourceHealthControllerProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.sourceDiagnostics,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: diagnostics.isEmpty
                        ? null
                        : () => ref
                            .read(sourceDiagnosticsControllerProvider.notifier)
                            .clear(),
                    icon: const Icon(Icons.clear_all),
                    label: Text(context.l10n.sourceDiagnosticsClear),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.content_copy_outlined),
                      title: Text(context.l10n.copyDiagnostics),
                      subtitle: Text(context.l10n.diagnosticsPrivacyNote),
                      onTap: () => _copyDiagnostics(context, ref),
                    ),
                    const Divider(),
                    _SheetSectionTitle(title: context.l10n.sourceHealth),
                    if (health.isEmpty)
                      ListTile(title: Text(context.l10n.sourceDiagnosticsEmpty))
                    else
                      for (final item in health)
                        _SourceHealthTile(health: item),
                    const Divider(),
                    _SheetSectionTitle(
                      title: context.l10n.sourceFallbackEvents,
                    ),
                    if (fallbackEvents.isEmpty)
                      ListTile(
                        title: Text(context.l10n.sourceFallbackEventsEmpty),
                      )
                    else
                      for (final event in fallbackEvents)
                        _FallbackEventTile(event: event),
                    const Divider(),
                    _SheetSectionTitle(
                      title: context.l10n.latestSourceDiagnostics,
                    ),
                    if (diagnostics.isEmpty)
                      ListTile(title: Text(context.l10n.sourceDiagnosticsEmpty))
                    else
                      for (final diagnostic in diagnostics)
                        _SourceDiagnosticTile(diagnostic: diagnostic),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SourceHealthTile extends StatelessWidget {
  const _SourceHealthTile({required this.health});

  final SourceHealth health;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.monitor_heart_outlined),
      title: Text(
        '${context.l10n.sourceDisplayLabel(health.sourceId)} · ${_statusLabel(context)}',
      ),
      subtitle: Text(
        [
          context.l10n.sourceFailureCount(health.failureCount),
          if (health.lastErrorMessage != null)
            context.l10n
                .sourceLastError(sanitizeError(health.lastErrorMessage!)),
        ].join('\n'),
      ),
    );
  }

  String _statusLabel(BuildContext context) {
    return switch (health.status) {
      SourceHealthStatus.healthy => context.l10n.sourceHealthHealthy,
      SourceHealthStatus.degraded => context.l10n.sourceHealthDegraded,
      SourceHealthStatus.unavailable => context.l10n.sourceHealthUnavailable,
    };
  }
}

class _FallbackEventTile extends StatelessWidget {
  const _FallbackEventTile({required this.event});

  final SourceFallbackEvent event;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.swap_horiz_outlined),
      title: Text(
        '${context.l10n.sourceOperationLabel(event.operation)}: ${context.l10n.sourceTransitionLabel(event.fromSourceId, event.toSourceId)}',
      ),
      subtitle: Text(_formatFallbackEventReason(event.reason)),
    );
  }
}

final _fallbackAttemptPrefix = RegExp(
  r'^Source attempt \d+:\s*',
  caseSensitive: false,
);
final _sourceFallbackMessageBoilerplate = RegExp(
  r'^source fallback used[\s:：。！!;；,，\-–—.]*(?<reason>.*)$',
  caseSensitive: false,
);

String _formatFallbackEventReason(String reason) {
  final normalized = sanitizeError(reason).trim();
  if (normalized.isEmpty) {
    return normalized;
  }

  if (!_fallbackAttemptPrefix.hasMatch(normalized)) {
    return normalized;
  }

  final reasons = normalized
      .split(' · ')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .map((entry) => entry.replaceFirst(_fallbackAttemptPrefix, ''))
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);

  if (reasons.isEmpty) {
    return normalized;
  }

  if (reasons.length == 1) {
    return reasons.single;
  }

  return reasons.join('\n');
}

class _SourceDiagnosticTile extends StatelessWidget {
  const _SourceDiagnosticTile({required this.diagnostic});

  final SourceDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnostic.level) {
      SourceDiagnosticLevel.info => Theme.of(context).colorScheme.primary,
      SourceDiagnosticLevel.warning => Theme.of(context).colorScheme.tertiary,
      SourceDiagnosticLevel.error => Theme.of(context).colorScheme.error,
    };
    final messageLine = _diagnosticMessageLine(diagnostic);
    final timestamp = diagnostic.timestamp;
    final details = [
      if (diagnostic.url != null) sanitizeUrlForDiagnostics(diagnostic.url!),
      if (diagnostic.statusCode != null) 'HTTP ${diagnostic.statusCode}',
      if (diagnostic.usedFallback &&
          diagnostic.fromSourceId != null &&
          diagnostic.toSourceId != null)
        context.l10n.sourceTransitionLabel(
          diagnostic.fromSourceId!,
          diagnostic.toSourceId!,
        ),
      if (diagnostic.reason != null)
        _formatFallbackEventReason(diagnostic.reason!),
      if (timestamp != null)
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, color: color, size: 12),
      title: Text(
        '${context.l10n.sourceDisplayLabel(diagnostic.sourceId)} · ${context.l10n.sourceOperationLabel(diagnostic.operation)}',
      ),
      subtitle: Text(
        [
          if (messageLine != null) messageLine,
          if (details.isNotEmpty) details.join(' · '),
        ].join('\n'),
      ),
    );
  }
}

String? _diagnosticMessageLine(SourceDiagnostic diagnostic) {
  final message = sanitizeError(diagnostic.message).trim();
  if (message.isEmpty) {
    return null;
  }

  final sanitizedMessage = _sanitizeSourceFallbackMessage(message);
  if (sanitizedMessage == null) {
    return null;
  }

  return sanitizedMessage;
}

String? _sanitizeSourceFallbackMessage(String message) {
  final match = _sourceFallbackMessageBoilerplate.firstMatch(message);
  if (match == null) {
    return message;
  }

  final reason = match.namedGroup('reason')?.trim() ?? '';
  if (reason.isEmpty) {
    return null;
  }

  return reason;
}
