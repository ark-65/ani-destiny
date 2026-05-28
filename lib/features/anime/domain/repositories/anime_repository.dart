import '../entities/anime.dart';
import '../entities/anime_detail.dart';
import '../entities/play_source.dart';
import '../entities/schedule_item.dart';
import '../entities/search_result.dart';

abstract class AnimeRepository {
  Future<List<Anime>> getHomeRecommendations();

  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  });

  Future<AnimeDetail> getAnimeDetail(String animeId);

  Future<List<PlaySource>> getPlaySources(String episodeId);

  Future<List<ScheduleItem>> getSchedule();
}
