import '../entities/anime.dart';
import '../entities/anime_detail.dart';
import '../entities/play_source.dart';
import '../entities/schedule_item.dart';
import '../entities/search_result.dart';
import '../../../source/domain/entities/source_fallback_result.dart';

abstract class AnimeRepository {
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations();

  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  });

  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId);

  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(
    String episodeId,
  );

  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule();

  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  });

  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  });
}
