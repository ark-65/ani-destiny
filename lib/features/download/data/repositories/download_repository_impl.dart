import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  const DownloadRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<DownloadTask>> watchTasks() {
    final query = _database.select(_database.downloadTaskTable)
      ..orderBy([
        (table) => OrderingTerm(
              expression: table.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.watch().map(
          (rows) => rows.map(_taskFromRow).toList(growable: false),
        );
  }

  @override
  Future<DownloadTask?> getTask(String taskId) async {
    final query = _database.select(_database.downloadTaskTable)
      ..where((table) => table.id.equals(taskId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _taskFromRow(row);
  }

  @override
  Future<void> upsertTask(DownloadTask task) {
    return _database.into(_database.downloadTaskTable).insertOnConflictUpdate(
          DownloadTaskTableCompanion.insert(
            id: task.id,
            animeId: task.animeId,
            episodeId: task.episodeId,
            sourceId: Value(task.sourceId),
            title: task.title,
            episodeTitle: task.episodeTitle,
            url: task.url,
            localPath: Value(task.localPath),
            status: task.status.name,
            progress: task.progress,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
          ),
        );
  }

  @override
  Future<void> deleteTask(String taskId) {
    return (_database.delete(_database.downloadTaskTable)
          ..where((table) => table.id.equals(taskId)))
        .go();
  }

  DownloadTask _taskFromRow(DownloadTaskRow row) {
    return DownloadTask(
      id: row.id,
      animeId: row.animeId,
      episodeId: row.episodeId,
      sourceId: row.sourceId,
      title: row.title,
      episodeTitle: row.episodeTitle,
      url: row.url,
      localPath: row.localPath,
      status: DownloadStatus.values.firstWhere(
        (status) => status.name == row.status,
        orElse: () => DownloadStatus.queued,
      ),
      progress: row.progress,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
