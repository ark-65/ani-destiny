import '../entities/offline_media_item.dart';

abstract class OfflineMediaRepository {
  Future<List<OfflineMediaItem>> getAll();

  Future<OfflineMediaItem?> getByDownloadTaskId(String downloadTaskId);

  Future<void> upsert(OfflineMediaItem item);
}
