import 'dart:io';

import 'package:ani_destiny/features/danmaku/data/datasources/dandanplay_danmaku_datasource.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  final appId = Platform.environment['DANDANPLAY_APP_ID'] ?? '';
  final appSecret = Platform.environment['DANDANPLAY_APP_SECRET'] ?? '';
  stdout.writeln('Dandanplay Danmaku Smoke Test');
  if (appId.isEmpty || appSecret.isEmpty) {
    stdout.writeln(
      'Skipped: set DANDANPLAY_APP_ID and DANDANPLAY_APP_SECRET to run live requests.',
    );
    exitCode = 0;
    return;
  }

  final dataSource = DioDandanplayDanmakuDataSource(
    dio: Dio(),
    credentials: DandanplayCredentials(appId: appId, appSecret: appSecret),
  );

  try {
    final matches = await dataSource.match(
      animeTitle: '火影忍者',
      episodeTitle: '第01集',
      episodeIndex: 1,
    );
    stdout.writeln('[match]');
    stdout.writeln('count: ${matches.length}');
    if (matches.isEmpty) {
      stdout.writeln('No match found.');
      exitCode = 1;
      return;
    }

    final best = matches.first;
    stdout.writeln(
      'first: ${best.animeTitle} / ${best.episodeTitle} / ${best.id}',
    );

    final comments = await dataSource.getComments(matchId: best.id);
    stdout.writeln('[comments]');
    stdout.writeln('count: ${comments.length}');
    if (comments.isNotEmpty) {
      stdout.writeln(
        'first: ${comments.first.time.inMilliseconds}ms / ${comments.first.text}',
      );
    }
    exitCode = comments.isEmpty ? 1 : 0;
  } on Object catch (error, stackTrace) {
    stderr.writeln('Smoke failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
