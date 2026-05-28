import '../../domain/entities/search_result.dart';

class SearchResultModel {
  const SearchResultModel({
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

  SearchResult toEntity() {
    return SearchResult(
      animeId: animeId,
      title: title,
      coverUrl: coverUrl,
      description: description,
      sourceId: sourceId,
    );
  }
}
