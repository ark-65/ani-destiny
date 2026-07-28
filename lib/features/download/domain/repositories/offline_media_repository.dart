import '../entities/offline_media_item.dart';

abstract class OfflineMediaRepository {
  Future<List<OfflineMediaItem>> getAll();

  Stream<List<OfflineMediaItem>> watchAll();

  Future<OfflineMediaItem?> getByDownloadTaskId(String downloadTaskId);

  Future<void> upsert(OfflineMediaItem item);

  Future<void> delete(String id);
}
