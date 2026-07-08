import '../constants/app_constants.dart';

const issueReportBodyMaxLength = 6000;

Uri buildIssueReportUri({
  required String title,
  required String diagnosticsMarkdown,
  required String intro,
  required String truncatedNotice,
}) {
  return Uri.parse(AppConstants.newIssueUrl).replace(
    queryParameters: {
      'title': title,
      'body': buildIssueReportBody(
        diagnosticsMarkdown: diagnosticsMarkdown,
        intro: intro,
        truncatedNotice: truncatedNotice,
      ),
    },
  );
}

String buildIssueReportBody({
  required String diagnosticsMarkdown,
  required String intro,
  required String truncatedNotice,
  int maxDiagnosticsLength = issueReportBodyMaxLength,
}) {
  final trimmedIntro = intro.trim();
  final trimmedDiagnostics = diagnosticsMarkdown.trim();
  final visibleDiagnostics = trimmedDiagnostics.length <= maxDiagnosticsLength
      ? trimmedDiagnostics
      : '${trimmedDiagnostics.substring(0, maxDiagnosticsLength).trimRight()}\n\n$truncatedNotice';

  if (trimmedIntro.isEmpty) return visibleDiagnostics;
  if (visibleDiagnostics.isEmpty) return trimmedIntro;
  return '$trimmedIntro\n\n$visibleDiagnostics';
}
