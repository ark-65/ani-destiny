import '../../app/l10n/app_localizations.dart';
import 'diagnostic_sanitizer.dart';
import 'feedback_package.dart';

class FeedbackPackageFormatter {
  const FeedbackPackageFormatter({required this.l10n});

  final AppLocalizations l10n;

  String format(FeedbackPackage package) {
    final buffer = StringBuffer()
      ..writeln('# ${l10n.feedbackPackageTitle}')
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionApp}')
      ..writeln(
        '- ${l10n.feedbackPackageName}: ${sanitizeError(package.appName)}',
      )
      ..writeln(
        '- ${l10n.feedbackPackageVersion}: ${sanitizeError(package.appVersion)}',
      )
      ..writeln(
        '- ${l10n.feedbackPackageGeneratedAt}: ${package.generatedAt.toIso8601String()}',
      )
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionPlatform}')
      ..writeln(_sanitizeSection(package.platform))
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionSource}')
      ..writeln(_sanitizeSection(package.sourceSummary))
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionPlayback}')
      ..writeln(_sanitizeSection(package.playbackSummary))
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionDanmaku}')
      ..writeln(_sanitizeSection(package.danmakuSummary))
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionDownloads}')
      ..writeln(_sanitizeSection(package.downloadSummary))
      ..writeln()
      ..writeln('## ${l10n.feedbackPackageSectionNotes}')
      ..writeln(_sanitizeSection(package.notes));

    return buffer.toString().trimRight();
  }

  String _sanitizeSection(String value) {
    final lines = value
        .split('\n')
        .map((line) => sanitizeError(line))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return l10n.feedbackPackageUnavailable;
    return lines.join('\n');
  }
}
