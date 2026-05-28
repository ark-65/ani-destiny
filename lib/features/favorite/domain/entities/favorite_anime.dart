class FavoriteAnime {
  const FavoriteAnime({
    required this.animeId,
    required this.title,
    required this.sourceId,
    required this.createdAt,
    this.coverUrl,
  });

  final String animeId;
  final String title;
  final String? coverUrl;
  final String sourceId;
  final DateTime createdAt;
}
