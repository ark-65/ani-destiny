import '../entities/watch_history.dart';

abstract class HistoryRepository {
  Stream<List<WatchHistory>> watchHistory();

  Future<WatchHistory?> getByEpisode(String episodeId);

  Future<void> upsert(WatchHistory history);

  Future<void> delete(String id);

  Future<void> clear();
}
