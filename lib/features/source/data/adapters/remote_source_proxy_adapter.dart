import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../anime/domain/entities/anime.dart';
import '../../../anime/domain/entities/anime_detail.dart';
import '../../../anime/domain/entities/play_source.dart';
import '../../../anime/domain/entities/schedule_item.dart';
import '../../../anime/domain/entities/search_result.dart';
import '../../domain/adapters/anime_source_adapter.dart';

class RemoteSourceProxyAdapter implements AnimeSourceAdapter {
  RemoteSourceProxyAdapter({
    required Dio dio,
    required this.baseUrl,
  }) : _dio = dio;

  final Dio _dio;
  final String baseUrl;

  @override
  String get id => 'remote-proxy';

  @override
  String get name => 'Remote Source Proxy';

  @override
  String? get description =>
      'Future self-hosted proxy adapter. Not required for first version.';

  @override
  Future<List<Anime>> getHomeRecommendations() async {
    _ensureConfigured();
    final response = await _dio.get<List<dynamic>>('$baseUrl/home');
    return response.data
            ?.map((item) => _animeFromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  }) async {
    _ensureConfigured();
    final response = await _dio.get<List<dynamic>>(
      '$baseUrl/search',
      queryParameters: {
        'keyword': keyword,
        'page': page,
      },
    );
    return response.data
            ?.map((item) => _searchFromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) {
    // TODO(anidestiny): Define the SourceProxy detail response contract before
    // enabling this adapter in settings.
    return _notImplemented('detail');
  }

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) {
    // TODO(anidestiny): Define the SourceProxy play-source response contract before
    // enabling this adapter in settings.
    return _notImplemented('play sources');
  }

  @override
  Future<List<ScheduleItem>> getSchedule() {
    // TODO(anidestiny): Define the SourceProxy schedule response contract before
    // enabling this adapter in settings.
    return _notImplemented('schedule');
  }

  void _ensureConfigured() {
    if (baseUrl.trim().isEmpty) {
      throw const AppException(
        'Remote source proxy baseUrl is not configured.',
        code: 'remote_proxy_not_configured',
      );
    }
  }

  Future<T> _notImplemented<T>(String flow) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    throw AppException(
      'Remote source proxy $flow is not implemented yet.',
      code: 'remote_proxy_not_implemented',
    );
  }

  Anime _animeFromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      sourceId: id,
    );
  }

  SearchResult _searchFromJson(Map<String, dynamic> json) {
    return SearchResult(
      animeId: json['animeId'] as String,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      sourceId: id,
    );
  }
}
