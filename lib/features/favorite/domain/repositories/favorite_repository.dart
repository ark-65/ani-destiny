import '../entities/favorite_anime.dart';

abstract class FavoriteRepository {
  Stream<List<FavoriteAnime>> watchFavorites();

  Stream<bool> isFavorite({
    required String sourceId,
    required String animeId,
  });

  Future<void> add(FavoriteAnime anime);

  Future<void> remove({
    required String sourceId,
    required String animeId,
  });

  Future<void> toggle(FavoriteAnime anime);
}
