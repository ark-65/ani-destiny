import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/preferences_provider.dart';
import '../../data/adapters/mock_anime_source_adapter.dart';
import '../../data/adapters/remote_source_proxy_adapter.dart';
import '../../data/adapters/sakura_anime_source_adapter.dart';
import '../../data/registry/source_registry.dart';
import '../../data/repositories/source_repository_impl.dart';
import '../../data/services/persistent_source_health_service.dart';
import '../../data/services/source_fallback_service_impl.dart';
import '../../domain/adapters/anime_source_adapter.dart';
import '../../domain/entities/anime_source.dart';
import '../../domain/entities/source_diagnostic.dart';
import '../../domain/entities/source_fallback_event.dart';
import '../../domain/entities/source_health.dart';
import '../../domain/repositories/source_repository.dart';
import '../../domain/services/source_diagnostic_recorder.dart';
import '../../domain/services/source_fallback_service.dart';
import '../../domain/services/source_health_service.dart';

final sourceDiagnosticsControllerProvider =
    NotifierProvider<SourceDiagnosticsController, List<SourceDiagnostic>>(
  SourceDiagnosticsController.new,
);

class SourceDiagnosticsController extends Notifier<List<SourceDiagnostic>>
    implements SourceDiagnosticRecorder {
  static const _capacity = 80;

  @override
  List<SourceDiagnostic> build() => const [];

  @override
  void record(SourceDiagnostic diagnostic) {
    final item = SourceDiagnostic(
      sourceId: diagnostic.sourceId,
      operation: diagnostic.operation,
      level: diagnostic.level,
      message: diagnostic.message,
      url: diagnostic.url,
      statusCode: diagnostic.statusCode,
      exceptionType: diagnostic.exceptionType,
      timestamp: diagnostic.timestamp ?? DateTime.now(),
      fromSourceId: diagnostic.fromSourceId,
      toSourceId: diagnostic.toSourceId,
      usedFallback: diagnostic.usedFallback,
      reason: diagnostic.reason,
    );
    final next = [...state, item];
    state = next.length > _capacity
        ? next.sublist(next.length - _capacity)
        : List.unmodifiable(next);
  }

  @override
  List<SourceDiagnostic> latest({String? sourceId}) {
    final values = sourceId == null
        ? state
        : state.where((item) => item.sourceId == sourceId);
    return List.unmodifiable(values.toList().reversed);
  }

  @override
  void clear({String? sourceId}) {
    if (sourceId == null) {
      state = const [];
      return;
    }
    state = state.where((item) => item.sourceId != sourceId).toList();
  }
}

final sourceRegistryProvider = Provider<SourceRegistry>((ref) {
  final dio = ref.watch(dioProvider);
  final diagnostics = ref.watch(sourceDiagnosticsControllerProvider.notifier);
  return SourceRegistry(
    adapters: [
      MockAnimeSourceAdapter(),
      SakuraAnimeSourceAdapter(dio: dio, diagnosticRecorder: diagnostics),
      RemoteSourceProxyAdapter(dio: dio, baseUrl: ''),
    ],
  );
});

final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepositoryImpl(
    registry: ref.watch(sourceRegistryProvider),
    preferences: () => ref.read(sharedPreferencesProvider.future),
  );
});

final sourceHealthControllerProvider =
    NotifierProvider<SourceHealthController, List<SourceHealth>>(
  SourceHealthController.new,
);

