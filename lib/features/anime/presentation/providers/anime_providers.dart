import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../source/presentation/providers/source_providers.dart';
import '../../data/repositories/anime_repository_impl.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/entities/play_source.dart';
import '../../domain/entities/schedule_item.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/anime_repository.dart';

typedef SourceAnimeRequest = ({String sourceId, String animeId});
typedef SourceEpisodeRequest = ({String sourceId, String episodeId});

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepositoryImpl(
    sourceRepository: ref.watch(sourceRepositoryProvider),
  );
});

final animeDetailProvider = FutureProvider.autoDispose
    .family<AnimeDetail, String>((ref, animeId) async {
  await ref.watch(currentSourceIdProvider.future);
  return ref.watch(animeRepositoryProvider).getAnimeDetail(animeId);
});

final playSourcesProvider =
    FutureProvider.autoDispose.family<List<PlaySource>, String>(
  (ref, episodeId) async {
    await ref.watch(currentSourceIdProvider.future);
    return ref.watch(animeRepositoryProvider).getPlaySources(episodeId);
  },
);

final animeDetailBySourceProvider = FutureProvider.autoDispose
    .family<AnimeDetail, SourceAnimeRequest>((ref, request) async {
  final registry = ref.watch(sourceRegistryProvider);
  final adapter = registry.getById(request.sourceId) ?? registry.defaultAdapter;
  return adapter.getAnimeDetail(request.animeId);
});

final playSourcesBySourceProvider = FutureProvider.autoDispose
    .family<List<PlaySource>, SourceEpisodeRequest>((ref, request) async {
  final registry = ref.watch(sourceRegistryProvider);
  final adapter = registry.getById(request.sourceId) ?? registry.defaultAdapter;
  return adapter.getPlaySources(request.episodeId);
});

final searchResultsProvider =
    FutureProvider.autoDispose.family<List<SearchResult>, String>(
  (ref, keyword) async {
    await ref.watch(currentSourceIdProvider.future);
    if (keyword.trim().isEmpty) return [];
    return ref.watch(animeRepositoryProvider).search(keyword);
  },
);

final scheduleProvider =
    FutureProvider.autoDispose<List<ScheduleItem>>((ref) async {
  await ref.watch(currentSourceIdProvider.future);
  return ref.watch(animeRepositoryProvider).getSchedule();
});
