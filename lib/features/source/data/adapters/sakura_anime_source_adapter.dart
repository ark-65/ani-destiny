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
import '../../domain/entities/source_diagnostic.dart';
import '../../domain/services/source_diagnostic_recorder.dart';

class SakuraAnimeSourceAdapter implements AnimeSourceAdapter {
  SakuraAnimeSourceAdapter({
    required Dio dio,
    SourceDiagnosticRecorder diagnosticRecorder =
        const NoopSourceDiagnosticRecorder(),
    this.baseUrl = 'https://yhdm.one',
  })  : _dio = dio,
        _diagnostics = diagnosticRecorder;

  static const _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) AniDestiny/1.0 Safari/537.36';

  final Dio _dio;
  final SourceDiagnosticRecorder _diagnostics;
  final String baseUrl;

  @override
  String get id => 'sakura';

  @override
  String get name => 'Sakura Anime';

  @override
  String? get description => 'Website parser source. Experimental.';

  @override
  Future<List<Anime>> getHomeRecommendations() async {
    final document = await _getDocument('/', operation: 'home');
    final cards = _parseAnimeCards(document);
    if (cards.isNotEmpty) return cards.take(24).toList(growable: false);

    _record(
      SourceDiagnosticLevel.warning,
      'home',
      'Sakura home primary selectors returned no items; trying latest page.',
      url: _resolveUri('/').toString(),
    );
    final latest = await _getDocument('/latest/', operation: 'home');
    final items = _parseLatestItems(latest);
    if (items.isEmpty) {
      throw _parserFailure(
        'home',
        'Sakura home failed: no recommendation items found.',
        code: 'sakura_home_empty',
        url: _resolveUri('/latest/').toString(),
      );
    }

    return items
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
      operation: 'search',
    );
    return _parseSearchResults(document);
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async {
    final idValue = _normalizeAnimeId(animeId) ?? animeId;
    final document =
        await _getDocument('/vod/$idValue.html', operation: 'detail');
    final title = _extractDetailTitle(document);

    if (title.isEmpty) {
      throw _parserFailure(
        'detail',
        'Sakura detail failed: cannot parse title.',
        code: 'sakura_parse_detail_title_failed',
        url: _resolveUri('/vod/$idValue.html').toString(),
      );
    }

    final episodes = _parseEpisodes(document, idValue);
    if (episodes.isEmpty) {
      throw _parserFailure(
        'detail',
        'Sakura detail failed: cannot parse episode list.',
        code: 'sakura_parse_detail_episodes_failed',
        url: _resolveUri('/vod/$idValue.html').toString(),
      );
    }

    return AnimeDetail(
      id: idValue,
      title: title,
      coverUrl: _absoluteUrl(
        _imageSource(
          document.querySelector('.detail-poster img') ??
              document.querySelector('div.thumb img') ??
              document.querySelector('img[src*="/cover"]') ??
              document.querySelector('img[data-original*="/cover"]') ??
              document.querySelector('meta[property="og:image"]'),
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
    final episodeRef = _normalizeEpisodeId(episodeId);
    if (episodeRef == null) {
      throw _parserFailure(
        'play',
        'Sakura play source failed: unsupported episode id $episodeId.',
        code: 'sakura_invalid_episode_id',
      );
    }

    final playPath =
        '/vod-play/${episodeRef.animeId}/${episodeRef.episodeKey}.html';
    final apiPath =
        '/_get_plays/${episodeRef.animeId}/${episodeRef.episodeKey}';
    final referer = _resolveUri(playPath).toString();

    try {
      final response = await _getHtml(
        apiPath,
        operation: 'play',
        referer: playPath,
      );
      final sources = _parsePlaySourcesPayload(
        response.data ?? '',
        episodeRef,
        referer,
      );
      if (sources.isNotEmpty) return sources;

      _record(
        SourceDiagnosticLevel.warning,
        'play',
        'Sakura play API returned no usable source; trying play page scripts.',
        url: response.realUri.toString(),
        statusCode: response.statusCode,
      );
    } on AppException catch (error) {
      _record(
        SourceDiagnosticLevel.warning,
        'play',
        'Sakura play API failed; trying play page scripts.',
        url: _resolveUri(apiPath).toString(),
        exceptionType: error.runtimeType.toString(),
      );
    }

    final page = await _getHtml(playPath, operation: 'play', referer: playPath);
    final sources =
        _parsePlaySourcesPayload(page.data ?? '', episodeRef, referer);
    if (sources.isEmpty) {
      throw _parserFailure(
        'play',
        'Sakura play source failed: video_plays script or media URL not found.',
        code: 'sakura_parse_play_sources_failed',
        url: page.realUri.toString(),
      );
    }
    return sources;
  }

  @override
  Future<List<ScheduleItem>> getSchedule() async {
    final document = await _getDocument('/latest/', operation: 'schedule');
    final items = _parseLatestItems(document);
    if (items.isEmpty) {
      _record(
        SourceDiagnosticLevel.warning,
        'schedule',
        'Sakura schedule returned no latest items.',
        url: _resolveUri('/latest/').toString(),
      );
      return const [];
    }

    return items
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
    String pathOrUrl, {
    Map<String, dynamic>? queryParameters,
    required String operation,
    String? referer,
  }) async {
    final response = await _getHtml(
      pathOrUrl,
      queryParameters: queryParameters,
      operation: operation,
      referer: referer,
    );
    return html_parser.parse(response.data ?? '');
  }

  Future<Response<String>> _getHtml(
    String pathOrUrl, {
    Map<String, dynamic>? queryParameters,
    String operation = 'unknown',
    String? referer,
  }) async {
    final uri =
        _resolveUri(pathOrUrl).replace(queryParameters: queryParameters);
    final refererUrl = referer == null ? null : _resolveUri(referer).toString();
    try {
      final response = await _dio.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
          headers: {
            'User-Agent': _userAgent,
            'Accept': 'text/html,application/json;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.7,ja;q=0.5',
            if (refererUrl != null) 'Referer': refererUrl,
          },
        ),
      );

      final statusCode = response.statusCode;
      if (statusCode != null && statusCode >= 400) {
        throw _networkFailure(
          operation,
          'Sakura $operation failed: HTTP $statusCode from upstream.',
          code: 'sakura_http_error',
          url: uri.toString(),
          statusCode: statusCode,
        );
      }

      if ((response.data ?? '').trim().isEmpty) {
        throw _networkFailure(
          operation,
          'Sakura $operation failed: upstream returned an empty response.',
          code: 'sakura_empty_response',
          url: uri.toString(),
          statusCode: statusCode,
        );
      }

      return response;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _networkFailure(
        operation,
        'Sakura $operation failed: network request could not be completed.',
        code: 'sakura_network_error',
        url: uri.toString(),
        statusCode: error.response?.statusCode,
        exception: error,
      );
    } on Object catch (error) {
      throw _networkFailure(
        operation,
        'Sakura $operation failed: unexpected adapter error.',
        code: 'sakura_unexpected_error',
        url: uri.toString(),
        exception: error,
      );
    }
  }

  List<Anime> _parseAnimeCards(dom.Document document) {
    final byId = <String, Anime>{};
    final candidates = <dom.Element>[
      ...document.querySelectorAll('li'),
      ...document.querySelectorAll('.lpic li, .img li, .pics li'),
      ...document.querySelectorAll('article, .vodlist__item'),
    ];

    for (final item in candidates) {
      final link = item.querySelector('a[href*="/vod/"]');
      final animeId = _normalizeAnimeId(link?.attributes['href']);
      if (animeId == null || byId.containsKey(animeId)) continue;

      final title = _clean(
        link?.attributes['title'] ??
            link?.querySelector('[title]')?.attributes['title'] ??
            item.querySelector('img')?.attributes['alt'] ??
            link?.text,
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
    final items = <dom.Element>[
      ...document.querySelectorAll('#search_list li'),
      ...document.querySelectorAll('li.clearfix'),
      ...document.querySelectorAll('div.lpic li'),
      ...document.querySelectorAll('li'),
    ];

    for (final item in items) {
      final link = item.querySelector('h6 a[href*="/vod/"]') ??
          item.querySelector('h2 a[href*="/vod/"]') ??
          item.querySelector('a[href*="/vod/"]');
      final animeId = _normalizeAnimeId(link?.attributes['href']);
      if (animeId == null || byId.containsKey(animeId)) continue;

      final title = _clean(
        link?.attributes['title'] ??
            item.querySelector('img')?.attributes['alt'] ??
            link?.text,
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
    final links = <dom.Element>[
      ...document.querySelectorAll('.ep-panel a[href*="/vod-play/"]'),
      ...document.querySelectorAll('div.movurl a[href], div.movurls a[href]'),
      ...document.querySelectorAll('a[href*="/vod-play/"]'),
    ];

    for (final link in links) {
      final episodeRef = _normalizeEpisodeId(link.attributes['href']);
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
    final seenEpisodeIds = <String>{};
    final rows = <dom.Element>[
      ...document.querySelectorAll('.latest-ul li'),
      ...document.querySelectorAll('li'),
    ];

    for (final row in rows) {
      final link = row.querySelector('a.names[href*="/vod-play/"]') ??
          row.querySelector('a[href*="/vod-play/"]');
      final episodeRef = _normalizeEpisodeId(link?.attributes['href']);
      if (episodeRef == null) continue;
      if (!seenEpisodeIds.add(episodeRef.id)) continue;

      final linkText = _clean(link?.text);
      final title = _clean(
        row.querySelector('.name')?.text ??
            link?.attributes['title'] ??
            _stripEpisodeSuffix(linkText),
      );
      if (title.isEmpty) continue;

      final rowText = _clean(row.text);
      final dateText = _clean(
        row.querySelector('em')?.text ??
            RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(rowText)?.group(0),
      );
      items.add(
        _LatestItem(
          animeId: episodeRef.animeId,
          episodeId: episodeRef.id,
          title: title,
          episodeTitle: _clean(row.querySelector('.ep_name')?.text) |
              _extractEpisodeTitle(rowText),
          region: _clean(row.querySelector('.region')?.text) |
              _extractRegion(rowText),
          dateText: dateText,
          date: DateTime.tryParse(dateText),
        ),
      );
    }

    return items;
  }

  List<PlaySource> _parsePlaySourcesPayload(
    String raw,
    _EpisodeRef episodeRef,
    String referer,
  ) {
    final sources = <PlaySource>[];
    final decoded = _tryDecodeJsonMap(raw);
    final plays = decoded?['video_plays'];
    if (plays is List) {
      sources.addAll(_playSourcesFromList(plays, episodeRef, referer));
    }

    if (sources.isEmpty) {
      sources.addAll(_playSourcesFromScripts(raw, episodeRef, referer));
    }

    if (sources.isEmpty) {
      sources.addAll(_playSourcesFromDirectUrls(raw, episodeRef, referer));
    }

    final byUrl = <String, PlaySource>{};
    for (final source in sources) {
      byUrl.putIfAbsent(source.url, () => source);
    }
    return byUrl.values.toList(growable: false);
  }

  List<PlaySource> _playSourcesFromList(
    List<dynamic> plays,
    _EpisodeRef episodeRef,
    String referer,
  ) {
    final sources = <PlaySource>[];
    for (var index = 0; index < plays.length; index++) {
      final item = plays[index];
      if (item is! Map) continue;

      final rawUrl = _clean(
        item['play_data']?.toString() ??
            item['url']?.toString() ??
            item['file']?.toString() ??
            item['src']?.toString(),
      );
      final playUrl = _absoluteUrl(_unescapeUrl(rawUrl));
      if (playUrl == null) continue;

      final sourceName = _clean(
        item['src_site']?.toString() ??
            item['name']?.toString() ??
            item['title']?.toString(),
      );
      sources.add(_playSource(episodeRef, playUrl, referer, index, sourceName));
    }
    return sources;
  }

  List<PlaySource> _playSourcesFromScripts(
    String raw,
    _EpisodeRef episodeRef,
    String referer,
  ) {
    final document = html_parser.parse(raw);
    final sources = <PlaySource>[];
    for (final script in document.querySelectorAll('script')) {
      final scriptText = script.text;
      final arrayMatch = RegExp(
        r'''["']?video_plays["']?\s*[:=]\s*(\[[\s\S]*?\])\s*[;,}]''',
      ).firstMatch(scriptText);
      if (arrayMatch != null) {
        final decoded = _tryDecodeJsonList(arrayMatch.group(1)!);
        if (decoded != null) {
          sources.addAll(
            _playSourcesFromList(decoded, episodeRef, referer),
          );
        }
      }
    }
    return sources;
  }

  List<PlaySource> _playSourcesFromDirectUrls(
    String raw,
    _EpisodeRef episodeRef,
    String referer,
  ) {
    final sources = <PlaySource>[];
    final matches = RegExp(
      r'''(https?:\\?/\\?/[^'"\s<>]+\.(?:m3u8|mp4)(?:\?[^'"\s<>]*)?|/[^'"\s<>]+\.(?:m3u8|mp4)(?:\?[^'"\s<>]*)?)''',
      caseSensitive: false,
    ).allMatches(raw);
    var index = 0;
    for (final match in matches) {
      final url = _absoluteUrl(_unescapeUrl(match.group(1) ?? ''));
      if (url == null) continue;
      sources.add(_playSource(episodeRef, url, referer, index++, ''));
    }
    return sources;
  }

  PlaySource _playSource(
    _EpisodeRef episodeRef,
    String playUrl,
    String referer,
    int index,
    String sourceName,
  ) {
    return PlaySource(
      id: '${episodeRef.id}-${sourceName.isEmpty ? index + 1 : sourceName}',
      episodeId: episodeRef.id,
      title: sourceName.isEmpty ? 'Sakura ${index + 1}' : sourceName,
      url: playUrl,
      quality: playUrl.toLowerCase().contains('.m3u8') ? 'HLS' : 'Direct',
      headers: {
        'Referer': referer,
        'User-Agent': _userAgent,
      },
    );
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object {
      return null;
    }
    return null;
  }

  List<dynamic>? _tryDecodeJsonList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } on Object {
      return null;
    }
  }

  String _extractDetailTitle(dom.Document document) {
    final candidates = [
      document.querySelector('.names')?.text,
      document.querySelector('h1')?.text,
      document.querySelector('h2.title')?.text,
      document
          .querySelector('meta[property="og:title"]')
          ?.attributes['content'],
      document.querySelector('title')?.text,
    ];
    for (final candidate in candidates) {
      final title = _clean(candidate)
          .replaceFirst(RegExp(r'\s*[-_–|].*樱花动漫.*$'), '')
          .trim();
      if (title.isNotEmpty && title != '樱花动漫') return title;
    }
    return '';
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

    final direct = _clean(
      document.querySelector('div.info')?.text ??
          document.querySelector('.detail-info')?.text,
    );
    if (direct.isNotEmpty) return direct;

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
    for (final element in document.querySelectorAll('.mb-1, .sinfo span')) {
      final text = _clean(element.text);
      if (!text.startsWith('类型') && element.querySelectorAll('a').isEmpty) {
        continue;
      }

      final linkedTags = element
          .querySelectorAll('a, span')
          .map((node) => _clean(node.text))
          .where((value) => value.isNotEmpty && !value.startsWith('类型'))
          .toSet()
          .toList(growable: false);
      if (linkedTags.isNotEmpty) return linkedTags;

      if (text.startsWith('类型')) {
        return _splitTags(text.replaceFirst(RegExp(r'^类型[:：]?'), ''));
      }
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
    for (final element
        in document.querySelectorAll('.mb-1, .small, .sinfo span')) {
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
        image.attributes['src'] ??
        image.attributes['content'];
  }

  String? _coverUrlFor(String animeId) => _absoluteUrl('/cover2/$animeId.jpg');

  String? _absoluteUrl(String? raw) {
    final value = _clean(raw);
    if (value.isEmpty) return null;
    return _resolveUri(value).toString();
  }

  Uri _resolveUri(String pathOrUrl) {
    final value = pathOrUrl.trim();
    final base = Uri.parse(_normalizedBase);
    if (value.isEmpty || value == '/') return base;
    return base.resolve(value.replaceAll(r'\/', '/'));
  }

  String get _normalizedBase => baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  String? _normalizeAnimeId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    if (RegExp(r'^\d+$').hasMatch(normalized)) return normalized;
    final path = _resolveUri(normalized).path;
    final match = RegExp(r'/vod/(\d+)\.html').firstMatch(path);
    return match?.group(1) ?? _normalizeEpisodeId(normalized)?.animeId;
  }

  _EpisodeRef? _normalizeEpisodeId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    final compactMatch = RegExp(r'^(\d+)/([^/.]+)$').firstMatch(normalized);
    if (compactMatch != null) {
      return _EpisodeRef(
        animeId: compactMatch.group(1)!,
        episodeKey: compactMatch.group(2)!,
      );
    }

    final path = _resolveUri(normalized).path;
    final pathMatch = RegExp(
      r'/vod-play/(\d+)/([^/.]+)\.html',
    ).firstMatch(path);
    if (pathMatch != null) {
      return _EpisodeRef(
        animeId: pathMatch.group(1)!,
        episodeKey: pathMatch.group(2)!,
      );
    }
    return null;
  }

  String _unescapeUrl(String value) {
    final clean = _clean(value).replaceAll(r'\/', '/');
    if (!clean.contains(r'\u')) return clean;
    try {
      return jsonDecode('"${clean.replaceAll('"', r'\"')}"').toString();
    } on Object {
      return clean;
    }
  }

  String _stripEpisodeSuffix(String value) {
    return _clean(value)
        .replaceFirst(RegExp(r'\s*第\d+集.*$'), '')
        .replaceFirst(RegExp(r'\s*正片.*$'), '')
        .trim();
  }

  String _extractEpisodeTitle(String rowText) {
    return RegExp(r'(第\d+集(?:完结)?|第\d+话|正片|HD中字|TC)')
            .firstMatch(rowText)
            ?.group(1) ??
        '';
  }

  String _extractRegion(String rowText) {
    return RegExp(r'(日本|中国|美国|大陆|欧美|韩国)').firstMatch(rowText)?.group(1) ?? '';
  }

  String _clean(String? value) {
    return value?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  }

  AppException _networkFailure(
    String operation,
    String message, {
    required String code,
    String? url,
    int? statusCode,
    Object? exception,
  }) {
    _record(
      SourceDiagnosticLevel.error,
      operation,
      message,
      url: url,
      statusCode: statusCode,
      exceptionType: exception?.runtimeType.toString(),
    );
    return AppException(message, code: code, cause: exception);
  }

  AppException _parserFailure(
    String operation,
    String message, {
    required String code,
    String? url,
  }) {
    _record(
      SourceDiagnosticLevel.error,
      operation,
      message,
      url: url,
      exceptionType: 'ParserError',
    );
    return AppException(message, code: code);
  }

  void _record(
    SourceDiagnosticLevel level,
    String operation,
    String message, {
    String? url,
    int? statusCode,
    String? exceptionType,
  }) {
    _diagnostics.record(
      SourceDiagnostic(
        sourceId: id,
        operation: operation,
        level: level,
        message: message,
        url: url,
        statusCode: statusCode,
        exceptionType: exceptionType,
      ),
    );
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

  String operator |(String fallback) => isEmpty ? fallback : this;
}
