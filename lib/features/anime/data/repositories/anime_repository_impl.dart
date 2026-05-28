import '../../../source/domain/repositories/source_repository.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/entities/play_source.dart';
import '../../domain/entities/schedule_item.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/anime_repository.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  const AnimeRepositoryImpl({
    required SourceRepository sourceRepository,
  }) : _sourceRepository = sourceRepository;

  final SourceRepository _sourceRepository;

  @override
  Future<List<Anime>> getHomeRecommendations() async {
    final adapter = await _sourceRepository.getCurrentAdapter();
    return adapter.getHomeRecommendations();
  }

  @override
  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  }) async {
    final adapter = await _sourceRepository.getCurrentAdapter();
    return adapter.search(keyword, page: page);
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    final adapter = await _sourceRepository.getCurrentAdapter();
    return adapter.getAnimeDetail(animeId);
  }

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) async {
    final adapter = await _sourceRepository.getCurrentAdapter();
    return adapter.getPlaySources(episodeId);
  }

  @override
  Future<List<ScheduleItem>> getSchedule() async {
    final adapter = await _sourceRepository.getCurrentAdapter();
    return adapter.getSchedule();
  }
}
