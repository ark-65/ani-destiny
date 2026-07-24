import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/update/app_update_checker.dart';
import '../providers/settings_providers.dart';

class AppUpdateReminder extends ConsumerStatefulWidget {
  const AppUpdateReminder({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppUpdateReminder> createState() => _AppUpdateReminderState();
}

class _AppUpdateReminderState extends ConsumerState<AppUpdateReminder> {
  String? _shownVersion;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<AppUpdate?>>(appUpdateProvider, (_, next) {
      final update = next.valueOrNull;
      if (update == null || _shownVersion == update.version || !mounted) return;
      _shownVersion = update.version;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showUpdateReminder(update);
      });
    });
  }

  void _showUpdateReminder(AppUpdate update) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(l10n.updateAvailableSubtitle(update.version)),
        leading: const Icon(Icons.system_update_outlined),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: Text(l10n.later),
          ),
          FilledButton(
            onPressed: () async {
              await launchUrl(
                Uri.parse(update.releaseUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
