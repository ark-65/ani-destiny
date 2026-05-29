import 'download_task.dart';

class DownloadProgress {
  const DownloadProgress({
    required this.taskId,
    required this.progress,
    required this.status,
    this.downloadedBytes = 0,
    this.totalBytes,
  });

  final String taskId;
  final double progress;
  final DownloadStatus status;
  final int downloadedBytes;
  final int? totalBytes;
}
