import '../entities/anime_detail.dart';
import '../repositories/anime_repository.dart';

class GetAnimeDetail {
  const GetAnimeDetail(this._repository);

  final AnimeRepository _repository;

  Future<AnimeDetail> call(String animeId) {
    return _repository.getAnimeDetail(animeId);
  }
}
