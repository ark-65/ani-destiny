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
    var mediaSequence = 0;
    Duration? pendingSegmentDuration;
    String? pendingSegmentTitle;
    Map<String, String>? pendingVariantAttributes;
    HlsInitializationSegment? initializationSegment;
    HlsEncryptionKey? activeEncryptionKey;
    _PendingByteRange? pendingByteRange;
    Uri? previousByteRangeUri;
    int? previousByteRangeEnd;
    Uri? previousMapByteRangeUri;
    int? previousMapByteRangeEnd;
    var pendingDiscontinuity = false;
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
      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        final value = int.tryParse(
          line.substring('#EXT-X-MEDIA-SEQUENCE:'.length).trim(),
        );
        if (value == null || value < 0) {
          throw const FormatException('Invalid HLS media sequence.');
        }
        mediaSequence = value;
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
      if (line.startsWith('#EXT-X-MAP:')) {
        final attributes = _parseAttributes(
          line.substring('#EXT-X-MAP:'.length),
        );
        final mapUri = attributes['URI'];
        if (mapUri == null || mapUri.isEmpty) {
          throw const FormatException(
            'HLS initialization segment URI missing.',
          );
        }
        final resolvedMapUri = uri.resolve(mapUri);
        final mapByteRange = attributes['BYTERANGE'] == null
            ? null
            : _resolveByteRange(
                _parseByteRange(attributes['BYTERANGE']!),
                resourceUri: resolvedMapUri,
                previousUri: previousMapByteRangeUri,
                previousEnd: previousMapByteRangeEnd,
              );
        initializationSegment = HlsInitializationSegment(
          uri: resolvedMapUri,
          byteRange: mapByteRange,
        );
        if (mapByteRange != null) {
          previousMapByteRangeUri = resolvedMapUri;
          previousMapByteRangeEnd = mapByteRange.endInclusive;
        }
        continue;
      }
      if (line.startsWith('#EXT-X-KEY:')) {
        final attributes = _parseAttributes(
          line.substring('#EXT-X-KEY:'.length),
        );
        final method = attributes['METHOD']?.toUpperCase();
        if (method == 'NONE') {
          activeEncryptionKey = null;
          continue;
        }
        if (method != 'AES-128') {
          throw FormatException(
            'Unsupported HLS encryption method: ${method ?? 'missing'}.',
          );
        }
        final keyUri = attributes['URI'];
        if (keyUri == null || keyUri.isEmpty) {
          throw const FormatException('HLS encryption key URI missing.');
        }
        activeEncryptionKey = HlsEncryptionKey(
          method: method!,
          uri: uri.resolve(keyUri),
          iv: attributes['IV'],
        );
        continue;
      }
      if (line == '#EXT-X-DISCONTINUITY') {
        pendingDiscontinuity = true;
        continue;
      }
      if (line.startsWith('#EXT-X-BYTERANGE:')) {
        pendingByteRange = _parseByteRange(
          line.substring('#EXT-X-BYTERANGE:'.length),
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
        final byteRange = pendingByteRange == null
            ? null
            : _resolveByteRange(
                pendingByteRange,
                resourceUri: resolvedUri,
                previousUri: previousByteRangeUri,
                previousEnd: previousByteRangeEnd,
              );
        segments.add(
          HlsSegment(
            uri: resolvedUri,
            duration: pendingSegmentDuration,
            title: pendingSegmentTitle,
            encryptionKey: activeEncryptionKey,
            initializationSegment: initializationSegment,
            byteRange: byteRange,
            hasDiscontinuity: pendingDiscontinuity,
          ),
        );
        if (byteRange != null) {
          previousByteRangeUri = resolvedUri;
          previousByteRangeEnd = byteRange.endInclusive;
        }
        pendingByteRange = null;
        pendingSegmentDuration = null;
        pendingSegmentTitle = null;
        pendingDiscontinuity = false;
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
      mediaSequence: mediaSequence,
      targetDuration: targetDuration,
      initializationSegment: initializationSegment,
    );
  }

  _PendingByteRange _parseByteRange(String value) {
    final parts = value.trim().split('@');
    if (parts.length > 2) {
      throw const FormatException('Invalid HLS byte range.');
    }
    final length = int.tryParse(parts.first);
    final offset = parts.length == 2 ? int.tryParse(parts.last) : null;
    if (length == null || length <= 0 || (offset != null && offset < 0)) {
      throw const FormatException('Invalid HLS byte range.');
    }
    return _PendingByteRange(length: length, offset: offset);
  }

  HlsByteRange _resolveByteRange(
    _PendingByteRange pending, {
    required Uri resourceUri,
    required Uri? previousUri,
    required int? previousEnd,
  }) {
    final offset = pending.offset;
    if (offset != null) {
      return HlsByteRange(length: pending.length, offset: offset);
    }
    if (previousUri != resourceUri || previousEnd == null) {
      throw const FormatException(
        'HLS byte range without offset must follow the same resource.',
      );
    }
    return HlsByteRange(length: pending.length, offset: previousEnd + 1);
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

class _PendingByteRange {
  const _PendingByteRange({required this.length, this.offset});

  final int length;
  final int? offset;
}
