import 'dart:async';
import 'dart:typed_data';

import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/source/data/adapters/sakura_anime_source_adapter.dart';
import 'package:ani_destiny/features/source/data/services/in_memory_source_diagnostic_recorder.dart';
import 'package:ani_destiny/features/source/domain/entities/source_diagnostic.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InMemorySourceDiagnosticRecorder records, filters, and clears entries',
      () {
    final recorder = InMemorySourceDiagnosticRecorder(capacity: 2);

    recorder.record(
      const SourceDiagnostic(
        sourceId: 'mock',
        operation: 'home',
        level: SourceDiagnosticLevel.info,
        message: 'ok',
      ),
    );
    recorder.record(
      const SourceDiagnostic(
        sourceId: 'sakura',
        operation: 'detail',
        level: SourceDiagnosticLevel.error,
        message: 'detail failed',
      ),
    );
    recorder.record(
      const SourceDiagnostic(
        sourceId: 'sakura',
        operation: 'play',
        level: SourceDiagnosticLevel.warning,
        message: 'fallback',
      ),
    );

    expect(recorder.latest(), hasLength(2));
    expect(recorder.latest().first.operation, 'play');
    expect(recorder.latest(sourceId: 'sakura'), hasLength(2));

    recorder.clear(sourceId: 'sakura');
    expect(recorder.latest(), isEmpty);
  });

  test('Sakura adapter records parser errors without storing raw HTML',
      () async {
    final recorder = InMemorySourceDiagnosticRecorder();
    final adapter = SakuraAnimeSourceAdapter(
      dio: Dio()
        ..httpClientAdapter = const _FakeHttpClientAdapter(
          html: '<html><body><h1 class="names">Broken</h1></body></html>',
        ),
      diagnosticRecorder: recorder,
      baseUrl: 'https://example.test',
    );

    await expectLater(
      adapter.getAnimeDetail('2026406456'),
      throwsA(isA<AppException>()),
    );

    final diagnostics = recorder.latest(sourceId: 'sakura');
    expect(diagnostics, isNotEmpty);
    expect(diagnostics.first.level, SourceDiagnosticLevel.error);
    expect(diagnostics.first.operation, 'detail');
    expect(diagnostics.first.message, contains('cannot parse episode list'));
    expect(diagnostics.first.message, isNot(contains('<html>')));
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  const _FakeHttpClientAdapter({required this.html});

  final String html;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      html,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }
}
