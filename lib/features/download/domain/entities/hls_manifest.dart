class HlsManifest {
  const HlsManifest({
    required this.uri,
    required this.segments,
    required this.variants,
    required this.isLive,
    this.targetDuration,
    this.initializationSegment,
  });

  final Uri uri;
  final List<HlsSegment> segments;
  final List<HlsVariant> variants;
  final bool isLive;
  final Duration? targetDuration;
  final HlsInitializationSegment? initializationSegment;

  bool get isMasterPlaylist => variants.isNotEmpty;
  bool get isMediaPlaylist => segments.isNotEmpty;
}

class HlsInitializationSegment {
  const HlsInitializationSegment({required this.uri});

  final Uri uri;
}

class HlsSegment {
  const HlsSegment({
    required this.uri,
    this.duration,
    this.title,
  });

  final Uri uri;
  final Duration? duration;
  final String? title;
}

class HlsVariant {
  const HlsVariant({
    required this.uri,
    this.bandwidth,
    this.resolution,
  });

  final Uri uri;
  final int? bandwidth;
  final String? resolution;
}
