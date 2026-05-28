import '../../domain/entities/anime_detail.dart';
import 'episode_model.dart';

class AnimeDetailModel {
  const AnimeDetailModel({
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
  final List<EpisodeModel> episodes;
  final String sourceId;

  AnimeDetail toEntity() {
    return AnimeDetail(
      id: id,
      title: title,
      coverUrl: coverUrl,
      description: description,
      aliases: aliases,
      tags: tags,
      episodes: episodes.map((episode) => episode.toEntity()).toList(),
      sourceId: sourceId,
    );
  }
}
