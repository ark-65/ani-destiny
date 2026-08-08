import '../../domain/entities/hls_manifest.dart';

class HlsManifestParser {
  const HlsManifestParser();

  HlsManifest parse(
    String content, {
    required Uri uri,
    Map<String, String> importedVariables = const {},
  }) {
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
    final renditions = <HlsRendition>[];
    final variables = <String, String>{};
    Duration? targetDuration;
    HlsStartPosition? startPosition;
    var protocolVersion = 1;
    var mediaSequence = 0;
    var discontinuitySequence = 0;
    Duration? pendingSegmentDuration;
    String? pendingSegmentTitle;
    Map<String, String>? pendingVariantAttributes;
    HlsInitializationSegment? initializationSegment;
    HlsEncryptionKey? activeEncryptionKey;
    var hasMediaOnlyPlaylistTags = false;
    var hasMasterOnlyPlaylistTags = false;
    _PendingByteRange? pendingByteRange;
    Uri? previousByteRangeUri;
    int? previousByteRangeEnd;
    Uri? previousMapByteRangeUri;
    int? previousMapByteRangeEnd;
    var pendingDiscontinuity = false;
    var pendingGap = false;
    DateTime? pendingProgramDateTime;
    var hasEndList = false;

    for (var index = 1; index < lines.length; index++) {
      final line = lines[index];
      if (pendingVariantAttributes != null && line.startsWith('#EXT')) {
        throw const FormatException('Invalid HLS variant URI.');
      }
      if (line == '#EXT-X-ENDLIST') {
        hasEndList = true;
        continue;
      }
      if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        hasMediaOnlyPlaylistTags = true;
        final value = int.tryParse(
          line.substring('#EXT-X-TARGETDURATION:'.length).trim(),
        );
        if (value == null || value <= 0) {
          throw const FormatException('Invalid HLS target duration.');
        }
        targetDuration = Duration(seconds: value);
        continue;
      }
      if (line.startsWith('#EXT-X-START:')) {
        if (startPosition != null) {
          throw const FormatException('Duplicate HLS start position.');
        }
        final attributes = _parseAttributes(
          line.substring('#EXT-X-START:'.length),
        );
        final timeOffset = double.tryParse(attributes['TIME-OFFSET'] ?? '');
        final precise = attributes['PRECISE'];
        if (timeOffset == null ||
            !timeOffset.isFinite ||
            (precise != null && precise != 'YES' && precise != 'NO')) {
          throw const FormatException('Invalid HLS start position.');
        }
        startPosition = HlsStartPosition(
          timeOffsetSeconds: timeOffset,
          precise: precise == 'YES',
        );
        continue;
      }
      if (line.startsWith('#EXT-X-VERSION:')) {
        final value = int.tryParse(
          line.substring('#EXT-X-VERSION:'.length).trim(),
        );
        if (value == null || value < 1) {
          throw const FormatException('Invalid HLS protocol version.');
        }
        protocolVersion = value;
        continue;
      }
      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        hasMediaOnlyPlaylistTags = true;
        final value = int.tryParse(
          line.substring('#EXT-X-MEDIA-SEQUENCE:'.length).trim(),
        );
        if (value == null || value < 0) {
          throw const FormatException('Invalid HLS media sequence.');
        }
        mediaSequence = value;
        continue;
      }
      if (line.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE:')) {
        hasMediaOnlyPlaylistTags = true;
        final value = int.tryParse(
          line.substring('#EXT-X-DISCONTINUITY-SEQUENCE:'.length).trim(),
        );
        if (value == null || value < 0) {
          throw const FormatException(
            'Invalid HLS discontinuity sequence.',
          );
        }
        discontinuitySequence = value;
        continue;
      }
      if (line.startsWith('#EXTINF:')) {
        hasMediaOnlyPlaylistTags = true;
        if (pendingSegmentDuration != null) {
          throw const FormatException('HLS segment URI missing.');
        }
        final info = line.substring('#EXTINF:'.length);
        final commaIndex = info.indexOf(',');
        final durationText =
            commaIndex == -1 ? info : info.substring(0, commaIndex);
        final title = commaIndex == -1 ? null : info.substring(commaIndex + 1);
        final seconds = double.tryParse(durationText.trim());
        if (seconds == null || !seconds.isFinite || seconds <= 0) {
          throw const FormatException('Invalid HLS segment duration.');
        }
        pendingSegmentDuration = Duration(
          milliseconds: (seconds * 1000).round(),
        );
        pendingSegmentTitle = title?.trim().isEmpty ?? true ? null : title;
        continue;
      }
      if (line.startsWith('#EXT-X-DEFINE:')) {
        final attributes = _parseAttributes(
          line.substring('#EXT-X-DEFINE:'.length),
        );
        final importedName = attributes['IMPORT'];
        if (importedName != null) {
          final importedValue = importedVariables[importedName];
          if (attributes.length != 1 ||
              importedValue == null ||
              variables.containsKey(importedName)) {
            throw const FormatException('Invalid HLS variable import.');
          }
          variables[importedName] = importedValue;
          continue;
        }
        final name = attributes['NAME'];
        final value = attributes['VALUE'];
        if (name == null ||
            value == null ||
            !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(name) ||
            variables.containsKey(name)) {
          throw const FormatException('Invalid HLS variable definition.');
        }
        variables[name] = _substituteVariables(value, variables);
        continue;
      }
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        if (pendingVariantAttributes != null) {
          throw const FormatException('Invalid HLS variant URI.');
        }
        pendingVariantAttributes = _parseAttributes(
          line.substring('#EXT-X-STREAM-INF:'.length),
        );
        hasMasterOnlyPlaylistTags = true;
        continue;
      }
      if (line.startsWith('#EXT-X-MEDIA:')) {
        hasMasterOnlyPlaylistTags = true;
        final attributes = _parseAttributes(
          line.substring('#EXT-X-MEDIA:'.length),
        );
        final type = attributes['TYPE'];
        if (type == null || type.isEmpty) {
          throw const FormatException('Invalid HLS media rendition.');
        }
        const supportedMediaTypes = {'AUDIO', 'VIDEO', 'SUBTITLES'};
        if (!supportedMediaTypes.contains(type)) {
          throw const FormatException('Invalid HLS media rendition type.');
        }
        final groupId = attributes['GROUP-ID'];
        final name = attributes['NAME'];
        final renditionUri = attributes['URI'];
        final defaultValue = attributes['DEFAULT'];
        final autoselectValue = attributes['AUTOSELECT'];
        if (groupId == null ||
            groupId.isEmpty ||
            name == null ||
            name.isEmpty ||
            (renditionUri != null && renditionUri.isEmpty)) {
          throw const FormatException('Invalid HLS media rendition.');
        }
        if ((defaultValue != null &&
                defaultValue != 'YES' &&
                defaultValue != 'NO') ||
            (autoselectValue != null &&
                autoselectValue != 'YES' &&
                autoselectValue != 'NO') ||
            (defaultValue == 'YES' && autoselectValue == 'NO')) {
          throw const FormatException(
            'Invalid HLS audio selection attributes.',
          );
        }
        renditions.add(
          HlsRendition(
            type: type,
            groupId: groupId,
            name: name,
            uri: renditionUri == null
                ? null
                : uri.resolve(_substituteVariables(renditionUri, variables)),
            isDefault: defaultValue == 'YES',
            autoselect: autoselectValue == 'YES',
            language: attributes['LANGUAGE'],
          ),
        );
        continue;
      }
      if (line.startsWith('#EXT-X-SESSION-DATA:') ||
          line.startsWith('#EXT-X-SESSION-KEY:')) {
        hasMasterOnlyPlaylistTags = true;
        continue;
      }
      if (line.startsWith('#EXT-X-MAP:')) {
        hasMediaOnlyPlaylistTags = true;
        final attributes = _parseAttributes(
          line.substring('#EXT-X-MAP:'.length),
        );
        final mapUri = attributes['URI'];
        if (mapUri == null || mapUri.isEmpty) {
          throw const FormatException(
            'HLS initialization segment URI missing.',
          );
        }
        final resolvedMapUri = uri.resolve(
          _substituteVariables(mapUri, variables),
        );
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
          encryptionKey: activeEncryptionKey,
        );
        if (mapByteRange != null) {
          previousMapByteRangeUri = resolvedMapUri;
          previousMapByteRangeEnd = mapByteRange.endInclusive;
        }
        continue;
      }
      if (line.startsWith('#EXT-X-KEY:')) {
        hasMediaOnlyPlaylistTags = true;
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
        final keyFormat = attributes['KEYFORMAT'] ?? 'identity';
        if (keyFormat != 'identity') {
          throw FormatException(
            'Unsupported HLS encryption key format: $keyFormat.',
          );
        }
        final keyUri = attributes['URI'];
        if (keyUri == null || keyUri.isEmpty) {
          throw const FormatException('HLS encryption key URI missing.');
        }
        final iv = attributes['IV'];
        if (iv != null && !RegExp(r'^0[xX][0-9a-fA-F]{32}$').hasMatch(iv)) {
          throw const FormatException('Invalid HLS AES-128 IV.');
        }
        activeEncryptionKey = HlsEncryptionKey(
          method: method!,
          uri: uri.resolve(_substituteVariables(keyUri, variables)),
          iv: iv,
        );
        continue;
      }
      if (line == '#EXT-X-DISCONTINUITY') {
        hasMediaOnlyPlaylistTags = true;
        pendingDiscontinuity = true;
        continue;
      }
      if (line == '#EXT-X-GAP') {
        hasMediaOnlyPlaylistTags = true;
        pendingGap = true;
        continue;
      }
      if (line.startsWith('#EXT-X-PROGRAM-DATE-TIME:')) {
        hasMediaOnlyPlaylistTags = true;
        final value = line.substring('#EXT-X-PROGRAM-DATE-TIME:'.length).trim();
        final parsed = DateTime.tryParse(value);
        if (parsed == null) {
          throw const FormatException('Invalid HLS program date time.');
        }
        pendingProgramDateTime = parsed;
        continue;
      }
      if (line.startsWith('#EXT-X-BYTERANGE:')) {
        hasMediaOnlyPlaylistTags = true;
        pendingByteRange = _parseByteRange(
          line.substring('#EXT-X-BYTERANGE:'.length),
        );
        continue;
      }
      if (line.startsWith('#')) {
        continue;
      }

      final resolvedUri = uri.resolve(_substituteVariables(line, variables));
      if (pendingVariantAttributes != null) {
        final bandwidth = int.tryParse(
          pendingVariantAttributes['BANDWIDTH'] ?? '',
        );
        if (bandwidth == null || bandwidth <= 0) {
          throw const FormatException('Invalid HLS variant bandwidth.');
        }
        final audioGroupId = pendingVariantAttributes['AUDIO'];
        if (audioGroupId != null && audioGroupId.isEmpty) {
          throw const FormatException('Invalid HLS variant audio group.');
        }
        final videoGroupId = pendingVariantAttributes['VIDEO'];
        if (videoGroupId != null && videoGroupId.isEmpty) {
          throw const FormatException('Invalid HLS variant video group.');
        }
        final subtitlesGroupId = pendingVariantAttributes['SUBTITLES'];
        if (subtitlesGroupId != null && subtitlesGroupId.isEmpty) {
          throw const FormatException('Invalid HLS variant subtitles group.');
        }
        variants.add(
          HlsVariant(
            uri: resolvedUri,
            bandwidth: bandwidth,
            resolution: pendingVariantAttributes['RESOLUTION'],
            audioGroupId: audioGroupId,
            videoGroupId: videoGroupId,
            subtitlesGroupId: subtitlesGroupId,
            codecs: pendingVariantAttributes['CODECS'],
          ),
        );
        pendingVariantAttributes = null;
      } else {
        if (pendingSegmentDuration == null) {
          throw const FormatException('HLS segment duration missing.');
        }
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
            isGap: pendingGap,
            programDateTime: pendingProgramDateTime,
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
        pendingGap = false;
        pendingProgramDateTime = null;
      }
    }

    final defaultAudioGroups = <String>{};
    for (final rendition in renditions.where((item) => item.isDefault)) {
      if (!defaultAudioGroups.add(rendition.groupId)) {
        throw const FormatException(
          'HLS audio group contains multiple default renditions.',
        );
      }
    }

    if (pendingVariantAttributes != null) {
      throw const FormatException('Invalid HLS variant URI.');
    }
    if (pendingSegmentDuration != null) {
      throw const FormatException('HLS segment URI missing.');
    }
    if (segments.isNotEmpty && variants.isNotEmpty) {
      throw const FormatException('Invalid HLS mixed playlist type.');
    }
    if (segments.isNotEmpty && hasMasterOnlyPlaylistTags) {
      throw const FormatException('Invalid HLS master tag in media playlist.');
    }
    if (variants.isNotEmpty && hasMediaOnlyPlaylistTags) {
      throw const FormatException('Invalid HLS media tag in master playlist.');
    }
    if (segments.isEmpty && variants.isEmpty) {
      throw const FormatException('HLS manifest contains no media entries.');
    }
    if (segments.isNotEmpty) {
      final declaredTargetDuration = targetDuration;
      if (declaredTargetDuration == null) {
        throw const FormatException('HLS target duration missing.');
      }
      final longestRoundedSegmentSeconds = segments
          .map(
            (segment) => (segment.duration!.inMilliseconds / 1000).round(),
          )
          .reduce((longest, current) => longest > current ? longest : current);
      if (longestRoundedSegmentSeconds > declaredTargetDuration.inSeconds) {
        throw const FormatException(
          'HLS target duration is shorter than a media segment.',
        );
      }
    }

    return HlsManifest(
      uri: uri,
      segments: List.unmodifiable(segments),
      variants: List.unmodifiable(variants),
      renditions: List.unmodifiable(renditions),
      isLive: !hasEndList,
      variables: Map.unmodifiable(variables),
      protocolVersion: protocolVersion,
      mediaSequence: mediaSequence,
      discontinuitySequence: discontinuitySequence,
      targetDuration: targetDuration,
      startPosition: startPosition,
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

  String _substituteVariables(
    String value,
    Map<String, String> variables,
  ) {
    final variablePattern = RegExp(r'\{\$([A-Za-z0-9_-]+)\}');
    final substituted = value.replaceAllMapped(variablePattern, (match) {
      final name = match.group(1)!;
      final replacement = variables[name];
      if (replacement == null) {
        throw FormatException('Undefined HLS variable: $name.');
      }
      return replacement;
    });
    if (substituted.contains(r'{$')) {
      throw const FormatException('Invalid HLS variable reference.');
    }
    return substituted;
  }

  Map<String, String> _parseAttributes(String value) {
    final attributes = <String, String>{};
    final parts = <String>[];
    final current = StringBuffer();
    var insideQuotes = false;
    for (final codeUnit in value.codeUnits) {
      final character = String.fromCharCode(codeUnit);
      if (character == '"') {
        insideQuotes = !insideQuotes;
      }
      if (character == ',' && !insideQuotes) {
        parts.add(current.toString());
        current.clear();
      } else {
        current.write(character);
      }
    }
    if (insideQuotes) {
      throw const FormatException('Invalid HLS attribute list.');
    }
    parts.add(current.toString());

    for (final part in parts) {
      final equalsIndex = part.indexOf('=');
      if (equalsIndex == -1) continue;
      final key = part.substring(0, equalsIndex).trim();
      final rawValue = part.substring(equalsIndex + 1).trim();
      attributes[key] = rawValue.length >= 2 &&
              rawValue.startsWith('"') &&
              rawValue.endsWith('"')
          ? rawValue.substring(1, rawValue.length - 1)
          : rawValue;
    }
    return attributes;
  }
}

class _PendingByteRange {
  const _PendingByteRange({required this.length, this.offset});

  final int length;
  final int? offset;
}
