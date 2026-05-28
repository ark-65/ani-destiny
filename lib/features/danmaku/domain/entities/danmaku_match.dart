class DanmakuMatch {
  const DanmakuMatch({
    required this.id,
    required this.animeTitle,
    required this.episodeTitle,
    this.episodeIndex,
    this.source,
    this.score,
  });

  final String id;
  final String animeTitle;
  final String episodeTitle;
  final int? episodeIndex;
  final String? source;
  final double? score;
}
