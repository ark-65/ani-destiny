import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../../core/error/app_exception.dart';
import '../../../anime/domain/entities/anime.dart';
import '../../../anime/domain/entities/anime_detail.dart';
import '../../../anime/domain/entities/episode.dart';
import '../../../anime/domain/entities/play_source.dart';
import '../../../anime/domain/entities/schedule_item.dart';
import '../../../anime/domain/entities/search_result.dart';
import '../../domain/adapters/anime_source_adapter.dart';

class SakuraAnimeSourceAdapter implements AnimeSourceAdapter {
  SakuraAnimeSourceAdapter({
    required Dio dio,
    this.baseUrl = 'https://yhdm.one',
  }) : _dio = dio;

  final Dio _dio;
  final String baseUrl;

  @override
  String get id => 'sakura';

  @override
  String get name => 'Sakura Anime';

  @override
  String? get description =>
      'SakuraAnime-compatible source adapter backed by client-side parsing.';

  @override
  Future<List<Anime>> getHomeRecommendations() async {
    final document = await _getDocument('/');
    final cards = _parseAnimeCards(document);
    if (cards.isNotEmpty) return cards.take(24).toList(growable: false);

    final latest = await _getDocument('/latest/');
    return _parseLatestItems(latest)
        .take(24)
        .map(
          (item) => Anime(
            id: item.animeId,
            title: item.title,
            coverUrl: _coverUrlFor(item.animeId),
            tags: [if (item.region.isNotEmpty) item.region],
            sourceId: id,
            status: item.episodeTitle,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
  }) async {
    final query = keyword.trim();
    if (query.isEmpty) return const [];

    final document = await _getDocument(
      '/search',
      queryParameters: {
        'q': query,
        if (page > 1) 'page': page.toString(),
      },
    );
    return _parseSearchResults(document);
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    final idValue = _animeIdFromAny(animeId) ?? animeId;
    final document = await _getDocument('/vod/$idValue.html');
    final title = _clean(
      document.querySelector('.names')?.text ??
          document.querySelector('h1')?.text,
    );

    if (title.isEmpty) {
      throw const AppException(
        'Sakura Anime detail page did not contain a title.',
        code: 'sakura_parse_detail_title_failed',
      );
    }

    final episodes = _parseEpisodes(document, idValue);

    return AnimeDetail(
      id: idValue,
      title: title,
      coverUrl: _absoluteUrl(
        _imageSource(
          document.querySelector('.detail-poster img') ??
              document.querySelector('img[src*="/cover"]') ??
              document.querySelector('img[data-original*="/cover"]'),
        ),
      ),
      description: _extractDetailDescription(document),
      aliases: _splitAliases(_findLabeledValue(document, '别名')),
      tags: _extractDetailTags(document),
      episodes: episodes,
      sourceId: id,
    );
  }

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) async {
    final episodeRef = _episodeRefFromAny(episodeId);
    if (episodeRef == null) {
      throw AppException(
        'Sakura Anime episode id is not supported: $episodeId',
        code: 'sakura_invalid_episode_id',
      );
    }

    final response = await _getRaw(
      '/_get_plays/${episodeRef.animeId}/${episodeRef.episodeKey}',
      referer: '/vod-play/${episodeRef.animeId}/${episodeRef.episodeKey}.html',
    );
    final payload = _decodeJson(response);
    final plays = payload['video_plays'];

    if (plays is! List || plays.isEmpty) {
      throw const AppException(
        'Sakura Anime did not return playable sources.',
        code: 'sakura_no_play_sources',
      );
    }

    final sources = <PlaySource>[];
    for (var index = 0; index < plays.length; index++) {
      final item = plays[index];
      if (item is! Map) continue;

      final rawUrl = _clean(item['play_data']?.toString());
      if (rawUrl.isEmpty) continue;

      final playUrl = _absoluteUrl(rawUrl);
      if (playUrl == null) continue;

      final sourceName = _clean(item['src_site']?.toString());
      sources.add(
        PlaySource(
          id: '${episodeRef.id}-${sourceName.isEmpty ? index + 1 : sourceName}',
          episodeId: episodeRef.id,
          title: sourceName.isEmpty ? 'Sakura ${index + 1}' : sourceName,
          url: playUrl,
          quality: playUrl.contains('.m3u8') ? 'HLS' : null,
          headers: {
            'referer': _absoluteUrl(
              '/vod-play/${episodeRef.animeId}/${episodeRef.episodeKey}.html',
            )!,
          },
        ),
      );
    }

    if (sources.isEmpty) {
      throw const AppException(
        'Sakura Anime returned play data but no usable URL.',
        code: 'sakura_parse_play_sources_failed',
      );
    }

    return sources;
  }

