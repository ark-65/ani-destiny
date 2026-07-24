import 'package:ani_destiny/core/update/app_update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns an update when the latest stable release is newer', () {
    final update = AppUpdate.fromGitHubRelease(
      installedVersion: '1.0.6',
      release: {
        'tag_name': 'v1.1.0',
        'html_url': 'https://github.com/ark-65/ani-destiny/releases/tag/v1.1.0',
        'prerelease': false,
      },
    );

    expect(update?.version, 'v1.1.0');
  });

  test(
      'does not prompt for the installed version, older releases, or prereleases',
      () {
    for (final release in [
      {
        'tag_name': 'v1.0.6',
        'html_url': 'https://example.com/1.0.6',
        'prerelease': false,
      },
      {
        'tag_name': 'v1.0.5',
        'html_url': 'https://example.com/1.0.5',
        'prerelease': false,
      },
      {
        'tag_name': 'v1.1.0-beta.1',
        'html_url': 'https://example.com/1.1.0-beta.1',
        'prerelease': true,
      },
    ]) {
      expect(
        AppUpdate.fromGitHubRelease(
          installedVersion: '1.0.6',
          release: release,
        ),
        isNull,
      );
    }
  });
}
