import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../anime/domain/entities/anime.dart';
import '../../../anime/domain/entities/anime_detail.dart';
import '../../../anime/domain/entities/play_source.dart';
import '../../../anime/domain/entities/schedule_item.dart';
import '../../../anime/domain/entities/search_result.dart';
import '../../domain/adapters/anime_source_adapter.dart';

class SakuraAnimeSourceAdapter implements AnimeSourceAdapter {
  SakuraAnimeSourceAdapter({
    required Dio dio,
    this.baseUrl = 'https://www.yinghua8.net',
  }) : _dio = dio;

  final Dio _dio;
  final String baseUrl;

  @override
  String get id => 'sakura';

  @override
  String get name => 'Sakura Anime';

  @override
  String? get description =>
      'Skeleton for future SakuraAnime-style HTML parsing. Disabled in v1.';

  @override
  Future<List<Anime>> getHomeRecommendations() {
    return _notImplemented<List<Anime>>('home recommendations');
  }

  @override
  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  }) {
    return _notImplemented<List<SearchResult>>('search');
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) {
    return _notImplemented<AnimeDetail>('anime detail');
  }

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) {
    return _notImplemented<List<PlaySource>>('play source resolution');
  }

  @override
  Future<List<ScheduleItem>> getSchedule() {
    return _notImplemented<List<ScheduleItem>>('weekly schedule');
  }

  Future<T> _notImplemented<T>(String flow) async {
    // TODO(anidestiny): Port SakuraAnime parsing into this adapter after the mock
    // app flow is stable; keep HTML parsing out of presentation pages.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _dio.options.baseUrl = baseUrl;
    throw AppException(
      'Sakura Anime $flow is not implemented yet.',
      code: 'sakura_not_implemented',
    );
  }
}
