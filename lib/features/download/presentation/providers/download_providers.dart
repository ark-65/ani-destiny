import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/database_provider.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/services/bt_download_service_placeholder.dart';
import '../../data/services/http_download_service.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/services/download_service.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepositoryImpl(ref.watch(appDatabaseProvider));
});

final httpDownloadServiceProvider = Provider<DownloadService>((ref) {
  return HttpDownloadService(
    dio: ref.watch(dioProvider),
    repository: ref.watch(downloadRepositoryProvider),
  );
});

final btDownloadServiceProvider = Provider<DownloadService>((ref) {
  return const BtDownloadServicePlaceholder();
});

final downloadTasksProvider =
    StreamProvider.autoDispose<List<DownloadTask>>((ref) {
  return ref.watch(downloadRepositoryProvider).watchTasks();
});

final downloadProgressProvider =
    StreamProvider.autoDispose.family<DownloadProgress, String>((ref, taskId) {
  return ref.watch(httpDownloadServiceProvider).watchProgress(taskId);
});