class SourceHealthController extends Notifier<List<SourceHealth>>
    implements SourceHealthService {
  @override
  List<SourceHealth> build() {
    final sourceIds = ref
        .watch(sourceRegistryProvider)
        .adapters
        .map((adapter) => adapter.id)
        .toList(growable: false);
    unawaited(_loadPersistedHealth(sourceIds));
    return sourceIds.map(SourceHealth.initial).toList(growable: false);
  }

  @override
  SourceHealth getHealth(String sourceId) {
    return state.firstWhere(
      (health) => health.sourceId == sourceId,
      orElse: () => SourceHealth.initial(sourceId),
    );
  }

  @override
  List<SourceHealth> getAllHealth() => List.unmodifiable(state);

  @override
  void recordSuccess({
    required String sourceId,
    required String operation,
  }) {
    final next = getHealth(sourceId).copyWith(
      status: SourceHealthStatus.healthy,
      failureCount: 0,
      lastSuccessAt: DateTime.now(),
      clearLastErrorMessage: true,
    );
    _setHealth(next);
  }

  @override
  void recordFailure({
    required String sourceId,
    required String operation,
    required Object error,
  }) {
    final current = getHealth(sourceId);
    final failureCount = current.failureCount + 1;
    final next = current.copyWith(
      status: sourceHealthStatusForFailureCount(failureCount),
      failureCount: failureCount,
      lastFailureAt: DateTime.now(),
      lastErrorMessage: _summarize(error),
    );
    _setHealth(next);
  }

  @override
  bool shouldFallback(String sourceId) {
    return getHealth(sourceId).status == SourceHealthStatus.unavailable;
  }

  @override
  void reset(String sourceId) {
    _setHealth(SourceHealth.initial(sourceId));
  }

  Future<void> _loadPersistedHealth(List<String> sourceIds) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    final service = PersistentSourceHealthService(
      preferences: preferences,
      sourceIds: sourceIds,
    );
    state = service.getAllHealth();
  }

  void _setHealth(SourceHealth health) {
    final values = [
      for (final item in state)
        if (item.sourceId == health.sourceId) health else item,
      if (!state.any((item) => item.sourceId == health.sourceId)) health,
    ];
    state = List.unmodifiable(values);
    unawaited(_persist(health));
  }

  Future<void> _persist(SourceHealth health) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    final sourceIds = state.map((item) => item.sourceId);
    final service = PersistentSourceHealthService(
      preferences: preferences,
      sourceIds: sourceIds,
    );
    service.save(health);
  }

  String _summarize(Object error) {
    final text = error
        .toString()
        .replaceAll(RegExp(r'(https?://[^\s?]+)\?[^\s]+'), r'$1?[hidden]')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= 140) return text;
    return '${text.substring(0, 137)}...';
  }
}

final sourceFallbackEventsProvider =
    NotifierProvider<SourceFallbackEventsController, List<SourceFallbackEvent>>(
  SourceFallbackEventsController.new,
);

class SourceFallbackEventsController
    extends Notifier<List<SourceFallbackEvent>> {
  static const _capacity = 40;

  @override
  List<SourceFallbackEvent> build() => const [];

  void record(SourceFallbackEvent event) {
    final next = [...state, event];
    state = next.length > _capacity
        ? next.sublist(next.length - _capacity)
        : List.unmodifiable(next);
  }
}

final sourceFallbackServiceProvider = Provider<SourceFallbackService>((ref) {
  return SourceFallbackServiceImpl(
    sourceRepository: ref.watch(sourceRepositoryProvider),
    registry: ref.watch(sourceRegistryProvider),
    healthService: ref.watch(sourceHealthControllerProvider.notifier),
    diagnosticRecorder: ref.watch(sourceDiagnosticsControllerProvider.notifier),
    onFallbackEvent: ref.watch(sourceFallbackEventsProvider.notifier).record,
  );
});

final sourceListProvider = Provider<List<AnimeSource>>((ref) {
  return ref.watch(sourceRepositoryProvider).getSources();
});

final currentSourceIdProvider =
    AsyncNotifierProvider<CurrentSourceIdController, String>(
  CurrentSourceIdController.new,
);

class CurrentSourceIdController extends AsyncNotifier<String> {
  @override
  Future<String> build() {
    return ref.watch(sourceRepositoryProvider).getCurrentSourceId();
  }

  Future<void> setSource(String sourceId) async {
    state = AsyncValue.data(sourceId);
    await ref.read(sourceRepositoryProvider).setCurrentSourceId(sourceId);
    ref.invalidateSelf();
  }
}

final currentSourceAdapterProvider =
    FutureProvider<AnimeSourceAdapter>((ref) async {
  final sourceId = await ref.watch(currentSourceIdProvider.future);
  final registry = ref.watch(sourceRegistryProvider);
  return registry.getById(sourceId) ?? registry.defaultAdapter;
});
