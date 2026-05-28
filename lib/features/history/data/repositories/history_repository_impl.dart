import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/watch_history.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<WatchHistory>> watchHistory() {
    final query = _database.select(_database.watchHistoryTable)
      ..orderBy([
        (table) => OrderingTerm(
              expression: table.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.watch().map(
          (rows) => rows.map(_historyFromRow).toList(growable: false),
        );
  }

  @override
  Future<WatchHistory?> getByEpisode(String episodeId) async {
    final query = _database.select(_database.watchHistoryTable)
      ..where((table) => table.episodeId.equals(episodeId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _historyFromRow(row);
  }

  @override
  Future<void> upsert(WatchHistory history) {
    return _database.into(_database.watchHistoryTable).insertOnConflictUpdate(
          WatchHistoryTableCompanion.insert(
            id: history.id,
            animeId: history.animeId,
            episodeId: history.episodeId,
            animeTitle: history.animeTitle,
            episodeTitle: history.episodeTitle,
            coverUrl: Value(history.coverUrl),
            positionMs: history.position.inMilliseconds,
            durationMs: Value(history.duration?.inMilliseconds),
            sourceId: history.sourceId,
            updatedAt: history.updatedAt,
          ),
        );
  }

  @override
  Future<void> delete(String id) {
    return (_database.delete(_database.watchHistoryTable)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  @override
  Future<void> clear() {
    return _database.delete(_database.watchHistoryTable).go();
  }

  WatchHistory _historyFromRow(WatchHistoryRow row) {
    return WatchHistory(
      id: row.id,
      animeId: row.animeId,
      episodeId: row.episodeId,
      animeTitle: row.animeTitle,
      episodeTitle: row.episodeTitle,
      coverUrl: row.coverUrl,
      position: Duration(milliseconds: row.positionMs),
      duration: row.durationMs == null
          ? null
          : Duration(milliseconds: row.durationMs!),
      sourceId: row.sourceId,
      updatedAt: row.updatedAt,
    );
  }
}
