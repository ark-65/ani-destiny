import 'dart:async';
import 'dart:typed_data';

import 'package:ani_destiny/features/source/data/adapters/sakura_anime_source_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'SakuraAnimeSourceAdapter parses search, detail, schedule, and play data',
      () async {
    final dio = Dio()
      ..httpClientAdapter = const _FakeHttpClientAdapter(
        responses: {
          '/': _homeHtml,
          '/latest/': _latestHtml,
          '/search': _searchHtml,
          '/vod/2026406456.html': _detailHtml,
          '/_get_plays/2026406456/ep1': _playJson,
        },
      );
    final adapter = SakuraAnimeSourceAdapter(
      dio: dio,
      baseUrl: 'https://example.test',
    );

    final home = await adapter.getHomeRecommendations();
    expect(home.single.title, '最强王者的第二人生 第二季');
    expect(home.single.coverUrl, 'https://example.test/cover2/2026406456.jpg');

    final search = await adapter.search('王者');
    expect(search.single.animeId, '2026406456');
    expect(search.single.description, contains('拥有独树一帜力量'));

    final detail = await adapter.getAnimeDetail(search.single.animeId);
    expect(detail.title, '最强王者的第二人生 第二季');
    expect(detail.aliases, contains('三岁开始做王者 第二季'));
    expect(detail.tags, contains('奇幻'));
    expect(detail.description, contains('动漫介绍正文'));
    expect(detail.episodes.first.id, '2026406456/ep1');

    final playSources = await adapter.getPlaySources(detail.episodes.first.id);
    expect(playSources.single.title, 'jyzy');
    expect(
      playSources.single.url,
      'https://cdn.example.test/video/index.m3u8',
    );
    expect(
      playSources.single.headers['referer'],
      'https://example.test/vod-play/2026406456/ep1.html',
    );

    final schedule = await adapter.getSchedule();
    expect(schedule.single.animeId, '2026406456');
    expect(schedule.single.weekday, DateTime(2026, 5, 28).weekday);
    expect(schedule.single.updateTime, '2026-05-28 第01集');
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  const _FakeHttpClientAdapter({
    required this.responses,
  });

  final Map<String, String> responses;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
    }
  ]
}
''';
