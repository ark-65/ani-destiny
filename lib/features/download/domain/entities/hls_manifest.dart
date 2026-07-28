class HlsManifest {
  const HlsManifest({
    required this.uri,
    required this.segments,
    required this.variants,
    required this.isLive,
    this.renditions = const [],
    this.variables = const {},
    this.protocolVersion = 1,
    this.mediaSequence = 0,
    this.targetDuration,
    this.initializationSegment,
  });

  final Uri uri;
  final List<HlsSegment> segments;
  final List<HlsVariant> variants;
  final List<HlsRendition> renditions;
  final bool isLive;
  final Map<String, String> variables;
  final int protocolVersion;
  final int mediaSequence;
  final Duration? targetDuration;
  final HlsInitializationSegment? initializationSegment;

  bool get isMasterPlaylist => variants.isNotEmpty;
  bool get isMediaPlaylist => segments.isNotEmpty;
}

class HlsRendition {
  const HlsRendition({
    required this.type,
    required this.groupId,
    required this.name,
    required this.uri,
    this.isDefault = false,
    this.autoselect = false,
    this.language,
  });

  final String type;
  final String groupId;
  final String name;
  final Uri? uri;
  final bool isDefault;
  final bool autoselect;
  final String? language;
}

class HlsInitializationSegment {
  const HlsInitializationSegment({
    required this.uri,
    this.byteRange,
    this.encryptionKey,
  });

  final Uri uri;
  final HlsByteRange? byteRange;
  final HlsEncryptionKey? encryptionKey;
}

class HlsSegment {
  const HlsSegment({
    required this.uri,
    this.duration,
    this.title,
    this.encryptionKey,
    this.initializationSegment,
    this.byteRange,
    this.hasDiscontinuity = false,
    this.isGap = false,
  });

  final Uri uri;
  final Duration? duration;
  final String? title;
  final HlsEncryptionKey? encryptionKey;
  final HlsInitializationSegment? initializationSegment;
  final HlsByteRange? byteRange;
  final bool hasDiscontinuity;
  final bool isGap;
}

class HlsByteRange {
  const HlsByteRange({required this.length, required this.offset});

  final int length;
  final int offset;

  int get endInclusive => offset + length - 1;

  String get requestHeader => 'bytes=$offset-$endInclusive';
}

class HlsEncryptionKey {
  const HlsEncryptionKey({
    required this.method,
    required this.uri,
    this.iv,
  });

  final String method;
  final Uri uri;
  final String? iv;
}

class HlsVariant {
  const HlsVariant({
    required this.uri,
    this.bandwidth,
    this.resolution,
    this.audioGroupId,
    this.subtitlesGroupId,
    this.codecs,
  });

  final Uri uri;
  final int? bandwidth;
  final String? resolution;
  final String? audioGroupId;
  final String? subtitlesGroupId;
  final String? codecs;
}
