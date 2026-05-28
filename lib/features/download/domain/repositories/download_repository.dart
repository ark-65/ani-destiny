import '../entities/download_task.dart';

abstract class DownloadRepository {
  Stream<List<DownloadTask>> watchTasks();

  Future<DownloadTask?> getTask(String taskId);

  Future<void> upsertTask(DownloadTask task);

  Future<void> deleteTask(String taskId);
}
