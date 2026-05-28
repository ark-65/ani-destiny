class SearchResult {
  const SearchResult({
    required this.animeId,
    required this.title,
    required this.sourceId,
    this.coverUrl,
    this.description,
  });

  final String animeId;
  final String title;
  final String? coverUrl;
  final String? description;
  final String sourceId;
}
