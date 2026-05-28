import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/preferences_provider.dart';
import '../../data/adapters/mock_anime_source_adapter.dart';
import '../../data/adapters/remote_source_proxy_adapter.dart';
import '../../data/adapters/sakura_anime_source_adapter.dart';
import '../../data/registry/source_registry.dart';
import '../../data/repositories/source_repository_impl.dart';
import '../../domain/adapters/anime_source_adapter.dart';
import '../../domain/entities/anime_source.dart';
import '../../domain/entities/source_diagnostic.dart';
import '../../domain/repositories/source_repository.dart';
import '../../domain/services/source_diagnostic_recorder.dart';

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
