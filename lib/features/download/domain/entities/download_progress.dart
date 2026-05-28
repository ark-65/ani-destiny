import 'download_task.dart';

class DownloadProgress {
  const DownloadProgress({
    required this.taskId,
    required this.progress,
    required this.status,
  });

  final String taskId;
  final double progress;
  final DownloadStatus status;
}
