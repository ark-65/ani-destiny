import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/database_provider.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/offline_media_repository_impl.dart';
import '../../data/services/download_task_creator.dart';
import '../../data/services/hls_manifest_loader.dart';
import '../../data/services/http_download_service.dart';
import '../../data/services/local_offline_media_service.dart';
import '../../data/services/unsupported_bt_download_service.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/offline_media_item.dart';
import '../../domain/services/hls_manifest_loader.dart';
import '../../domain/services/offline_media_service.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/offline_media_repository.dart';
import '../../domain/services/download_service.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepositoryImpl(ref.watch(appDatabaseProvider));
});

final hlsManifestLoaderProvider = Provider<HlsManifestLoader>((ref) {
  return DioHlsManifestLoader(
    dio: ref.watch(dioProvider),
  );
});

final offlineMediaRepositoryProvider = Provider<OfflineMediaRepository>((ref) {
  return OfflineMediaRepositoryImpl(ref.watch(appDatabaseProvider));
});

final offlineMediaServiceProvider = Provider<OfflineMediaService>((ref) {
  return LocalOfflineMediaService(
    repository: ref.watch(offlineMediaRepositoryProvider),
  );
});

final httpDownloadServiceProvider = Provider<DownloadService>((ref) {
  return HttpDownloadService(
    dio: ref.watch(dioProvider),
    repository: ref.watch(downloadRepositoryProvider),
    hlsManifestLoader: ref.watch(hlsManifestLoaderProvider),
    offlineMediaRepository: ref.watch(offlineMediaRepositoryProvider),
  );
});

final downloadTaskCreatorProvider = Provider<DownloadTaskCreator>((ref) {
  return DownloadTaskCreator(ref.watch(httpDownloadServiceProvider));
});

final btDownloadServiceProvider = Provider<DownloadService>((ref) {
  return const UnsupportedBtDownloadService();
});

final interruptedHlsRecoveryProvider = FutureProvider<void>((ref) {
  ref.keepAlive();
  return ref.watch(downloadRepositoryProvider).recoverInterruptedHlsTasks();
});

final downloadTasksProvider =
    StreamProvider.autoDispose<List<DownloadTask>>((ref) async* {
  final repository = ref.watch(downloadRepositoryProvider);
  await ref.watch(interruptedHlsRecoveryProvider.future);
  yield* repository.watchTasks();
});

final offlineMediaItemsProvider =
    StreamProvider.autoDispose<List<OfflineMediaItem>>((ref) {
  return ref.watch(offlineMediaRepositoryProvider).watchAll();
});

final downloadProgressProvider =
    StreamProvider.autoDispose.family<DownloadProgress, String>((ref, taskId) {
  return ref.watch(httpDownloadServiceProvider).watchProgress(taskId);
});
