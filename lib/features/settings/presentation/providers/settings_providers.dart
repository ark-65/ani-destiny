import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/diagnostics/feedback_package.dart';
import '../../../../core/diagnostics/feedback_package_collector.dart';
import '../../../../core/diagnostics/feedback_package_formatter.dart';
import '../../../danmaku/presentation/providers/danmaku_providers.dart';
import '../../../download/domain/entities/download_task.dart';
import '../../../download/presentation/providers/download_providers.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../source/presentation/providers/source_providers.dart';

final appVersionLabelProvider = Provider<String>(
  (ref) => AppConstants.appVersion,
);

final feedbackPackageProvider =
    FutureProvider.autoDispose<FeedbackPackage>((ref) async {
  final currentSourceId = await _currentSourceId(ref);
  final downloadTasks = await _downloadTasks(ref);
  const dandanplayAppId = String.fromEnvironment('DANDANPLAY_APP_ID');
  const dandanplayAppSecret = String.fromEnvironment('DANDANPLAY_APP_SECRET');
  final l10n = AppLocalizations(
    AppLocalizations.resolve(
      ui.PlatformDispatcher.instance.locale,
      AppLocalizations.supportedLocales,
    ),
  );

  return FeedbackPackageCollector(
    appName: AppConstants.appName,
    appVersion: ref.watch(appVersionLabelProvider),
    platform: defaultTargetPlatform.name,
    currentSourceId: currentSourceId,
    sourceHealth: ref.watch(sourceHealthControllerProvider),
    sourceDiagnostics: ref
        .watch(sourceDiagnosticsControllerProvider)
        .toList(growable: false)
        .reversed
        .toList(growable: false),
    fallbackEvents: ref
        .watch(sourceFallbackEventsProvider)
        .toList(growable: false)
        .reversed
        .toList(growable: false),
    playbackDiagnostics: ref.watch(lastPlaybackDiagnosticsProvider),
    danmakuEnabled: ref.watch(danmakuSettingsProvider).enabled,
    dandanplayAppIdConfigured: dandanplayAppId.isNotEmpty,
    dandanplayAppSecretConfigured: dandanplayAppSecret.isNotEmpty,
    downloadTasks: downloadTasks,
    sourceLabelForId: l10n.sourceDisplayLabel,
  ).collect();
});

final feedbackPackageMarkdownProvider =
    FutureProvider.autoDispose<String>((ref) async {
  final package = await ref.watch(feedbackPackageProvider.future);
  return const FeedbackPackageFormatter().format(package);
});

Future<String?> _currentSourceId(Ref ref) async {
  try {
    return await ref.watch(currentSourceIdProvider.future);
  } on Object {
    return null;
  }
}

Future<List<DownloadTask>> _downloadTasks(Ref ref) {
  return ref.watch(downloadRepositoryProvider).watchTasks().first.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => const <DownloadTask>[],
      );
}
