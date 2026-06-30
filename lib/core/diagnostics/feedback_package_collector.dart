import '../../app/l10n/app_localizations.dart';
import '../../features/download/download_task_cleanup_state.dart';
import '../../features/download/domain/entities/download_failure_reason.dart';
import '../../features/download/domain/entities/download_kind.dart';
import '../../features/download/domain/entities/download_task.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
import '../../features/source/domain/entities/source_diagnostic.dart';
import '../../features/source/domain/entities/source_fallback_event.dart';
import '../../features/source/domain/entities/source_health.dart';
import 'diagnostic_sanitizer.dart';
import 'feedback_package.dart';
import 'playback_diagnostic_summary.dart';

class FeedbackPackageCollector {
  const FeedbackPackageCollector({
    required this.l10n,
    required this.appName,
    required this.appVersion,
    required this.platform,
    required this.currentSourceId,
    required this.sourceHealth,
    required this.sourceDiagnostics,
    required this.fallbackEvents,
    required this.playbackDiagnostics,
    required this.danmakuEnabled,
    required this.dandanplayAppIdConfigured,
    required this.dandanplayAppSecretConfigured,
    required this.downloadTasks,
    String Function(String sourceId)? sourceLabelForId,
  }) : _sourceLabelForId = sourceLabelForId ?? _identitySourceLabel;

  final AppLocalizations l10n;
  final String appName;
  final String appVersion;
  final String platform;
  final String? currentSourceId;
  final List<SourceHealth> sourceHealth;
  final List<SourceDiagnostic> sourceDiagnostics;
  final List<SourceFallbackEvent> fallbackEvents;
  final PlaybackDiagnostics? playbackDiagnostics;
  final bool danmakuEnabled;
  final bool dandanplayAppIdConfigured;
  final bool dandanplayAppSecretConfigured;
  final List<DownloadTask> downloadTasks;
  final String Function(String sourceId) _sourceLabelForId;

  static String _identitySourceLabel(String sourceId) => sourceId;

  FeedbackPackage collect({DateTime? generatedAt}) {
    return FeedbackPackage(
      generatedAt: generatedAt ?? DateTime.now(),
      appName: appName,
      appVersion: appVersion,
      platform: platform,
      sourceSummary: _sourceSummary(),
      playbackSummary: _playbackSummary(),
      danmakuSummary: _danmakuSummary(),
      downloadSummary: _downloadSummary(),
      notes: l10n.feedbackPackageNotesPlaceholder,
    );
  }

  String _sourceSummary() {
    final lines = <String>[
      '- ${l10n.selectedAppSource}: ${_sourceLabelOrUnavailable(currentSourceId)}',
    ];

    if (sourceHealth.isEmpty) {
      lines.add('- ${l10n.sourceHealth}: ${l10n.feedbackPackageUnavailable}');
    } else {
      lines.add('- ${l10n.sourceHealth}:');
      for (final health in sourceHealth) {
        lines.add(
          '  - ${_sourceLabel(health.sourceId)} · ${_sourceHealthStatusLabel(health.status)}',
        );
        lines.add('    ${l10n.sourceFailureCount(health.failureCount)}');
        if (health.lastErrorMessage != null) {
          lines.add(
            '    ${l10n.sourceLastError(sanitizeError(health.lastErrorMessage!))}',
          );
        }
      }
    }

    if (fallbackEvents.isEmpty) {
      lines.add('- ${l10n.sourceFallbackEvents}: ${l10n.feedbackPackageNone}');
    } else {
      lines.add('- ${l10n.sourceFallbackEvents}:');
      for (final event in fallbackEvents.take(6)) {
        lines.add(
          '  - ${l10n.sourceOperationLabel(event.operation)}: '
          '${l10n.sourceTransitionLabel(event.fromSourceId, event.toSourceId)}',
        );
        lines.add(
          '    ${l10n.feedbackPackageReason}: ${sanitizeError(event.reason)}',
        );
      }
    }

    if (sourceDiagnostics.isEmpty) {
      lines.add(
        '- ${l10n.latestSourceDiagnostics}: ${l10n.feedbackPackageNone}',
      );
    } else {
      lines.add('- ${l10n.latestSourceDiagnostics}:');
      for (final diagnostic in sourceDiagnostics.take(8)) {
        final details = [
          if (diagnostic.statusCode != null) 'HTTP ${diagnostic.statusCode}',
          if (diagnostic.url != null) sanitizeUrl(diagnostic.url!),
          if (diagnostic.exceptionType != null) diagnostic.exceptionType!,
          if (diagnostic.usedFallback &&
              diagnostic.fromSourceId != null &&
              diagnostic.toSourceId != null)
            l10n.sourceTransitionLabel(
              diagnostic.fromSourceId!,
              diagnostic.toSourceId!,
            ),
        ].join(' · ');
        lines.add(
          '  - ${_sourceLabel(diagnostic.sourceId)} · '
          '${l10n.sourceOperationLabel(diagnostic.operation)}',
        );
        lines.add('    ${sanitizeError(diagnostic.message)}');
        if (details.isNotEmpty) {
          lines.add('    $details');
        }
      }
    }

    return lines.join('\n');
  }

