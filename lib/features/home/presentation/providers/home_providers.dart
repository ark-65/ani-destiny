import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../anime/domain/entities/anime.dart';
import '../../../anime/presentation/providers/anime_providers.dart';
import '../../../source/presentation/providers/source_providers.dart';

final homeRecommendationsProvider =
    FutureProvider.autoDispose<List<Anime>>((ref) async {
  await ref.watch(currentSourceIdProvider.future);
  return ref.watch(animeRepositoryProvider).getHomeRecommendations();
});
