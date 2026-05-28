import '../entities/play_source.dart';
import '../repositories/anime_repository.dart';

class GetPlaySources {
  const GetPlaySources(this._repository);

  final AnimeRepository _repository;

  Future<List<PlaySource>> call(String episodeId) {
    return _repository.getPlaySources(episodeId);
  }
}
