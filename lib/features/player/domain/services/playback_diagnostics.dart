import '../../../../core/utils/url_sanitizer.dart';

class PlaybackDiagnostics {
  const PlaybackDiagnostics({
    required this.animeTitle,
    required this.episodeTitle,
    required this.sourceId,
    required this.requestedSourceId,
    required this.playSourceTitle,
    required this.urlType,
    required this.sanitizedUrl,
    required this.headerKeys,
  });

  final String animeTitle;
  final String episodeTitle;
  final String sourceId;
  final String? requestedSourceId;
  final String? playSourceTitle;
  final String urlType;
  final String sanitizedUrl;
  final List<String> headerKeys;

  bool get usedSourceFallback {
    final requested = requestedSourceId?.trim();
    return requested != null && requested.isNotEmpty && requested != sourceId;
  }
}

class PlaybackDiagnosticsBuilder {
  const PlaybackDiagnosticsBuilder();

  PlaybackDiagnostics build({
    required String animeTitle,
    required String episodeTitle,
    required String sourceId,
    String? requestedSourceId,
    required String? playSourceTitle,
    required String playUrl,
    required Map<String, String> headers,
  }) {
    return PlaybackDiagnostics(
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      sourceId: sourceId,
      requestedSourceId: requestedSourceId,
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
