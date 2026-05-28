import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../source/presentation/providers/source_providers.dart';
import '../../data/repositories/anime_repository_impl.dart';
import '../../../source/domain/entities/source_fallback_result.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/entities/play_source.dart';
import '../../domain/entities/schedule_item.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/anime_repository.dart';

typedef SourceAnimeRequest = ({String sourceId, String animeId});
typedef SourceEpisodeRequest = ({String sourceId, String episodeId});

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepositoryImpl(
    fallbackService: ref.watch(sourceFallbackServiceProvider),
  );
});

final animeDetailProvider = FutureProvider.autoDispose
    .family<SourceFallbackResult<AnimeDetail>, String>((ref, animeId) async {
  await ref.watch(currentSourceIdProvider.future);
  return ref.watch(animeRepositoryProvider).getAnimeDetail(animeId);
});

final playSourcesProvider = FutureProvider.autoDispose
    .family<SourceFallbackResult<List<PlaySource>>, String>(
  (ref, episodeId) async {
    await ref.watch(currentSourceIdProvider.future);
    return ref.watch(animeRepositoryProvider).getPlaySources(episodeId);
  },
);

final animeDetailBySourceProvider = FutureProvider.autoDispose
    .family<SourceFallbackResult<AnimeDetail>, SourceAnimeRequest>(
        (ref, request) async {
  return ref.watch(animeRepositoryProvider).getAnimeDetailFromSource(
        sourceId: request.sourceId,
        animeId: request.animeId,
      );
});

final playSourcesBySourceProvider = FutureProvider.autoDispose
    .family<SourceFallbackResult<List<PlaySource>>, SourceEpisodeRequest>(
        (ref, request) async {
  return ref.watch(animeRepositoryProvider).getPlaySourcesFromSource(
        sourceId: request.sourceId,
        episodeId: request.episodeId,
      );
});

final searchResultsProvider = FutureProvider.autoDispose
    .family<SourceFallbackResult<List<SearchResult>>, String>(
  (ref, keyword) async {
    final sourceId = await ref.watch(currentSourceIdProvider.future);
    if (keyword.trim().isEmpty) {
      return SourceFallbackResult<List<SearchResult>>(
        value: const [],
        sourceId: sourceId,
        usedFallback: false,
      );
    }
    return ref.watch(animeRepositoryProvider).search(keyword);
  },
);

final scheduleProvider =
    FutureProvider.autoDispose<SourceFallbackResult<List<ScheduleItem>>>(
        (ref) async {
  await ref.watch(currentSourceIdProvider.future);
  return ref.watch(animeRepositoryProvider).getSchedule();
});
