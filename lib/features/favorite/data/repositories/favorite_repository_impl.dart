import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/favorite_anime.dart';
import '../../domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  const FavoriteRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<FavoriteAnime>> watchFavorites() {
    final query = _database.select(_database.favoriteAnimeTable)
      ..orderBy([
        (table) => OrderingTerm(
              expression: table.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.watch().map(
          (rows) => rows.map(_favoriteFromRow).toList(growable: false),
        );
  }

  @override
  Stream<bool> isFavorite(String animeId) {
    final query = _database.select(_database.favoriteAnimeTable)
      ..where((table) => table.animeId.equals(animeId))
      ..limit(1);
    return query.watchSingleOrNull().map((row) => row != null);
  }

  @override
  Future<void> add(FavoriteAnime anime) {
    return _database.into(_database.favoriteAnimeTable).insertOnConflictUpdate(
          FavoriteAnimeTableCompanion.insert(
            animeId: anime.animeId,
            title: anime.title,
            coverUrl: Value(anime.coverUrl),
            sourceId: anime.sourceId,
            createdAt: anime.createdAt,
          ),
        );
  }

  @override
  Future<void> remove(String animeId) {
    return (_database.delete(_database.favoriteAnimeTable)
          ..where((table) => table.animeId.equals(animeId)))
        .go();
  }

  @override
  Future<void> toggle(FavoriteAnime anime) async {
    final query = _database.select(_database.favoriteAnimeTable)
      ..where((table) => table.animeId.equals(anime.animeId))
      ..limit(1);
    final existing = await query.getSingleOrNull();
    if (existing == null) {
      await add(anime);
    } else {
      await remove(anime.animeId);
    }
  }

  FavoriteAnime _favoriteFromRow(FavoriteAnimeRow row) {
    return FavoriteAnime(
      animeId: row.animeId,
      title: row.title,
      coverUrl: row.coverUrl,
      sourceId: row.sourceId,
      createdAt: row.createdAt,
    );
  }
}
