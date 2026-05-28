import 'dart:async';
import 'dart:typed_data';

import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/source/data/adapters/sakura_anime_source_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Sakura adapter parses fake home, search, detail, schedule, and play data',
      () async {
    final fake = _FakeHttpClientAdapter(
      responses: {
        '/': _homeHtml,
        '/latest/': _latestHtml,
        '/search': _searchHtml,
        '/vod/2026406456.html': _detailHtml,
        '/_get_plays/2026406456/ep1': _playJson,
      },
    );
    final adapter = SakuraAnimeSourceAdapter(
      dio: Dio()..httpClientAdapter = fake,
      baseUrl: 'https://example.test',
    );

    final home = await adapter.getHomeRecommendations();
    expect(home.single.title, '最强王者的第二人生 第二季');
    expect(home.single.coverUrl, 'https://example.test/cover2/2026406456.jpg');

    final search = await adapter.search('王者');
    expect(search.single.animeId, '2026406456');
    expect(search.single.description, contains('拥有独树一帜力量'));
    expect(fake.requests.any((uri) => uri.path == '/search'), isTrue);

    final detail = await adapter.getAnimeDetail(search.single.animeId);
    expect(detail.title, '最强王者的第二人生 第二季');
    expect(detail.aliases, contains('三岁开始做王者 第二季'));
    expect(detail.tags, contains('奇幻'));
    expect(detail.description, contains('动漫介绍正文'));
    expect(detail.episodes.first.id, '2026406456/ep1');

    final playSources = await adapter.getPlaySources(detail.episodes.first.id);
    expect(playSources, hasLength(2));
    expect(playSources.first.title, 'jyzy');
    expect(
      playSources.first.url,
      'https://cdn.example.test/video/index.m3u8',
    );
    expect(
      playSources.first.headers['Referer'],
      'https://example.test/vod-play/2026406456/ep1.html',
    );
    expect(playSources.first.headers, contains('User-Agent'));
    expect(playSources.last.title, '备用线路');
    expect(playSources.last.quality, 'HLS');

    final schedule = await adapter.getSchedule();
    expect(schedule.single.animeId, '2026406456');
    expect(schedule.single.weekday, DateTime(2026, 5, 28).weekday);
    expect(schedule.single.updateTime, '2026-05-28 第01集');
  });

  test('Sakura adapter falls back to latest when home cards are missing',
      () async {
    final adapter = SakuraAnimeSourceAdapter(
      dio: Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          responses: {
            '/': '<html><body></body></html>',
            '/latest/': _latestHtml,
          },
        ),
      baseUrl: 'https://example.test',
    );

    final home = await adapter.getHomeRecommendations();
    expect(home.single.id, '2026406456');
    expect(home.single.status, '第01集');
  });

  test('Sakura adapter normalizes absolute and relative URLs', () async {
    final adapter = SakuraAnimeSourceAdapter(
      dio: Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          responses: {
            '/vod/2026406456.html': _detailHtml,
            '/_get_plays/2026406456/ep1': _playJson,
          },
        ),
      baseUrl: 'https://example.test/root/',
    );

    final detail = await adapter.getAnimeDetail(
      'https://example.test/vod/2026406456.html?from=search',
    );
    expect(detail.id, '2026406456');

    final playSources = await adapter.getPlaySources(
      'https://example.test/vod-play/2026406456/ep1.html?line=1',
    );
    expect(playSources.last.url, 'https://example.test/media/backup.m3u8');
  });

  test('Sakura adapter parses play source script fallback', () async {
    final adapter = SakuraAnimeSourceAdapter(
      dio: Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          responses: {
            '/_get_plays/2026406456/ep1': _playScriptHtml,
          },
        ),
      baseUrl: 'https://example.test',
    );

    final sources = await adapter.getPlaySources('2026406456/ep1');
    expect(sources, hasLength(1));
    expect(sources.single.title, 'script-line');
    expect(sources.single.url, 'https://example.test/video/script.m3u8');
  });

  test('Sakura adapter throws AppException for empty detail episodes',
      () async {
    final adapter = SakuraAnimeSourceAdapter(
      dio: Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          responses: {
            '/vod/2026406456.html': _detailWithoutEpisodesHtml,
          },
        ),
      baseUrl: 'https://example.test',
    );

    await expectLater(
      adapter.getAnimeDetail('2026406456'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'sakura_parse_detail_episodes_failed',
        ),
      ),
    );
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.responses});

  final Map<String, String> responses;
  final List<Uri> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    final body = responses[options.uri.path];
    if (body == null) {
      return ResponseBody.fromString(
        'Not found',
        404,
        headers: {
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
    }

    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }
}

const _homeHtml = '''
<html>
  <body>
    <ul>
      <li class="col-3 mb-3">
        <a href="/vod-play/2026406456/ep1.html">
          <img src="/cover2/2026406456.jpg" alt="最强王者的第二人生 第二季">
        </a>
        <a href="/vod/2026406456.html" title="最强王者的第二人生 第二季">
          <div>最强王者的第二人生 第二季</div>
        </a>
        <div><span>更至第01集</span></div>
      </li>
    </ul>
  </body>
</html>
''';

const _searchHtml = '''
<html>
  <body>
    <ul id="search_list">
      <li class="clearfix">
        <a href="/vod/2026406456.html">
          <img data-original="/cover2/2026406456.jpg" alt="最强王者的第二人生 第二季">
        </a>
        <h6><a href="/vod/2026406456.html" title="最强王者的第二人生 第二季">最强王者的第二人生 第二季</a></h6>
        <p class="small">简介：拥有独树一帜力量的少年继续前进。</p>
      </li>
    </ul>
  </body>
</html>
''';

const _detailHtml = '''
<html>
  <body>
    <h1 class="names">最强王者的第二人生 第二季</h1>
    <div class="detail-poster"><img src="/cover/2026406456.jpg"></div>
    <div class="mb-1">别名： 三岁开始做王者 第二季 / 最強王者</div>
    <div class="mb-1">类型： <span>动画</span> <a>奇幻</a> <a>冒险</a></div>
    <div class="ep-panel">
      <a href="/vod-play/2026406456/ep2.html">第02集</a>
      <a href="/vod-play/2026406456/ep1.html">第01集</a>
    </div>
    <h5>动漫介绍</h5>
    <div>动漫介绍正文。</div>
  </body>
</html>
''';

const _detailWithoutEpisodesHtml = '''
<html>
  <body>
    <h1 class="names">最强王者的第二人生 第二季</h1>
    <h5>动漫介绍</h5>
    <div>动漫介绍正文。</div>
  </body>
</html>
''';

const _latestHtml = '''
<html>
  <body>
    <ul class="latest-ul">
      <li>
        <span class="region">日本</span>
        <a class="names" href="/vod-play/2026406456/ep1.html">
          <span class="name">最强王者的第二人生 第二季</span>
          <span class="ep_name">第01集</span>
        </a>
        <em>2026-05-28</em>
      </li>
    </ul>
  </body>
</html>
''';

const _playJson = '''
{
  "video_plays": [
    {
      "play_data": "https://cdn.example.test/video/index.m3u8",
      "src_site": "jyzy"
    },
    {
      "play_data": "/media/backup.m3u8",
      "src_site": "备用线路"
    }
  ]
}
''';

const _playScriptHtml = '''
<html>
  <body>
    <script>
      window.playerData = {
        "video_plays": [
          {"play_data": "/video/script.m3u8", "src_site": "script-line"}
        ]
      };
    </script>
  </body>
</html>
''';
