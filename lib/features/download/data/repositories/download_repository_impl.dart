import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/download_failure_reason.dart';
import '../../domain/entities/download_kind.dart';
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
    final normalizedTask = normalizeDownloadTask(task);
    return _database.into(_database.downloadTaskTable).insertOnConflictUpdate(
          DownloadTaskTableCompanion.insert(
            id: normalizedTask.id,
            animeId: normalizedTask.animeId,
            episodeId: normalizedTask.episodeId,
            sourceId: Value(normalizedTask.sourceId),
            title: normalizedTask.title,
            episodeTitle: normalizedTask.episodeTitle,
            url: normalizedTask.url,
            kind: Value(normalizedTask.kind.name),
            headersJson: Value(jsonEncode(normalizedTask.headers)),
            localPath: Value(normalizedTask.localPath),
            status: normalizedTask.status.name,
            failureReason: Value(normalizedTask.failureReason.name),
            failureMessage: Value(normalizedTask.failureMessage),
            progress: normalizedTask.progress,
            totalBytes: Value(normalizedTask.totalBytes),
            downloadedBytes: Value(normalizedTask.downloadedBytes),
            createdAt: normalizedTask.createdAt,
            updatedAt: normalizedTask.updatedAt,
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
    return normalizeDownloadTask(
      DownloadTask(
        id: row.id,
        animeId: row.animeId,
        episodeId: row.episodeId,
        sourceId: row.sourceId,
        title: row.title,
        episodeTitle: row.episodeTitle,
        url: row.url,
        kind: downloadKindFromName(row.kind),
        headers: _headersFromJson(row.headersJson),
        localPath: row.localPath,
        status: downloadStatusFromName(row.status),
        failureReason: downloadFailureReasonFromName(row.failureReason),
        failureMessage: row.failureMessage,
        progress: row.progress,
        totalBytes: row.totalBytes,
        downloadedBytes: row.downloadedBytes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      ),
    );
  }

  Map<String, String> _headersFromJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on Object {
      return const {};
    }
  }
}
