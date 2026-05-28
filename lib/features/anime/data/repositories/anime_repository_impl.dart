import '../../../source/domain/entities/source_fallback_result.dart';
import '../../../source/domain/services/source_fallback_service.dart';
import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/entities/play_source.dart';
import '../../domain/entities/schedule_item.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/anime_repository.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  const AnimeRepositoryImpl({
    required SourceFallbackService fallbackService,
  }) : _fallbackService = fallbackService;

  final SourceFallbackService _fallbackService;

  @override
  Future<SourceFallbackResult<List<Anime>>> getHomeRecommendations() {
    return _fallbackService.run<List<Anime>>(
      operation: 'home',
      action: (adapter) => adapter.getHomeRecommendations(),
      isFailureValue: (items) => items.isEmpty,
    );
  }

  @override
  Future<SourceFallbackResult<List<SearchResult>>> search(
    String keyword, {
    int page = 1,
  }) {
    return _fallbackService.run<List<SearchResult>>(
      operation: 'search',
      action: (adapter) => adapter.search(keyword, page: page),
    );
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetail(String animeId) {
    return _fallbackService.run<AnimeDetail>(
      operation: 'detail',
      action: (adapter) => adapter.getAnimeDetail(animeId),
      isFailureValue: _detailHasNoEpisodes,
    );
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySources(
    String episodeId,
  ) {
    return _fallbackService.run<List<PlaySource>>(
      operation: 'play_sources',
      action: (adapter) => adapter.getPlaySources(episodeId),
      isFailureValue: (items) => items.isEmpty,
    );
  }

  @override
  Future<SourceFallbackResult<List<ScheduleItem>>> getSchedule() {
    return _fallbackService.run<List<ScheduleItem>>(
      operation: 'schedule',
      action: (adapter) => adapter.getSchedule(),
    );
  }

  @override
  Future<SourceFallbackResult<AnimeDetail>> getAnimeDetailFromSource({
    required String sourceId,
    required String animeId,
  }) {
    return _fallbackService.run<AnimeDetail>(
      operation: 'detail',
      preferredSourceId: sourceId,
      action: (adapter) => adapter.getAnimeDetail(animeId),
      isFailureValue: _detailHasNoEpisodes,
    );
  }

  @override
  Future<SourceFallbackResult<List<PlaySource>>> getPlaySourcesFromSource({
    required String sourceId,
    required String episodeId,
  }) {
    return _fallbackService.run<List<PlaySource>>(
      operation: 'play_sources',
      preferredSourceId: sourceId,
      action: (adapter) => adapter.getPlaySources(episodeId),
      isFailureValue: (items) => items.isEmpty,
    );
  }

  bool _detailHasNoEpisodes(AnimeDetail detail) {
    return detail.episodes.isEmpty;
  }
}