  String _playbackSummary() {
    final diagnostics = playbackDiagnostics;
    if (diagnostics == null) {
      return '${l10n.feedbackPackageUnavailable}: '
          '${l10n.feedbackPackagePlaybackUnavailable}';
    }

    return buildPlaybackDiagnosticDetailLines(
      l10n: l10n,
      localeName: l10n.locale.toLanguageTag(),
      diagnostics: diagnostics,
      sourceLabelForId: _sourceLabel,
      includeExactIso: true,
    ).map((line) => '- $line').join('\n');
  }

  String _danmakuSummary() {
    return [
      '- ${l10n.enabled}: ${l10n.yesNo(danmakuEnabled)}',
      '- ${l10n.feedbackPackageDandanplayAppIdConfigured}: '
          '${l10n.yesNo(dandanplayAppIdConfigured)}',
      '- ${l10n.feedbackPackageDandanplayAppSecretConfigured}: '
          '${l10n.yesNo(dandanplayAppSecretConfigured)}',
      '- ${l10n.feedbackPackageDanmakuFallbackProvider}: '
          '${l10n.feedbackPackageAvailable}',
    ].join('\n');
  }

  String _sourceLabel(String sourceId) => _sourceLabelForId(sourceId);

  String _sourceLabelOrUnavailable(String? sourceId) {
    if (sourceId == null) return l10n.feedbackPackageUnavailable;
    return _sourceLabel(sourceId);
  }

  String _downloadSummary() {
    if (downloadTasks.isEmpty) {
      return '- ${l10n.feedbackPackageTotalTasks}: 0';
    }

    final statusCounts = <DownloadStatus, int>{};
    final kindCounts = <DownloadKind, int>{};
    final manualCleanupTaskIds = <String>{};
    for (final task in downloadTasks) {
      final needsManualCleanup = downloadTaskNeedsManualCleanup(task);
      if (needsManualCleanup) {
        manualCleanupTaskIds.add(task.id);
      }
      statusCounts[task.status] = (statusCounts[task.status] ?? 0) + 1;
      kindCounts[task.kind] = (kindCounts[task.kind] ?? 0) + 1;
    }

    final manualCleanupCount = manualCleanupTaskIds.length;
    final canceledCount =
        (statusCounts[DownloadStatus.canceled] ?? 0) - manualCleanupCount;

    final latestIssue = downloadTasks
        .where(
          (task) =>
              manualCleanupTaskIds.contains(task.id) ||
              task.status == DownloadStatus.failed ||
              task.status == DownloadStatus.unsupported ||
              (task.failureReason != DownloadFailureReason.none &&
                  task.failureReason != DownloadFailureReason.canceled),
        )
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final lines = <String>[
      '- ${l10n.feedbackPackageTotalTasks}: ${downloadTasks.length}',
      '- ${l10n.feedbackPackageStatusCounts}:',
      '  - ${_downloadStatusLabel(DownloadStatus.pending)}: '
          '${statusCounts[DownloadStatus.pending] ?? 0}',
      '  - ${_downloadStatusLabel(DownloadStatus.preparing)}: '
          '${statusCounts[DownloadStatus.preparing] ?? 0}',
      '  - ${_downloadStatusLabel(DownloadStatus.downloading)}: '
          '${statusCounts[DownloadStatus.downloading] ?? 0}',
      '  - ${_downloadStatusLabel(DownloadStatus.paused)}: '
          '${statusCounts[DownloadStatus.paused] ?? 0}',
      '  - ${_downloadStatusLabel(DownloadStatus.completed)}: '
          '${statusCounts[DownloadStatus.completed] ?? 0}',
      '  - ${_downloadStatusLabel(DownloadStatus.failed)}: '
          '${statusCounts[DownloadStatus.failed] ?? 0}',
      if (manualCleanupCount > 0)
        '  - ${l10n.downloadManualCleanupStatus}: $manualCleanupCount',
      '  - ${_downloadStatusLabel(DownloadStatus.canceled)}: $canceledCount',
      '  - ${_downloadStatusLabel(DownloadStatus.unsupported)}: '
          '${statusCounts[DownloadStatus.unsupported] ?? 0}',
      '- ${l10n.feedbackPackageKindCounts}:',
      for (final kind in DownloadKind.values)
        '  - ${_downloadKindLabel(kind)}: ${kindCounts[kind] ?? 0}',
    ];

    if (latestIssue.isEmpty) {
      lines.add(
        '- ${l10n.feedbackPackageLatestIssue}: ${l10n.feedbackPackageNone}',
      );
    } else {
      final task = latestIssue.first;
      final needsManualCleanup = manualCleanupTaskIds.contains(task.id);
      final manualCleanupActionLabel = manualCleanupCount > 1
          ? l10n.recheckLeftoverFilesCount(manualCleanupCount)
          : null;
      lines.add(
        '- ${l10n.feedbackPackageLatestIssue}: '
        '${needsManualCleanup ? l10n.downloadManualCleanupStatus : _downloadStatusLabel(task.status)}'
        ' · ${l10n.feedbackPackageReason}: '
        '${_downloadFailureReasonLabel(task.failureReason)}',
      );
      final localPath = task.localPath;
      if (needsManualCleanup && localPath != null && localPath.isNotEmpty) {
        lines.add('  ${l10n.downloadLocalPath}: $localPath');
        lines.add(
          '  ${l10n.feedbackPackageMessage}: '
          '${l10n.downloadManualCleanupFeedbackNextStep(actionLabel: manualCleanupActionLabel)}',
        );
      }
      final failureMessage = _downloadFailureMessage(task);
      if (failureMessage != null) {
        lines.add(
          '  ${l10n.feedbackPackageMessage}: $failureMessage',
        );
      }
    }

    return lines.join('\n');
  }

