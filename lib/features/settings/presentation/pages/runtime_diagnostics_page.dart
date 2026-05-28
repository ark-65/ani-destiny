import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/utils/url_sanitizer.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../danmaku/presentation/providers/danmaku_providers.dart';
import '../../../source/domain/entities/source_diagnostic.dart';
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
    final danmakuSettings = ref.watch(danmakuSettingsProvider);

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
                  value: defaultTargetPlatform.name,
                  icon: Icons.devices_outlined,
                ),
                _DiagnosticTile(
                  label: context.l10n.currentSourceId,
                  value: currentSourceId ?? '-',
                  icon: Icons.source_outlined,
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.danmaku,
              children: [
                _DiagnosticTile(
                  label: context.l10n.enabled,
                  value: danmakuSettings.enabled.toString(),
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
                  subtitle: Text(context.l10n.playbackDiagnosticsDebugHint),
                ),
              ],
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
    ];

    return ListTile(
      leading: Icon(_iconForLevel(diagnostic.level)),
      title: Text('${diagnostic.sourceId} · ${diagnostic.operation}'),
      subtitle: SelectableText(
        [
          diagnostic.message,
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
