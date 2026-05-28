import '../../../anime/domain/entities/anime.dart';
import '../../../anime/domain/entities/anime_detail.dart';
import '../../../anime/domain/entities/play_source.dart';
import '../../../anime/domain/entities/schedule_item.dart';
import '../../../anime/domain/entities/search_result.dart';

abstract class AnimeSourceAdapter {
  String get id;
  String get name;
  String? get description;

  Future<List<Anime>> getHomeRecommendations();

  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  });

  Future<AnimeDetail> getAnimeDetail(String animeId);

  Future<List<PlaySource>> getPlaySources(String episodeId);

  Future<List<ScheduleItem>> getSchedule();
}
