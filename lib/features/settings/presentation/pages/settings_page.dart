import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/theme/theme_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/diagnostics/issue_report_link.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../danmaku/presentation/providers/danmaku_providers.dart';
import '../../../danmaku/presentation/widgets/danmaku_settings_sheet.dart';
import '../../../player/presentation/providers/playback_buffering_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final danmakuSettings = ref.watch(danmakuSettingsProvider);
    final playbackBufferingSettings =
        ref.watch(playbackBufferingSettingsProvider);
    final version = ref.watch(appVersionLabelProvider).valueOrNull ??
        AppConstants.appVersion;

    return SafeArea(
      child: AdaptivePage(
        child: ListView(
          children: [
            Text(
              context.l10n.settings,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SettingsSection(
              title: context.l10n.playback,
              children: [
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: Text(context.l10n.sourceSettings),
                  subtitle: Text(context.l10n.sourceSettingsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/sources'),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(context.l10n.downloads),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/downloads'),
                ),
                ListTile(
                  leading: const Icon(Icons.subtitles_outlined),
                  title: Text(context.l10n.danmakuSettings),
                  trailing: const Icon(Icons.tune),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    builder: (context) => DanmakuSettingsSheet(
                      settings: danmakuSettings,
                      onChanged: (settings) {
                        ref.read(danmakuSettingsProvider.notifier).state =
                            settings;
                      },
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.network_check_outlined),
                  title: Text(context.l10n.forceAheadPlaybackBuffering),
                  subtitle: Text(
                    context.l10n.forceAheadPlaybackBufferingSubtitle,
                  ),
                  value: playbackBufferingSettings.forceAheadBuffering,
                  onChanged: (value) => ref
                      .read(playbackBufferingSettingsProvider.notifier)
                      .setForceAheadBuffering(value),
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.appearance,
              children: [
                RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (value) => _setTheme(ref, value),
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.system,
                        title: Text(context.l10n.system),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.light,
                        title: Text(context.l10n.light),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.dark,
                        title: Text(context.l10n.dark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.about,
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(context.l10n.aboutAniDestiny),
                  subtitle: Text(
                    '${context.l10n.appVersion(version)}\n'
                    '${context.l10n.appDescription}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: Text(context.l10n.supportedPlatforms),
                  subtitle: Text(context.l10n.supportedPlatformsValue),
                ),
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: Text(context.l10n.sourceStatus),
                  subtitle: Text(context.l10n.sourceStatusValue),
                ),
                ListTile(
                  leading: const Icon(Icons.subtitles_outlined),
                  title: Text(context.l10n.danmakuAbout),
                  subtitle: Text(context.l10n.danmakuAboutValue),
                ),
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(context.l10n.runtimeDiagnostics),
                  subtitle: Text(context.l10n.runtimeDiagnosticsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/diagnostics'),
                ),
                ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: Text(context.l10n.copyDiagnostics),
                  subtitle: Text(context.l10n.diagnosticsPrivacyNote),
                  onTap: () => _copyDiagnostics(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(context.l10n.reportIssue),
                  subtitle: Text(context.l10n.reportIssueSubtitle),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _reportIssue(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(context.l10n.githubRepository),
                  subtitle: const Text(AppConstants.openSourceUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openExternalUrl(AppConstants.openSourceUrl),
                ),
                ListTile(
                  leading: const Icon(Icons.new_releases_outlined),
                  title: Text(context.l10n.releasePage),
                  subtitle: const Text(AppConstants.releaseUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openExternalUrl(AppConstants.releaseUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setTheme(WidgetRef ref, ThemeMode? value) {
    if (value == null) return;
    ref.read(themeModeProvider.notifier).setThemeMode(value);
  }

  Future<void> _openExternalUrl(String url) async {
    await _openExternalUri(Uri.parse(url));
  }

  Future<void> _openExternalUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyDiagnostics(BuildContext context, WidgetRef ref) async {
    try {
      await _copyDiagnosticsMarkdown(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.diagnosticsCopied)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.diagnosticsCopyFailed)),
      );
    }
  }

  Future<void> _reportIssue(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final markdown = await _copyDiagnosticsMarkdown(ref);
      final uri = buildIssueReportUri(
        title: l10n.issueReportTitle,
        diagnosticsMarkdown: markdown,
        intro: l10n.issueReportBodyIntro,
        truncatedNotice: l10n.issueReportBodyTruncatedNotice,
      );
      await _openExternalUri(uri);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.issueReportCopied)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.issueReportCopyFailed)),
      );
    }
  }

  Future<String> _copyDiagnosticsMarkdown(WidgetRef ref) async {
    final markdown = await ref.read(feedbackPackageMarkdownProvider.future);
    await Clipboard.setData(ClipboardData(text: markdown));
    return markdown;
  }
}
