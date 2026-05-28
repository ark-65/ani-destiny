class Episode {
  const Episode({
    required this.id,
    required this.animeId,
    required this.title,
    this.index,
    this.sourceId,
    this.rawUrl,
  });

  final String id;
  final String animeId;
  final String title;
  final int? index;
  final String? sourceId;
  final String? rawUrl;
}
