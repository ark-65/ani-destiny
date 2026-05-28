import '../entities/anime.dart';
import '../repositories/anime_repository.dart';

class GetHomeRecommendations {
  const GetHomeRecommendations(this._repository);

  final AnimeRepository _repository;

  Future<List<Anime>> call() {
    return _repository.getHomeRecommendations();
  }
}
