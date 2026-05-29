class HlsManifest {
  const HlsManifest({
    required this.uri,
    required this.segments,
    required this.variants,
    required this.isLive,
    this.targetDuration,
  });

  final Uri uri;
  final List<HlsSegment> segments;
  final List<HlsVariant> variants;
  final bool isLive;
  final Duration? targetDuration;

  bool get isMasterPlaylist => variants.isNotEmpty;
  bool get isMediaPlaylist => segments.isNotEmpty;
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
