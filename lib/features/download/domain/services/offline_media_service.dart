import '../entities/offline_media_item.dart';

abstract class OfflineMediaService {
  Future<OfflineMediaIntegrityStatus> verify(OfflineMediaItem item);

  Future<void> remove(OfflineMediaItem item);

  Future<void> removeAll(Iterable<OfflineMediaItem> items);
}