  @override
  Future<List<ScheduleItem>> getSchedule() async {
    final document = await _getDocument('/latest/');
    return _parseLatestItems(document)
        .take(80)
        .map(
          (item) => ScheduleItem(
            id: 'sakura-latest-${item.episodeId}',
            animeId: item.animeId,
            title: item.title,
            coverUrl: _coverUrlFor(item.animeId),
            weekday: item.date?.weekday ?? DateTime.now().weekday,
            updateTime: [
              if (item.dateText.isNotEmpty) item.dateText,
              if (item.episodeTitle.isNotEmpty) item.episodeTitle,
            ].join(' '),
            sourceId: id,
          ),
        )
        .toList(growable: false);
  }

  Future<dom.Document> _getDocument(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final data = await _getRaw(path, queryParameters: queryParameters);
    return html_parser.parse(data);
  }

  Future<String> _getRaw(
    String path, {
    Map<String, String>? queryParameters,
    String? referer,
  }) async {
    try {
      final response = await _dio.getUri<String>(
        _uri(path, queryParameters: queryParameters),
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            if (referer != null) 'referer': _absoluteUrl(referer),
          },
        ),
      );
      final data = response.data;
      if (data == null || data.trim().isEmpty) {
        throw const AppException(
          'Sakura Anime returned an empty response.',
          code: 'sakura_empty_response',
        );
      }
      return data;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException(
        'Unable to load Sakura Anime content.',
        code: 'sakura_network_error',
        cause: error,
      );
    } on Object catch (error) {
      throw AppException(
        'Unexpected Sakura Anime adapter failure.',
        code: 'sakura_unexpected_error',
        cause: error,
      );
    }
  }

  Map<String, dynamic> _decodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object catch (error) {
      throw AppException(
        'Sakura Anime play response is not valid JSON.',
        code: 'sakura_play_json_failed',
        cause: error,
      );
    }

    throw const AppException(
      'Sakura Anime play response has an unexpected shape.',
      code: 'sakura_play_json_shape_failed',
    );
  }

  List<Anime> _parseAnimeCards(dom.Document document) {
    final byId = <String, Anime>{};

    for (final item in document.querySelectorAll('li')) {
      final link = item.querySelector('a[href^="/vod/"]');
      final href = link?.attributes['href'];
      final animeId = _animeIdFromVodHref(href);
      if (animeId == null || byId.containsKey(animeId)) continue;

      final title = _clean(
        link?.attributes['title'] ??
            link?.querySelector('[title]')?.attributes['title'] ??
            link?.text ??
            item.querySelector('img')?.attributes['alt'],
      );
      if (title.isEmpty) continue;

      final text = _clean(item.text);
      byId[animeId] = Anime(
        id: animeId,
        title: title,
        coverUrl: _absoluteUrl(_imageSource(item.querySelector('img'))),
        description: _extractDescriptionFromText(text),
        tags: _extractTagsFromText(text),
        sourceId: id,
        status: _extractLatestText(item),
      );
    }

    return byId.values.toList(growable: false);
  }

  List<SearchResult> _parseSearchResults(dom.Document document) {
    final byId = <String, SearchResult>{};
    final items = document.querySelectorAll('#search_list li').isEmpty
        ? document.querySelectorAll('li.clearfix')
        : document.querySelectorAll('#search_list li');

    for (final item in items) {
      final link = item.querySelector('h6 a[href^="/vod/"]') ??
          item.querySelector('a[href^="/vod/"]');
      final animeId = _animeIdFromVodHref(link?.attributes['href']);
      if (animeId == null || byId.containsKey(animeId)) continue;

      final title = _clean(
        link?.attributes['title'] ??
            link?.text ??
            item.querySelector('img')?.attributes['alt'],
      );
      if (title.isEmpty) continue;

      byId[animeId] = SearchResult(
        animeId: animeId,
        title: title,
        coverUrl: _absoluteUrl(_imageSource(item.querySelector('img'))),
        description: _extractDescriptionFromText(item.text),
        sourceId: id,
      );
    }

    return byId.values.toList(growable: false);
  }

  List<Episode> _parseEpisodes(dom.Document document, String animeId) {
    final byId = <String, Episode>{};
    final links = document.querySelectorAll(
      '.ep-panel a[href^="/vod-play/"], a[href^="/vod-play/"]',
    );

    for (final link in links) {
      final episodeRef = _episodeRefFromAny(link.attributes['href']);
      if (episodeRef == null || episodeRef.animeId != animeId) continue;
      if (byId.containsKey(episodeRef.id)) continue;

      final title = _clean(link.text);
      byId[episodeRef.id] = Episode(
        id: episodeRef.id,
        animeId: animeId,
        title: title.isEmpty ? episodeRef.episodeKey : title,
        index: _episodeIndexFrom(title),
        sourceId: id,
        rawUrl: _absoluteUrl(link.attributes['href']),
      );
    }

    final episodes = byId.values.toList(growable: false);
    if (episodes.every((episode) => episode.index != null)) {
      episodes.sort((a, b) => a.index!.compareTo(b.index!));
    }
    return episodes;
  }

  List<_LatestItem> _parseLatestItems(dom.Document document) {
    final items = <_LatestItem>[];
    final rows = document.querySelectorAll('.latest-ul li');

    for (final row in rows) {
      final link = row.querySelector('a.names[href^="/vod-play/"]') ??
          row.querySelector('a[href^="/vod-play/"]');
      final episodeRef = _episodeRefFromAny(link?.attributes['href']);
      if (episodeRef == null) continue;

      final title = _clean(
        row.querySelector('.name')?.text ??
            link?.attributes['title'] ??
            link?.text,
      );
      if (title.isEmpty) continue;

      final dateText = _clean(row.querySelector('em')?.text);
      items.add(
        _LatestItem(
          animeId: episodeRef.animeId,
          episodeId: episodeRef.id,
          title: title,
          episodeTitle: _clean(row.querySelector('.ep_name')?.text),
          region: _clean(row.querySelector('.region')?.text),
          dateText: dateText,
          date: DateTime.tryParse(dateText),
        ),
      );
    }

    return items;
  }

  String? _extractDetailDescription(dom.Document document) {
    for (final selector in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
      for (final heading in document.querySelectorAll(selector)) {
        if (!heading.text.contains('动漫介绍')) continue;

        var sibling = heading.nextElementSibling;
        while (sibling != null) {
          final text = _clean(sibling.text);
          if (sibling.localName != 'hr' &&
              text.isNotEmpty &&
              !text.contains('动漫介绍')) {
            return text;
          }
          sibling = sibling.nextElementSibling;
        }
      }
    }

    final bodyText = _clean(document.body?.text);
    final marker = bodyText.indexOf('动漫介绍');
    if (marker >= 0) {
      final description = bodyText.substring(marker + '动漫介绍'.length).trim();
      if (description.isNotEmpty) return description;
    }

    return _clean(
      document.querySelector('meta[name="description"]')?.attributes['content'],
    ).nullIfEmpty;
  }

  List<String> _extractDetailTags(dom.Document document) {
    for (final element in document.querySelectorAll('.mb-1')) {
      final text = _clean(element.text);
      if (!text.startsWith('类型')) continue;

      final linkedTags = element
          .querySelectorAll('a, span')
          .map((node) => _clean(node.text))
          .where((value) => value.isNotEmpty && !value.startsWith('类型'))
          .toSet()
          .toList(growable: false);
      if (linkedTags.isNotEmpty) return linkedTags;

      return _splitTags(text.replaceFirst(RegExp(r'^类型[:：]?'), ''));
    }

    return const [];
  }

  List<String> _extractTagsFromText(String text) {
    final marker = text.indexOf('类型');
    if (marker < 0) return const [];
    final rest = text.substring(marker).replaceFirst(RegExp(r'^类型[:：]?'), '');
    return _splitTags(rest);
  }

  List<String> _splitTags(String raw) {
    return raw
        .split(RegExp(r'[/／,，、|]+'))
        .map(_clean)
        .where((value) => value.isNotEmpty && value.length <= 12)
        .toList(growable: false);
  }

  String? _extractDescriptionFromText(String text) {
    final clean = _clean(text);
    final marker = clean.indexOf('简介：');
    if (marker < 0) return null;
    return clean.substring(marker + '简介：'.length).trim().nullIfEmpty;
  }

  String? _extractLatestText(dom.Element item) {
    final latest = _clean(item.querySelector('.red')?.text);
    if (latest.isNotEmpty) return latest;

    final text = _clean(item.text);
    final match = RegExp(r'(更至[^ ]+|更新至[^ ]+|第\d+集[^ ]*)').firstMatch(text);
    return match?.group(1);
  }

  String? _findLabeledValue(dom.Document document, String label) {
    for (final element in document.querySelectorAll('.mb-1, .small')) {
      final text = _clean(element.text);
      final pattern = RegExp('^$label[:：]\\s*(.+)');
      final match = pattern.firstMatch(text);
      if (match != null) return _clean(match.group(1)).nullIfEmpty;
    }
    return null;
  }

  List<String> _splitAliases(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[/／,，、]+'))
        .map(_clean)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  int? _episodeIndexFrom(String title) {
    final match = RegExp(r'第\s*0*(\d+)\s*[集话話]').firstMatch(title);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String? _imageSource(dom.Element? image) {
    if (image == null) return null;
    return image.attributes['data-original'] ??
        image.attributes['data-src'] ??
        image.attributes['src'];
  }

  String? _coverUrlFor(String animeId) => _absoluteUrl('/cover2/$animeId.jpg');

  String? _absoluteUrl(String? raw) {
    final value = _clean(raw);
    if (value.isEmpty) return null;
    return Uri.parse(_normalizedBase).resolve(value).toString();
  }

  Uri _uri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final rawPath = path.trim();
    final resolved = Uri.parse(_normalizedBase).resolve(
      rawPath == '/' ? '' : rawPath,
    );
    return queryParameters == null
        ? resolved
        : resolved.replace(queryParameters: queryParameters);
  }

  String get _normalizedBase => baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  String? _animeIdFromAny(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(value.trim())) return value.trim();
    return _animeIdFromVodHref(value) ?? _episodeRefFromAny(value)?.animeId;
  }

  String? _animeIdFromVodHref(String? href) {
    final value = href ?? '';
    final match = RegExp(r'/vod/(\d+)\.html').firstMatch(value);
    return match?.group(1);
  }

  _EpisodeRef? _episodeRefFromAny(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    final pathMatch = RegExp(
      r'/vod-play/(\d+)/([^/.]+)\.html',
    ).firstMatch(normalized);
    if (pathMatch != null) {
      return _EpisodeRef(
        animeId: pathMatch.group(1)!,
        episodeKey: pathMatch.group(2)!,
      );
    }

    final compactMatch = RegExp(r'^(\d+)/([^/.]+)$').firstMatch(normalized);
    if (compactMatch != null) {
      return _EpisodeRef(
        animeId: compactMatch.group(1)!,
        episodeKey: compactMatch.group(2)!,
      );
    }

    return null;
  }

  String _clean(String? value) {
    return value?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  }
}

class _EpisodeRef {
  const _EpisodeRef({
    required this.animeId,
    required this.episodeKey,
  });

  final String animeId;
  final String episodeKey;

  String get id => '$animeId/$episodeKey';
}

class _LatestItem {
  const _LatestItem({
    required this.animeId,
    required this.episodeId,
    required this.title,
    required this.episodeTitle,
    required this.region,
    required this.dateText,
    required this.date,
  });

  final String animeId;
  final String episodeId;
  final String title;
  final String episodeTitle;
  final String region;
  final String dateText;
  final DateTime? date;
}

extension _StringNullIfEmpty on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
