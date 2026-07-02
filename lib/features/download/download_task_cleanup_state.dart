import 'dart:io';

import 'package:flutter/foundation.dart';

import 'domain/entities/download_kind.dart';
import 'domain/entities/download_task.dart';

typedef DownloadCleanupPathExists = bool Function(String localPath);

DownloadCleanupPathExists? _debugDownloadCleanupPathExists;

@visibleForTesting
void debugSetDownloadCleanupPathExists(
  DownloadCleanupPathExists? exists,
) {
  _debugDownloadCleanupPathExists = exists;
}

bool downloadTaskHasRetainedPartialFile(DownloadTask task) {
  final localPath = task.localPath;
  if (localPath == null || localPath.isEmpty) {
    return false;
  }
  if (task.kind != DownloadKind.directFile) {
    return false;
  }
  if (task.status != DownloadStatus.failed &&
      task.status != DownloadStatus.canceled) {
    return false;
  }
  try {
    return (_debugDownloadCleanupPathExists ?? _defaultPathExists)(localPath);
  } on FileSystemException {
    return true;
  }
}

bool downloadTaskNeedsManualCleanup(DownloadTask task) {
  return task.status == DownloadStatus.canceled &&
      downloadTaskHasRetainedPartialFile(task);
}

bool downloadTaskShowsLocalPath(DownloadTask task) {
  final localPath = task.localPath;
  if (localPath == null || localPath.isEmpty) {
    return false;
  }
  return task.status == DownloadStatus.completed ||
      downloadTaskNeedsManualCleanup(task);
}

bool _defaultPathExists(String localPath) {
  return File(localPath).existsSync();
}
