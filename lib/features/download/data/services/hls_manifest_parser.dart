import '../../domain/entities/hls_manifest.dart';

class HlsManifestParser {
  const HlsManifestParser();

  HlsManifest parse(String content, {required Uri uri}) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty || lines.first != '#EXTM3U') {
      throw const FormatException('Invalid HLS manifest.');
    }

    final segments = <HlsSegment>[];
    final variants = <HlsVariant>[];
    Duration? targetDuration;
    Duration? pendingSegmentDuration;
    String? pendingSegmentTitle;
    Map<String, String>? pendingVariantAttributes;
    var hasEndList = false;

    for (var index = 1; index < lines.length; index++) {
      final line = lines[index];
      if (line == '#EXT-X-ENDLIST') {
        hasEndList = true;
        continue;
      }
      if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        targetDuration = Duration(
          seconds: _parseIntAfterColon(line, fallback: 0),
        );
        continue;
      }
      if (line.startsWith('#EXTINF:')) {
        final info = line.substring('#EXTINF:'.length);
        final commaIndex = info.indexOf(',');
        final durationText =
            commaIndex == -1 ? info : info.substring(0, commaIndex);
        final title = commaIndex == -1 ? null : info.substring(commaIndex + 1);
        final seconds = double.tryParse(durationText.trim());
        pendingSegmentDuration = seconds == null
            ? null
            : Duration(milliseconds: (seconds * 1000).round());
        pendingSegmentTitle = title?.trim().isEmpty ?? true ? null : title;
        continue;
      }
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        pendingVariantAttributes = _parseAttributes(
          line.substring('#EXT-X-STREAM-INF:'.length),
        );
        continue;
      }
      if (line.startsWith('#')) {
        continue;
      }

      final resolvedUri = uri.resolve(line);
      if (pendingVariantAttributes != null) {
        variants.add(
          HlsVariant(
            uri: resolvedUri,
            bandwidth: int.tryParse(
              pendingVariantAttributes['BANDWIDTH'] ?? '',
            ),
            resolution: pendingVariantAttributes['RESOLUTION'],
          ),
        );
        pendingVariantAttributes = null;
      } else {
        segments.add(
          HlsSegment(
            uri: resolvedUri,
            duration: pendingSegmentDuration,
            title: pendingSegmentTitle,
          ),
        );
        pendingSegmentDuration = null;
        pendingSegmentTitle = null;
      }
    }

    if (segments.isEmpty && variants.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }

    return HlsManifest(
      uri: uri,
      segments: List.unmodifiable(segments),
      variants: List.unmodifiable(variants),
      isLive: !hasEndList,
      targetDuration: targetDuration,
    );
  }

  int _parseIntAfterColon(String line, {required int fallback}) {
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return fallback;
    return int.tryParse(line.substring(colonIndex + 1).trim()) ?? fallback;
  }

  Map<String, String> _parseAttributes(String value) {
    final attributes = <String, String>{};
    final parts = value.split(',');
    for (final part in parts) {
      final equalsIndex = part.indexOf('=');
      if (equalsIndex == -1) continue;
      final key = part.substring(0, equalsIndex).trim();
      final rawValue = part.substring(equalsIndex + 1).trim();
      attributes[key] = rawValue.replaceAll('"', '');
    }
    return attributes;
  }
}
