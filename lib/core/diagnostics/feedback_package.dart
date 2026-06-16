class FeedbackPackage {
  const FeedbackPackage({
    required this.generatedAt,
    required this.appName,
    required this.appVersion,
    required this.platform,
    required this.sourceSummary,
    required this.playbackSummary,
    required this.danmakuSummary,
    required this.downloadSummary,
    required this.notes,
  });

  final DateTime generatedAt;
  final String appName;
  final String appVersion;
  final String platform;
  final String sourceSummary;
  final String playbackSummary;
  final String danmakuSummary;
  final String downloadSummary;
  final String notes;
}
