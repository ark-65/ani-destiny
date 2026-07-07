import '../../../../core/utils/url_sanitizer.dart';

enum PlaybackDiagnosticState {
  loading,
  ready,
  playing,
  buffering,
  error,
}

class PlaybackDiagnostics {
  const PlaybackDiagnostics({
    required this.capturedAt,
    required this.animeTitle,
    required this.episodeTitle,
    required this.selectedAppSourceId,
    required this.sourceId,
    required this.requestedSourceId,
    required this.playSourceTitle,
    required this.urlType,
    required this.sanitizedUrl,
    required this.headerKeys,
    required this.state,
    this.forceAheadBuffering = false,
  });

  final DateTime capturedAt;
  final String animeTitle;
  final String episodeTitle;
  final String? selectedAppSourceId;
  final String sourceId;
  final String? requestedSourceId;
  final String? playSourceTitle;
  final String urlType;
  final String sanitizedUrl;
  final List<String> headerKeys;
  final PlaybackDiagnosticState state;
  final bool forceAheadBuffering;

  bool get usedSourceFallback {
    final requested = requestedSourceId?.trim();
    return requested != null && requested.isNotEmpty && requested != sourceId;
  }

  String? divergentSelectedAppSourceId() {
    final selected = selectedAppSourceId?.trim();
    if (selected == null || selected.isEmpty) {
      return null;
    }
    if (selected == sourceId || selected == requestedSourceId) {
      return null;
    }
    return selected;
  }

  PlaybackDiagnostics copyWith({
    String? selectedAppSourceId,
    bool? forceAheadBuffering,
  }) {
    return PlaybackDiagnostics(
      capturedAt: capturedAt,
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      selectedAppSourceId: selectedAppSourceId ?? this.selectedAppSourceId,
      sourceId: sourceId,
      requestedSourceId: requestedSourceId,
      playSourceTitle: playSourceTitle,
      urlType: urlType,
      sanitizedUrl: sanitizedUrl,
      headerKeys: headerKeys,
      state: state,
      forceAheadBuffering: forceAheadBuffering ?? this.forceAheadBuffering,
    );
  }
}

class PlaybackDiagnosticsBuilder {
  const PlaybackDiagnosticsBuilder();

  PlaybackDiagnostics build({
    DateTime? capturedAt,
    required String animeTitle,
    required String episodeTitle,
    required String? selectedAppSourceId,
    required String sourceId,
    String? requestedSourceId,
    required String? playSourceTitle,
    required String playUrl,
    required Map<String, String> headers,
    required PlaybackDiagnosticState state,
    bool forceAheadBuffering = false,
  }) {
    return PlaybackDiagnostics(
      capturedAt: capturedAt ?? DateTime.now(),
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      selectedAppSourceId: selectedAppSourceId,
      sourceId: sourceId,
      requestedSourceId: requestedSourceId,
      playSourceTitle: playSourceTitle,
      urlType: detectUrlType(playUrl),
      sanitizedUrl: sanitizeUrl(playUrl),
      headerKeys: headers.keys.toList(growable: false)..sort(),
      state: state,
      forceAheadBuffering: forceAheadBuffering,
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
