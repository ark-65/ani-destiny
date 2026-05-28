import 'episode.dart';

class AnimeDetail {
  const AnimeDetail({
    required this.id,
    required this.title,
    required this.episodes,
    required this.sourceId,
    this.coverUrl,
    this.description,
    this.aliases = const [],
    this.tags = const [],
  });

  final String id;
  final String title;
  final String? coverUrl;
  final String? description;
  final List<String> aliases;
  final List<String> tags;
  final List<Episode> episodes;
  final String sourceId;
}
