import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('WatchHistoryRow')
class WatchHistoryTable extends Table {
  @override
  String get tableName => 'watch_history';

  TextColumn get id => text()();
  TextColumn get animeId => text().named('anime_id')();
  TextColumn get episodeId => text().named('episode_id')();
  TextColumn get animeTitle => text().named('anime_title')();
  TextColumn get episodeTitle => text().named('episode_title')();
  TextColumn get coverUrl => text().named('cover_url').nullable()();
  IntColumn get positionMs => integer().named('position_ms')();
  IntColumn get durationMs => integer().named('duration_ms').nullable()();
  TextColumn get sourceId => text().named('source_id')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FavoriteAnimeRow')
class FavoriteAnimeTable extends Table {
  @override
  String get tableName => 'favorite_anime';

  TextColumn get animeId => text().named('anime_id')();
  TextColumn get title => text()();
  TextColumn get coverUrl => text().named('cover_url').nullable()();
  TextColumn get sourceId => text().named('source_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {sourceId, animeId};
}

@DataClassName('DownloadTaskRow')
class DownloadTaskTable extends Table {
  @override
  String get tableName => 'download_task';

  TextColumn get id => text()();
  TextColumn get animeId => text().named('anime_id')();
  TextColumn get episodeId => text().named('episode_id')();
  TextColumn get title => text()();
  TextColumn get episodeTitle => text().named('episode_title')();
  TextColumn get sourceId =>
      text().named('source_id').withDefault(const Constant('mock'))();
  TextColumn get url => text()();
  TextColumn get localPath => text().named('local_path').nullable()();
  TextColumn get status => text()();
  RealColumn get progress => real()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    WatchHistoryTable,
    FavoriteAnimeTable,
    DownloadTaskTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ani_destiny'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(
              downloadTaskTable,
              downloadTaskTable.sourceId,
            );
          }
        },
      );
}
