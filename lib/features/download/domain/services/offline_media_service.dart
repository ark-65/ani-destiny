import '../entities/offline_media_item.dart';

abstract class OfflineMediaService {
  Future<void> remove(OfflineMediaItem item);
}
