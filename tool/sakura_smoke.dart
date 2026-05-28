import 'dart:io';

import 'package:ani_destiny/core/utils/url_sanitizer.dart';
import 'package:ani_destiny/features/source/data/adapters/sakura_anime_source_adapter.dart';
import 'package:ani_destiny/features/source/data/services/in_memory_source_diagnostic_recorder.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  final diagnostics = InMemorySourceDiagnosticRecorder();
  final adapter = SakuraAnimeSourceAdapter(
    dio: Dio(),
    diagnosticRecorder: diagnostics,
  );

  stdout.writeln('Sakura Smoke Test');
  try {
    final home = await adapter.getHomeRecommendations();
    stdout.writeln('[home]');
    stdout.writeln('count: ${home.length}');
    if (home.isNotEmpty) {
      stdout.writeln('first: ${home.first.title} / ${home.first.id}');
    }

    const keyword = '火影';
    final search = await adapter.search(keyword);
    stdout.writeln('[search]');
    stdout.writeln('keyword: $keyword');
    stdout.writeln('count: ${search.length}');
    if (search.isEmpty) {
      throw StateError('Sakura search returned no result for $keyword.');
    }
    stdout.writeln('first: ${search.first.title} / ${search.first.animeId}');

    final detail = await adapter.getAnimeDetail(search.first.animeId);
    stdout.writeln('[detail]');
    stdout.writeln('title: ${detail.title}');
    stdout.writeln('episodes: ${detail.episodes.length}');
    if (detail.episodes.isEmpty) {
      throw StateError('Sakura detail returned no episodes.');
    }

    final playSources = await adapter.getPlaySources(detail.episodes.first.id);
    stdout.writeln('[play]');
    stdout.writeln('sources: ${playSources.length}');
    if (playSources.isEmpty) {
      throw StateError('Sakura play returned no sources.');
    }
    stdout.writeln(
      'first url: ${sanitizeUrlForDiagnostics(playSources.first.url)}',
    );
    stdout
        .writeln('headers keys: ${playSources.first.headers.keys.join(', ')}');

    _printDiagnostics(diagnostics);
    exitCode = 0;
  } on Object catch (error, stackTrace) {
    stderr.writeln('Smoke failed: $error');
    stderr.writeln(stackTrace);
    _printDiagnostics(diagnostics);
    exitCode = 1;
  }
}

void _printDiagnostics(InMemorySourceDiagnosticRecorder diagnostics) {
  stdout.writeln('[diagnostics]');
  final items = diagnostics.latest(sourceId: 'sakura');
  if (items.isEmpty) {
    stdout.writeln('none');
    return;
  }
  for (final item in items) {
    stdout.writeln(
      '${item.level.name} ${item.operation}: ${item.message}'
      '${item.url == null ? '' : ' url=${sanitizeUrlForDiagnostics(item.url!)}'}'
      '${item.statusCode == null ? '' : ' status=${item.statusCode}'}'
      '${item.exceptionType == null ? '' : ' exception=${item.exceptionType}'}',
    );
  }
}
