import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/danmaku_item.dart';
import '../../domain/entities/danmaku_match.dart';

abstract class DandanplayDanmakuDataSource {
  Future<List<DanmakuMatch>> match({
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  });

  Future<List<DanmakuItem>> getComments({
    required String matchId,
  });
}

class DandanplayCredentials {
  const DandanplayCredentials({
    required this.appId,
    required this.appSecret,
  });

  final String appId;
  final String appSecret;

  bool get isConfigured =>
      appId.trim().isNotEmpty && appSecret.trim().isNotEmpty;
}

class DioDandanplayDanmakuDataSource implements DandanplayDanmakuDataSource {
  const DioDandanplayDanmakuDataSource({
    required Dio dio,
    this.baseUrl = 'https://api.dandanplay.net',
    this.credentials = const DandanplayCredentials(appId: '', appSecret: ''),
  }) : _dio = dio;

  final Dio _dio;
  final String baseUrl;
  final DandanplayCredentials credentials;

  @override
  Future<List<DanmakuMatch>> match({
    required String animeTitle,
    required String episodeTitle,
    int? episodeIndex,
  }) async {
    if (!credentials.isConfigured) return const [];

    final normalizedEpisode = _episodeQuery(
      episodeTitle: episodeTitle,
      episodeIndex: episodeIndex,
    );
    final response = await _getJson(
      '/api/v2/search/episodes',
      operation: 'match',
      queryParameters: {
        'anime': animeTitle,
        if (normalizedEpisode != null) 'episode': normalizedEpisode,
      },
    );

    final data = _responseMap(response.data, 'match');
    if (data['success'] == false) {
      throw AppException(
        'Dandanplay match failed: ${data['errorMessage'] ?? 'remote API returned failure.'}',
        code: 'dandanplay_match_failed',
      );
    }

    final animes = data['animes'];
    if (animes is! List || animes.isEmpty) return const [];

    final matches = <DanmakuMatch>[];
    for (var animeOffset = 0; animeOffset < animes.length; animeOffset++) {
      final anime = animes[animeOffset];
      if (anime is! Map) continue;
      final matchedAnimeTitle = _clean(anime['animeTitle']?.toString());
      final episodes = anime['episodes'];
      if (episodes is! List) continue;
      for (var episodeOffset = 0;
          episodeOffset < episodes.length;
          episodeOffset++) {
        final episode = episodes[episodeOffset];
        if (episode is! Map) continue;
        final episodeId = _clean(episode['episodeId']?.toString());
        if (episodeId.isEmpty) continue;
        final matchedEpisodeTitle = _clean(episode['episodeTitle']?.toString());
        matches.add(
          DanmakuMatch(
            id: episodeId,
            animeTitle:
                matchedAnimeTitle.isEmpty ? animeTitle : matchedAnimeTitle,
            episodeTitle: matchedEpisodeTitle.isEmpty
                ? episodeTitle
                : matchedEpisodeTitle,
            episodeIndex: _extractEpisodeIndex(matchedEpisodeTitle),
            source: 'dandanplay',
            score: _scoreMatch(
              animeTitle: animeTitle,
              episodeTitle: episodeTitle,
              episodeIndex: episodeIndex,
              matchedAnimeTitle: matchedAnimeTitle,
              matchedEpisodeTitle: matchedEpisodeTitle,
              animeOffset: animeOffset,
              episodeOffset: episodeOffset,
            ),
          ),
        );
      }
    }

    return matches;
  }

  @override
  Future<List<DanmakuItem>> getComments({
    required String matchId,
  }) async {
    if (!credentials.isConfigured) return const [];

    final response = await _getJson(
      '/api/v2/comment/$matchId',
      operation: 'comments',
      queryParameters: const {
        'chConvert': 0,
        'withRelated': true,
      },
    );

    final data = _responseMap(response.data, 'comments');
    final comments = data['comments'];
    if (comments is! List || comments.isEmpty) return const [];

    return comments
        .whereType<Map>()
        .map(_mapComment)
        .whereType<DanmakuItem>()
        .toList(growable: false);
  }