  String _sourceHealthStatusLabel(SourceHealthStatus status) {
    return switch (status) {
      SourceHealthStatus.healthy => l10n.sourceHealthHealthy,
      SourceHealthStatus.degraded => l10n.sourceHealthDegraded,
      SourceHealthStatus.unavailable => l10n.sourceHealthUnavailable,
    };
  }

  String _downloadStatusLabel(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.pending => l10n.pending,
      DownloadStatus.preparing => l10n.preparing,
      DownloadStatus.downloading => l10n.downloading,
      DownloadStatus.paused => l10n.downloadStoppedStatus,
      DownloadStatus.completed => l10n.completed,
      DownloadStatus.failed => l10n.failed,
      DownloadStatus.canceled => l10n.downloadDiscardedStatus,
      DownloadStatus.unsupported => l10n.unsupported,
    };
  }

  String _downloadKindLabel(DownloadKind kind) {
    return switch (kind) {
      DownloadKind.directFile => l10n.downloadKindDirectFile,
      DownloadKind.hls => l10n.downloadKindHls,
      DownloadKind.bt => l10n.downloadKindBt,
      DownloadKind.unknown => l10n.downloadKindUnknown,
    };
  }

  String _downloadFailureReasonLabel(DownloadFailureReason reason) {
    return switch (reason) {
      DownloadFailureReason.none => l10n.feedbackPackageNone,
      DownloadFailureReason.unsupportedType =>
        l10n.downloadFailureUnsupportedType,
      DownloadFailureReason.permissionDenied =>
        l10n.downloadFailurePermissionDenied,
      DownloadFailureReason.networkError => l10n.downloadFailureNetworkError,
      DownloadFailureReason.sourceUnavailable =>
        l10n.downloadFailureSourceUnavailable,
      DownloadFailureReason.invalidUrl => l10n.downloadFailureInvalidUrl,
      DownloadFailureReason.invalidManifest =>
        l10n.downloadFailureInvalidManifest,
      DownloadFailureReason.storageUnavailable =>
        l10n.downloadFailureStorageUnavailable,
      DownloadFailureReason.canceled => l10n.downloadDiscardedStatus,
      DownloadFailureReason.unknown => l10n.downloadFailureUnknown,
    };
  }

  String? _downloadFailureMessage(DownloadTask task) {
    if (task.failureReason == DownloadFailureReason.unsupportedType) {
      return switch (task.kind) {
        DownloadKind.hls => l10n.downloadUnsupportedHlsMessage,
        DownloadKind.bt => l10n.downloadUnsupportedBtMessage,
        DownloadKind.unknown => l10n.downloadUnsupportedUnknownMessage,
        DownloadKind.directFile => task.failureMessage == null
            ? null
            : sanitizeError(task.failureMessage!),
      };
    }
    return task.failureMessage == null
        ? null
        : sanitizeError(task.failureMessage!);
  }
}
