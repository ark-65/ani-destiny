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
import '../../domain/repositories/source_repository.dart';

final sourceRegistryProvider = Provider<SourceRegistry>((ref) {
  final dio = ref.watch(dioProvider);
  return SourceRegistry(
    adapters: [
      MockAnimeSourceAdapter(),
      SakuraAnimeSourceAdapter(dio: dio),
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
