class Anime {
  const Anime({
    required this.id,
    required this.title,
    this.originalTitle,
    this.coverUrl,
    this.description,
    this.tags = const [],
    this.sourceId,
    this.rating,
    this.year,
    this.status,
  });

  final String id;
  final String title;
  final String? originalTitle;
  final String? coverUrl;
  final String? description;
  final List<String> tags;
  final String? sourceId;
  final double? rating;
  final int? year;
  final String? status;
}
