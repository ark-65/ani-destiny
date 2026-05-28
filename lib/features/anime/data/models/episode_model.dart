import '../../domain/entities/episode.dart';

class EpisodeModel {
  const EpisodeModel({
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

  Episode toEntity() {
    return Episode(
      id: id,
      animeId: animeId,
      title: title,
      index: index,
      sourceId: sourceId,
      rawUrl: rawUrl,
    );
  }
}
