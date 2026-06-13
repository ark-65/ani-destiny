import '../../features/download/domain/entities/download_failure_reason.dart';
import '../../features/download/domain/entities/download_kind.dart';
import '../../features/download/domain/entities/download_task.dart';
import '../../features/player/domain/services/playback_diagnostics.dart';
import '../../features/source/domain/entities/source_diagnostic.dart';
import '../../features/source/domain/entities/source_fallback_event.dart';
import '../../features/source/domain/entities/source_health.dart';
import 'diagnostic_sanitizer.dart';
import 'feedback_package.dart';

class FeedbackPackageCollector {
  const FeedbackPackageCollector({
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
    );
  }

  String _sourceSummary() {
    final lines = <String>[
      '- Current source: ${_sourceLabelOrUnavailable(currentSourceId)}',
    ];

    if (sourceHealth.isEmpty) {
      lines.add('- Health: Unavailable');
    } else {
      lines.add('- Health:');
      for (final health in sourceHealth) {
        lines.add(
          '  - ${_sourceLabel(health.sourceId)}: ${health.status.name}, '
          'failures=${health.failureCount}',
        );
        if (health.lastErrorMessage != null) {
          lines.add(
            '    last error: ${sanitizeError(health.lastErrorMessage!)}',
          );
        }
      }
    }

    if (fallbackEvents.isEmpty) {
      lines.add('- Recent fallback events: none');
    } else {
      lines.add('- Recent fallback events:');
      for (final event in fallbackEvents.take(6)) {
        lines.add(
          '  - ${event.operation}: ${_sourceLabel(event.fromSourceId)} -> '
          '${_sourceLabel(event.toSourceId)}, '
          'reason=${sanitizeError(event.reason)}',
        );
      }
    }

    if (sourceDiagnostics.isEmpty) {
      lines.add('- Recent source diagnostics: none');
    } else {
      lines.add('- Recent source diagnostics:');
      for (final diagnostic in sourceDiagnostics.take(8)) {
        final details = [
          diagnostic.level.name,
          if (diagnostic.statusCode != null) 'HTTP ${diagnostic.statusCode}',
          if (diagnostic.url != null) sanitizeUrl(diagnostic.url!),
          if (diagnostic.exceptionType != null) diagnostic.exceptionType!,
        ].join(', ');
        lines.add(
          '  - ${_sourceLabel(diagnostic.sourceId)}/${diagnostic.operation}: '
          '${sanitizeError(diagnostic.message)} ($details)',
        );
      }
    }

    return lines.join('\n');
  }

  String _playbackSummary() {
    final diagnostics = playbackDiagnostics;
    if (diagnostics == null) {
      return 'Unavailable: no playback diagnostics captured in this session.';
    }

    return [
      '- Anime: ${diagnostics.animeTitle}',
      '- Episode: ${diagnostics.episodeTitle}',
      '- Source: ${_sourceLabel(diagnostics.sourceId)}',
      '- Line: ${diagnostics.playSourceTitle ?? 'Unavailable'}',
      '- URL type: ${diagnostics.urlType}',
      '- URL: ${diagnostics.sanitizedUrl}',
      '- Header keys: ${diagnostics.headerKeys.isEmpty ? 'none' : diagnostics.headerKeys.join(', ')}',
    ].join('\n');
  }

  String _danmakuSummary() {
    return [
      '- Enabled: $danmakuEnabled',
      '- Dandanplay app ID configured: $dandanplayAppIdConfigured',
      '- Dandanplay secondary credential configured: '
          '$dandanplayAppSecretConfigured',
      '- Fallback provider: available',
    ].join('\n');
  }

  String _sourceLabel(String sourceId) => _sourceLabelForId(sourceId);

  String _sourceLabelOrUnavailable(String? sourceId) {
    if (sourceId == null) return 'Unavailable';
    return _sourceLabel(sourceId);
  }

  String _downloadSummary() {
    if (downloadTasks.isEmpty) return '- Total tasks: 0';

    final statusCounts = <DownloadStatus, int>{};
    final kindCounts = <DownloadKind, int>{};
    for (final task in downloadTasks) {
      statusCounts[task.status] = (statusCounts[task.status] ?? 0) + 1;
      kindCounts[task.kind] = (kindCounts[task.kind] ?? 0) + 1;
    }

    final latestIssue = downloadTasks
        .where(
          (task) =>
              task.status == DownloadStatus.failed ||
              task.status == DownloadStatus.unsupported ||
              (task.failureReason != DownloadFailureReason.none &&
                  task.failureReason != DownloadFailureReason.canceled),
        )
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final lines = <String>[
      '- Total tasks: ${downloadTasks.length}',
      '- Status counts:',
      for (final status in DownloadStatus.values)
        '  - ${status.name}: ${statusCounts[status] ?? 0}',
      '- Kind counts:',
      for (final kind in DownloadKind.values)
        '  - ${kind.name}: ${kindCounts[kind] ?? 0}',
    ];

    if (latestIssue.isEmpty) {
      lines.add('- Latest issue: none');
    } else {
      final task = latestIssue.first;
      lines.add(
        '- Latest issue: ${task.status.name}, '
        'reason=${task.failureReason.name}',
      );
      if (task.failureMessage != null) {
        lines.add('  message=${sanitizeError(task.failureMessage!)}');
      }
    }

    return lines.join('\n');
  }
}
