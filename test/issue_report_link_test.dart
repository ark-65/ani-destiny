import 'package:ani_destiny/core/constants/app_constants.dart';
import 'package:ani_destiny/core/diagnostics/issue_report_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('issue report URL opens a prefilled GitHub issue', () {
    final uri = buildIssueReportUri(
      title: 'AniDestiny issue report',
      diagnosticsMarkdown: '# AniDestiny Feedback Summary\n- Version: 1.0.5',
      intro: 'Add reproduction steps before submitting.',
      truncatedNotice: 'Full report copied to clipboard.',
    );

    expect(uri.toString(), startsWith(AppConstants.newIssueUrl));
    expect(uri.queryParameters['title'], 'AniDestiny issue report');
    expect(
      uri.queryParameters['body'],
      contains('Add reproduction steps before submitting.'),
    );
    expect(
      uri.queryParameters['body'],
      contains('# AniDestiny Feedback Summary'),
    );
    expect(uri.queryParameters['body'], contains('- Version: 1.0.5'));
  });

  test('issue report body truncates long diagnostics for URL safety', () {
    final body = buildIssueReportBody(
      diagnosticsMarkdown: 'a' * (issueReportBodyMaxLength + 20),
      intro: 'Intro',
      truncatedNotice: 'Full report copied to clipboard.',
    );

    expect(body, startsWith('Intro\n\naaa'));
    expect(body, contains('Full report copied to clipboard.'));
    expect(body.length, lessThan(issueReportBodyMaxLength + 80));
  });
}
