import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/anime/domain/entities/anime_detail.dart';
import 'package:ani_destiny/features/anime/domain/entities/play_source.dart';
import 'package:ani_destiny/features/anime/domain/entities/schedule_item.dart';
import 'package:ani_destiny/features/anime/domain/entities/search_result.dart';
import 'package:ani_destiny/features/source/data/registry/source_registry.dart';
import 'package:ani_destiny/features/source/data/services/persistent_source_health_service.dart';
import 'package:ani_destiny/features/source/data/services/source_fallback_service_impl.dart';
import 'package:ani_destiny/features/source/domain/adapters/anime_source_adapter.dart';
import 'package:ani_destiny/features/source/domain/entities/anime_source.dart';
import 'package:ani_destiny/features/source/domain/entities/source_diagnostic.dart';
import 'package:ani_destiny/features/source/domain/entities/source_fallback_event.dart';
import 'package:ani_destiny/features/source/domain/repositories/source_repository.dart';
import 'package:ani_destiny/features/source/domain/services/source_diagnostic_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fallback uses selected source first', () async {
    final harness = await _Harness.create(selectedSourceId: 'sakura');

    final result = await harness.service.run<List<String>>(
      operation: 'home',
      action: (adapter) async {
        harness.calls.add(adapter.id);
        return [adapter.id];
      },
    );

    expect(result.sourceId, 'sakura');
    expect(result.usedFallback, isFalse);
    expect(harness.calls, ['sakura']);
  });

  test('fallback tries Sakura before Mock when selected source is unavailable',
      () async {
    final harness = await _Harness.create(selectedSourceId: 'remote-proxy');

    final result = await harness.service.run<List<String>>(
      operation: 'home',
      action: (adapter) async {
        harness.calls.add(adapter.id);
        if (adapter.id == 'remote-proxy') {
          throw Exception('selected unavailable');
        }
        return [adapter.id];
      },
    );

    expect(result.sourceId, 'sakura');
    expect(result.usedFallback, isTrue);
    expect(harness.calls, ['remote-proxy', 'sakura']);
    expect(
      result.message,
      'Selected source is temporarily unavailable. AniDestiny is showing another source instead.',
    );
  });

  test('fallback returns mock only when real source fails', () async {
    final harness = await _Harness.create(selectedSourceId: 'sakura');

    final result = await harness.service.run<List<String>>(
      operation: 'home',
      action: (adapter) async {
        harness.calls.add(adapter.id);
        if (adapter.id == 'sakura') throw Exception('real source failed');
        return [adapter.id];
      },
    );

    expect(result.sourceId, 'mock');
    expect(result.usedFallback, isTrue);
    expect(result.fromSourceId, 'sakura');
    expect(harness.calls, ['sakura', 'mock']);
    expect(harness.events.single.toSourceId, 'mock');
    expect(
      result.message,
      'Selected source is temporarily unavailable. AniDestiny is showing another source instead.',
    );
  });

  test('fallback events and diagnostics store sanitized failure reasons',
      () async {
    final recorder = _FakeDiagnosticRecorder();
    final harness = await _Harness.create(
      selectedSourceId: 'sakura',
      diagnosticRecorder: recorder,
    );

    final result = await harness.service.run<List<String>>(
      operation: 'home',
      action: (adapter) async {
        harness.calls.add(adapter.id);
        if (adapter.id == 'sakura') {
          throw Exception(
            'Failed https://example.test/watch?id=1&token=secret '
            '/Users/ark/Downloads/AniDestiny/debug.log',
          );
        }
        return [adapter.id];
      },
    );

    expect(result.sourceId, 'mock');
    expect(harness.events.single.reason, contains('https://example.test'));
    expect(harness.events.single.reason, isNot(contains('token=secret')));
    expect(harness.events.single.reason, contains('/Users/<user>/'));
    expect(harness.events.single.reason, isNot(contains('/Users/ark/')));
    expect(recorder.items.first.reason, isNot(contains('token=secret')));
    expect(recorder.items.last.reason, isNot(contains('token=secret')));
  });

  test('all sources failed throws AppException', () async {
    final harness = await _Harness.create(selectedSourceId: 'sakura');

    await expectLater(
      harness.service.run<List<String>>(
        operation: 'home',
        action: (adapter) async {
          throw Exception('${adapter.id} failed');
        },
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('search empty result is not treated as failure', () async {
    final harness = await _Harness.create(selectedSourceId: 'sakura');

    final result = await harness.service.run<List<SearchResult>>(
      operation: 'search',
      action: (adapter) async => const [],
    );

    expect(result.sourceId, 'sakura');
    expect(result.value, isEmpty);
    expect(result.usedFallback, isFalse);
  });

  test('play sources empty is treated as failure when policy asks for it',
      () async {
    final harness = await _Harness.create(selectedSourceId: 'sakura');

    final result = await harness.service.run<List<PlaySource>>(
      operation: 'play_sources',
      action: (adapter) async {
        harness.calls.add(adapter.id);
        if (adapter.id == 'mock') {
          return const [
            PlaySource(
              id: 'mock-line',
              episodeId: 'episode-1',
              title: 'Mock',
              url: 'https://example.test/video.mp4',
            ),
          ];
        }
        return const [];
      },
      isFailureValue: (items) => items.isEmpty,
    );

    expect(result.sourceId, 'mock');
    expect(result.usedFallback, isTrue);
    expect(harness.calls, ['sakura', 'mock']);
  });
}

class _Harness {
  _Harness({
    required this.service,
    required this.calls,
    required this.events,
  });

  final SourceFallbackServiceImpl service;
  final List<String> calls;
  final List<SourceFallbackEvent> events;

  static Future<_Harness> create({
    required String selectedSourceId,
    SourceDiagnosticRecorder? diagnosticRecorder,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final registry = SourceRegistry(
      adapters: const [
        _FakeAdapter(id: 'remote-proxy'),
        _FakeAdapter(id: 'sakura'),
        _FakeAdapter(id: 'mock'),
      ],
    );
    final calls = <String>[];
    final events = <SourceFallbackEvent>[];
    final service = SourceFallbackServiceImpl(
      sourceRepository: _FakeSourceRepository(
        registry: registry,
        selectedSourceId: selectedSourceId,
      ),
      registry: registry,
      healthService: PersistentSourceHealthService(
        preferences: await SharedPreferences.getInstance(),
        sourceIds: registry.adapters.map((adapter) => adapter.id),
      ),
      diagnosticRecorder: diagnosticRecorder ?? _FakeDiagnosticRecorder(),
      onFallbackEvent: events.add,
    );
    return _Harness(service: service, calls: calls, events: events);
  }
}

class _FakeSourceRepository implements SourceRepository {
  const _FakeSourceRepository({
    required this.registry,
    required this.selectedSourceId,
  });

  final SourceRegistry registry;
  final String selectedSourceId;

  @override
  Future<AnimeSourceAdapter> getCurrentAdapter() async {
    return registry.getById(selectedSourceId) ?? registry.defaultAdapter;
  }

  @override
  Future<String> getCurrentSourceId() async => selectedSourceId;

  @override
  List<AnimeSource> getSources() => const [];

  @override
  Future<void> setCurrentSourceId(String sourceId) async {}
}

class _FakeDiagnosticRecorder implements SourceDiagnosticRecorder {
  final items = <SourceDiagnostic>[];

  @override
  void clear({String? sourceId}) {}

  @override
  List<SourceDiagnostic> latest({String? sourceId}) {
    final values = sourceId == null
        ? items
        : items.where((item) => item.sourceId == sourceId);
    return values.toList(growable: false);
  }

  @override
  void record(SourceDiagnostic diagnostic) {
    items.add(diagnostic);
  }
}

class _FakeAdapter implements AnimeSourceAdapter {
  const _FakeAdapter({required this.id});

  @override
  final String id;

  @override
  String? get description => id;

  @override
  String get name => id;

  @override
  Future<AnimeDetail> getAnimeDetail(String animeId) async =>
      throw UnimplementedError();

  @override
  Future<List<Anime>> getHomeRecommendations() async => const [];

  @override
  Future<List<PlaySource>> getPlaySources(String episodeId) async => const [];

  @override
  Future<List<ScheduleItem>> getSchedule() async => const [];

  @override
  Future<List<SearchResult>> search(String keyword, {int page = 1}) async =>
      const [];
}
