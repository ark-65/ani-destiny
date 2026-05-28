class PlaySource {
  const PlaySource({
    required this.id,
    required this.episodeId,
    required this.title,
    required this.url,
    this.quality,
    this.headers = const {},
  });

  final String id;
  final String episodeId;
  final String title;
  final String url;
  final String? quality;
  final Map<String, String> headers;
}