  Future<Response<dynamic>> _getJson(
    String path, {
    required String operation,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(baseUrl).resolve(path).replace(
          queryParameters: queryParameters?.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
    try {
      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
          headers: {
            'Accept': 'application/json',
            ..._authHeaders(path),
          },
        ),
      );
      final statusCode = response.statusCode;
      if (statusCode != null && statusCode >= 400) {
        throw AppException(
          'Dandanplay $operation failed: HTTP $statusCode from remote API.',
          code: 'dandanplay_http_error',
        );
      }
      return response;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException(
        'Dandanplay $operation failed: network request could not be completed.',
        code: 'dandanplay_network_error',
        cause: error,
      );
    } on Object catch (error) {
      throw AppException(
        'Dandanplay $operation failed: unexpected data source error.',
        code: 'dandanplay_unexpected_error',
        cause: error,
      );
    }
  }

  Map<String, String> _authHeaders(String path) {
    if (!credentials.isConfigured) return const {};
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final signaturePayload =
        '${credentials.appId}$timestamp$path${credentials.appSecret}';
    final signature =
        base64Encode(sha256.convert(utf8.encode(signaturePayload)).bytes);
    return {
      'X-AppId': credentials.appId,
      'X-Timestamp': timestamp.toString(),
      'X-Signature': signature,
    };
  }

  Map<String, dynamic> _responseMap(Object? data, String operation) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw AppException(
      'Dandanplay $operation failed: response JSON shape is not supported.',
      code: 'dandanplay_json_shape_failed',
    );
  }

  DanmakuItem? _mapComment(Map<dynamic, dynamic> raw) {
    final id = _clean(raw['cid']?.toString());
    final text = _clean(raw['m']?.toString());
    final payload = _clean(raw['p']?.toString()).split(',');
    if (id.isEmpty || text.isEmpty || payload.length < 4) return null;

    final seconds = double.tryParse(payload[0]);
    final mode = int.tryParse(payload[1]);
    final color = int.tryParse(payload[2]);
    final sender = _clean(payload[3]);
    if (seconds == null || mode == null || color == null) return null;

    final type = switch (mode) {
      4 => DanmakuType.bottom,
      5 => DanmakuType.top,
      _ => DanmakuType.scroll,
    };

    return DanmakuItem(
      id: id,
      text: text,
      time: Duration(milliseconds: (seconds * 1000).round()),
      color: _argbColor(color),
      type: type,
      sender: sender.isEmpty ? null : sender,
      source: 'dandanplay',
    );
  }

  String? _episodeQuery({
    required String episodeTitle,
    int? episodeIndex,
  }) {
    if (episodeIndex != null) return episodeIndex.toString();
    final title = _clean(episodeTitle);
    if (title.isEmpty) return null;
    if (RegExp(r'全集|HD|正片|剧场版|Movie', caseSensitive: false).hasMatch(title)) {
      return 'movie';
    }
    final digitMatch = RegExp(r'第\s*0*(\d+)\s*[集话話]').firstMatch(title);
    if (digitMatch != null) return digitMatch.group(1);
    if (RegExp(r'^\d+$').hasMatch(title)) return title;
    return null;
  }

  int? _extractEpisodeIndex(String value) {
    final match = RegExp(r'第\s*0*(\d+)\s*[集话話]').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  double _scoreMatch({
    required String animeTitle,
    required String episodeTitle,
    required int? episodeIndex,
    required String matchedAnimeTitle,
    required String matchedEpisodeTitle,
    required int animeOffset,
    required int episodeOffset,
  }) {
    var score = 1.0 - (animeOffset * 0.03) - (episodeOffset * 0.01);
    if (_normalize(matchedAnimeTitle).contains(_normalize(animeTitle)) ||
        _normalize(animeTitle).contains(_normalize(matchedAnimeTitle))) {
      score += 0.5;
    }
    final matchedIndex = _extractEpisodeIndex(matchedEpisodeTitle);
    if (episodeIndex != null && matchedIndex == episodeIndex) score += 0.4;
    if (matchedEpisodeTitle.isNotEmpty &&
        _normalize(matchedEpisodeTitle).contains(_normalize(episodeTitle))) {
      score += 0.2;
    }
    return score;
  }

  int _argbColor(int rgb) {
    if (rgb < 0) return 0xFFFFFFFF;
    return rgb <= 0x00FFFFFF ? 0xFF000000 | rgb : rgb;
  }

  String _normalize(String value) => _clean(value).toLowerCase();

  String _clean(String? value) {
    return value?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  }
}
