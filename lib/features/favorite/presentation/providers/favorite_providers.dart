import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/database_provider.dart';
import '../../data/repositories/favorite_repository_impl.dart';
import '../../domain/entities/favorite_anime.dart';
import '../../domain/repositories/favorite_repository.dart';

typedef FavoriteIdentity = ({String sourceId, String animeId});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(ref.watch(appDatabaseProvider));
});

final favoriteListProvider =
    StreamProvider.autoDispose<List<FavoriteAnime>>((ref) {
  return ref.watch(favoriteRepositoryProvider).watchFavorites();
});

final isFavoriteProvider =
    StreamProvider.autoDispose.family<bool, FavoriteIdentity>((ref, identity) {
  return ref.watch(favoriteRepositoryProvider).isFavorite(
        sourceId: identity.sourceId,
        animeId: identity.animeId,
      );
});
