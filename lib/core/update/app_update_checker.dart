import 'package:dio/dio.dart';

class AppUpdateChecker {
  const AppUpdateChecker(this._dio);

  final Dio _dio;

  Future<AppUpdate?> check(String installedVersion) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/ark-65/ani-destiny/releases/latest',
    );
    return AppUpdate.fromGitHubRelease(
      installedVersion: installedVersion,
      release: response.data,
    );
  }
}

class AppUpdate {
  const AppUpdate({required this.version, required this.releaseUrl});

  final String version;
  final String releaseUrl;

  static AppUpdate? fromGitHubRelease({
    required String installedVersion,
    required Map<String, dynamic>? release,
  }) {
    if (release == null || release['prerelease'] == true) return null;
    final version = (release['tag_name'] as String? ?? '').trim();
    final releaseUrl = (release['html_url'] as String? ?? '').trim();
    if (version.isEmpty || releaseUrl.isEmpty) return null;
    if (!_isNewer(version, installedVersion)) return null;
    return AppUpdate(version: version, releaseUrl: releaseUrl);
  }

  static bool _isNewer(String candidate, String installed) {
    final candidateParts = _versionParts(candidate);
    final installedParts = _versionParts(installed);
    if (candidateParts == null || installedParts == null) return false;
    for (var index = 0; index < 3; index++) {
      if (candidateParts[index] != installedParts[index]) {
        return candidateParts[index] > installedParts[index];
      }
    }
    return false;
  }

  static List<int>? _versionParts(String version) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$')
        .firstMatch(version.trim());
    if (match == null) return null;
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }
}
