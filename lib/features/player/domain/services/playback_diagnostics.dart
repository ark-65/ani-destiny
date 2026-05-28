import '../../../../core/utils/url_sanitizer.dart';

class PlaybackDiagnostics {
  const PlaybackDiagnostics({
    required this.sourceId,
    required this.playSourceTitle,
    required this.urlType,
    required this.sanitizedUrl,
    required this.headerKeys,
  });

  final String sourceId;
  final String? playSourceTitle;
  final String urlType;
  final String sanitizedUrl;
  final List<String> headerKeys;
}

class PlaybackDiagnosticsBuilder {
  const PlaybackDiagnosticsBuilder();

  PlaybackDiagnostics build({
    required String sourceId,
    required String? playSourceTitle,
    required String playUrl,
    required Map<String, String> headers,
  }) {
    return PlaybackDiagnostics(
      sourceId: sourceId,
      playSourceTitle: playSourceTitle,
      urlType: detectUrlType(playUrl),
      sanitizedUrl: sanitizeUrl(playUrl),
      headerKeys: headers.keys.toList(growable: false)..sort(),
    );
  }

  String detectUrlType(String rawUrl) {
    final path =
        Uri.tryParse(rawUrl)?.path.toLowerCase() ?? rawUrl.toLowerCase();
    if (path.endsWith('.m3u8')) return 'm3u8';
    if (path.endsWith('.mp4')) return 'mp4';
    return 'unknown';
  }

  String sanitizeUrl(String rawUrl) {
    return sanitizeUrlForDiagnostics(rawUrl);
  }
}
