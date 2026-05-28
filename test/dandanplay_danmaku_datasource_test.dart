import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ani_destiny/features/danmaku/data/datasources/dandanplay_danmaku_datasource.dart';
import 'package:ani_destiny/features/danmaku/domain/entities/danmaku_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dandanplay data source parses match JSON and sends auth headers',
      () async {
    final fake = _FakeHttpClientAdapter(
      responses: {
        '/api/v2/search/episodes': _matchJson,
      },
    );
    final dataSource = DioDandanplayDanmakuDataSource(
      dio: Dio()..httpClientAdapter = fake,
      credentials: const DandanplayCredentials(
        appId: 'app-id',
        appSecret: 'secret',
      ),
    );

    final matches = await dataSource.match(
      animeTitle: '火影忍者',
      episodeTitle: '第01集',
      episodeIndex: 1,
    );

    expect(matches, hasLength(2));
    expect(matches.first.id, '2002431814001');
    expect(matches.first.animeTitle, '火影忍者');
    expect(matches.first.episodeTitle, '第1话 旋涡鸣人登场');
    expect(matches.first.source, 'dandanplay');
    expect(matches.first.score, greaterThan(matches.last.score!));
    expect(fake.requests.single.uri.queryParameters['anime'], '火影忍者');
    expect(fake.requests.single.uri.queryParameters['episode'], '1');
    expect(fake.requests.single.headers['X-AppId'], 'app-id');
    expect(fake.requests.single.headers, contains('X-Signature'));
    expect(fake.requests.single.headers, contains('X-Timestamp'));
  });

  test('Dandanplay data source parses comment JSON', () async {
    final dataSource = DioDandanplayDanmakuDataSource(
      dio: Dio()
        ..httpClientAdapter = _FakeHttpClientAdapter(
          responses: {
            '/api/v2/comment/2002431814001': _commentJson,
          },
        ),
      credentials: const DandanplayCredentials(
        appId: 'app-id',
        appSecret: 'secret',
      ),
    );

    final comments = await dataSource.getComments(matchId: '2002431814001');

    expect(comments, hasLength(3));
    expect(comments[0].id, '12345');
    expect(comments[0].time, const Duration(milliseconds: 12340));
    expect(comments[0].type, DanmakuType.scroll);
    expect(comments[0].color, 0xFFFFFFFF);
    expect(comments[0].source, 'dandanplay');
    expect(comments[1].type, DanmakuType.bottom);
    expect(comments[1].color, 0xFFFF0000);
    expect(comments[2].type, DanmakuType.top);
  });

  test('Dandanplay data source skips network when credentials are missing',
      () async {
    final fake = _FakeHttpClientAdapter(responses: const {});
    final dataSource = DioDandanplayDanmakuDataSource(
      dio: Dio()..httpClientAdapter = fake,
    );

    final matches = await dataSource.match(
      animeTitle: '火影忍者',
      episodeTitle: '第01集',
    );
    final comments = await dataSource.getComments(matchId: '1');

    expect(matches, isEmpty);
    expect(comments, isEmpty);
    expect(fake.requests, isEmpty);
  });
}

class _RequestCapture {
  const _RequestCapture({required this.uri, required this.headers});

  final Uri uri;
  final Map<String, dynamic> headers;
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.responses});

  final Map<String, String> responses;
  final List<_RequestCapture> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _RequestCapture(
        uri: options.uri,
        headers: Map<String, dynamic>.from(options.headers),
      ),
    );
    final body = responses[options.uri.path];
    if (body == null) {
      return ResponseBody.fromString(
        jsonEncode({'success': false, 'errorMessage': 'not found'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

const _matchJson = '''
{
  "success": true,
  "hasMore": false,
  "animes": [
    {
      "animeId": 2002431814,
      "animeTitle": "火影忍者",
      "type": "TV",
      "typeDescription": "TV",
      "episodes": [
        {
          "episodeId": 2002431814001,
          "episodeTitle": "第1话 旋涡鸣人登场"
        },
        {
          "episodeId": 2002431814002,
          "episodeTitle": "第2话 我是木叶丸"
        }
      ]
    }
  ]
}
''';

const _commentJson = '''
{
  "count": 3,
  "comments": [
    {"cid": 12345, "p": "12.34,1,16777215,98765", "m": "测试弹幕1"},
    {"cid": 67890, "p": "45.67,4,16711680,54321", "m": "底部弹幕"},
    {"cid": 33333, "p": "48.00,5,65280,777", "m": "顶部弹幕"}
  ]
}
''';
