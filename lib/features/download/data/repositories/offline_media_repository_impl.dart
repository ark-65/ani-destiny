import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/offline_media_item.dart';
import '../../domain/repositories/offline_media_repository.dart';

class OfflineMediaRepositoryImpl implements OfflineMediaRepository {
  const OfflineMediaRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<OfflineMediaItem>> getAll() async {
    final query = _allItemsQuery();
    return (await query.get()).map(_itemFromRow).toList(growable: false);
  }

  @override
  Stream<List<OfflineMediaItem>> watchAll() {
    return _allItemsQuery().watch().map(
          (rows) => rows.map(_itemFromRow).toList(growable: false),
        );
  }

  @override
  Future<OfflineMediaItem?> getByDownloadTaskId(String downloadTaskId) async {
    final query = _database.select(_database.offlineMediaTable)
      ..where((table) => table.downloadTaskId.equals(downloadTaskId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _itemFromRow(row);
  }

  @override
  Future<void> upsert(OfflineMediaItem item) {
    return _database.into(_database.offlineMediaTable).insertOnConflictUpdate(
          OfflineMediaTableCompanion.insert(
            id: item.id,
            downloadTaskId: item.downloadTaskId,
            animeId: item.animeId,
            episodeId: item.episodeId,
            title: item.title,
            episodeTitle: item.episodeTitle,
            manifestPath: item.manifestPath,
            downloadedBytes: Value(item.downloadedBytes),
            createdAt: item.createdAt,
            integrityStatus: Value(item.integrityStatus.name),
            verifiedAt: Value(item.verifiedAt),
          ),
        );
  }

  @override
  Future<void> delete(String id) {
    return (_database.delete(_database.offlineMediaTable)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  SimpleSelectStatement<$OfflineMediaTableTable, OfflineMediaRow>
      _allItemsQuery() {
    return _database.select(_database.offlineMediaTable)
      ..orderBy([
        (table) => OrderingTerm(
              expression: table.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);
  }

  OfflineMediaItem _itemFromRow(OfflineMediaRow row) {
    return OfflineMediaItem(
      id: row.id,
      downloadTaskId: row.downloadTaskId,
      animeId: row.animeId,
      episodeId: row.episodeId,
      title: row.title,
      episodeTitle: row.episodeTitle,
      manifestPath: row.manifestPath,
      downloadedBytes: row.downloadedBytes,
      createdAt: row.createdAt,
      integrityStatus: OfflineMediaIntegrityStatus.values.byName(
        row.integrityStatus,
      ),
      verifiedAt: row.verifiedAt,
    );
  }
}
