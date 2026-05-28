import '../entities/search_result.dart';
import '../repositories/anime_repository.dart';

class SearchAnime {
  const SearchAnime(this._repository);

  final AnimeRepository _repository;

  Future<List<SearchResult>> call(
    String keyword, {
    int page = 1,
  }) {
    return _repository.search(keyword, page: page);
  }
}
