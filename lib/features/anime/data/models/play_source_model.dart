import '../../domain/entities/play_source.dart';

class PlaySourceModel {
  const PlaySourceModel({
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

  PlaySource toEntity() {
    return PlaySource(
      id: id,
      episodeId: episodeId,
      title: title,
      url: url,
      quality: quality,
      headers: headers,
    );
  }
}
