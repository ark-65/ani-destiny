import '../entities/favorite_anime.dart';

abstract class FavoriteRepository {
  Stream<List<FavoriteAnime>> watchFavorites();

  Stream<bool> isFavorite(String animeId);

  Future<void> add(FavoriteAnime anime);

  Future<void> remove(String animeId);

  Future<void> toggle(FavoriteAnime anime);
}
