import 'diagnostic_sanitizer.dart';
import 'feedback_package.dart';

class FeedbackPackageFormatter {
  const FeedbackPackageFormatter();

  String format(FeedbackPackage package) {
    final buffer = StringBuffer()
      ..writeln('# AniDestiny Feedback Package')
      ..writeln()
      ..writeln('## App')
      ..writeln('- Name: ${sanitizeError(package.appName)}')
      ..writeln('- Version: ${sanitizeError(package.appVersion)}')
      ..writeln('- Generated at: ${package.generatedAt.toIso8601String()}')
      ..writeln()
      ..writeln('## Platform')
      ..writeln(_sanitizeSection(package.platform))
      ..writeln()
      ..writeln('## Source')
      ..writeln(_sanitizeSection(package.sourceSummary))
      ..writeln()
      ..writeln('## Playback')
      ..writeln(_sanitizeSection(package.playbackSummary))
      ..writeln()
      ..writeln('## Danmaku')
      ..writeln(_sanitizeSection(package.danmakuSummary))
      ..writeln()
      ..writeln('## Downloads')
      ..writeln(_sanitizeSection(package.downloadSummary))
      ..writeln()
      ..writeln('## Notes')
      ..writeln(_sanitizeSection(package.notes));

    return buffer.toString().trimRight();
  }

  String _sanitizeSection(String value) {
    final lines = value
        .split('\n')
        .map((line) => sanitizeError(line))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return 'Unavailable';
    return lines.join('\n');
  }
}
