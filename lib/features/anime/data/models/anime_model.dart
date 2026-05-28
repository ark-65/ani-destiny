import '../../domain/entities/anime.dart';

class AnimeModel {
  const AnimeModel({
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

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      originalTitle: json['originalTitle'] as String?,
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      sourceId: json['sourceId'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      year: json['year'] as int?,
      status: json['status'] as String?,
    );
  }

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

  Anime toEntity() {
    return Anime(
      id: id,
      title: title,
      originalTitle: originalTitle,
      coverUrl: coverUrl,
      description: description,
      tags: tags,
      sourceId: sourceId,
      rating: rating,
      year: year,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalTitle': originalTitle,
      'coverUrl': coverUrl,
      'description': description,
      'tags': tags,
      'sourceId': sourceId,
      'rating': rating,
      'year': year,
      'status': status,
    };
  }
}
