import 'download_failure_reason.dart';
import 'download_kind.dart';

const _unset = Object();

const unexpectedDownloadFailureMessage =
    'AniDestiny could not finish this download because of an unexpected error.';

enum DownloadStatus {
  pending,
  preparing,
  downloading,
  paused,
  completed,
  failed,
  canceled,
  unsupported,
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.animeId,
    required this.episodeId,
    required this.sourceId,
    required this.title,
    required this.episodeTitle,
    required this.url,
    required this.kind,
    this.headers = const {},
    required this.status,
    this.failureReason = DownloadFailureReason.none,
    this.failureMessage,
    required this.progress,
    this.totalBytes,
    this.downloadedBytes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.localPath,
  });

  final String id;
  final String animeId;
  final String episodeId;
  final String sourceId;
  final String title;
  final String episodeTitle;
  final String url;
  final DownloadKind kind;
  final Map<String, String> headers;
  final String? localPath;
  final DownloadStatus status;
  final DownloadFailureReason failureReason;
  final String? failureMessage;
  final double progress;
  final int? totalBytes;
  final int downloadedBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DownloadTask copyWith({
    Object? localPath = _unset,
    DownloadKind? kind,
    Map<String, String>? headers,
    DownloadStatus? status,
    DownloadFailureReason? failureReason,
    Object? failureMessage = _unset,
    double? progress,
    Object? totalBytes = _unset,
    int? downloadedBytes,
    DateTime? updatedAt,
  }) {
    return DownloadTask(
      id: id,
      animeId: animeId,
      episodeId: episodeId,
      sourceId: sourceId,
      title: title,
      episodeTitle: episodeTitle,
      url: url,
      kind: kind ?? this.kind,
      headers: headers ?? this.headers,
      localPath:
          identical(localPath, _unset) ? this.localPath : localPath as String?,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      failureMessage: identical(failureMessage, _unset)
          ? this.failureMessage
          : failureMessage as String?,
      progress: progress ?? this.progress,
      totalBytes:
          identical(totalBytes, _unset) ? this.totalBytes : totalBytes as int?,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DownloadStatus downloadStatusFromName(String value) {
  return switch (value) {
    'queued' => DownloadStatus.pending,
    'running' => DownloadStatus.downloading,
    _ => DownloadStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => DownloadStatus.pending,
      ),
  };
}

DownloadTask normalizeDownloadTask(DownloadTask task) {
  final failureMessage = task.failureMessage;
  if (failureMessage == null) {
    return task;
  }
  if (task.failureReason == DownloadFailureReason.unsupportedType) {
    return task.copyWith(failureMessage: null);
  }
  if (task.status == DownloadStatus.failed &&
      _looksLikeRawException(failureMessage)) {
    return task.copyWith(failureMessage: unexpectedDownloadFailureMessage);
  }
  return task;
}

bool _looksLikeRawException(String message) {
  final trimmed = message.trimLeft();
  return trimmed.startsWith('AppException') ||
      trimmed.startsWith('ArgumentError') ||
      trimmed.startsWith('AssertionError') ||
      trimmed.startsWith('Bad state:') ||
      trimmed.startsWith('CERTIFICATE_VERIFY_FAILED') ||
      trimmed.startsWith('CertificateException') ||
      trimmed.startsWith('ClientException') ||
      trimmed.startsWith('ConcurrentModificationError') ||
      trimmed.startsWith('Connection closed') ||
      trimmed.startsWith('Connection refused') ||
      trimmed.startsWith('Connection reset') ||
      trimmed.startsWith('Connection timed out') ||
      trimmed.startsWith('DioException') ||
      trimmed.startsWith('Exception:') ||
      trimmed.startsWith('Failed host lookup') ||
      trimmed.startsWith('FileSystemException') ||
      trimmed.startsWith('FormatException') ||
      trimmed.startsWith('HttpException') ||
      trimmed.startsWith('IntegerDivisionByZeroException') ||
      trimmed.startsWith('Invalid argument(s):') ||
      trimmed.startsWith('Instance of ') ||
      trimmed.startsWith('IOException') ||
      trimmed.startsWith('NetworkException') ||
      trimmed.startsWith('NoSuchMethodError') ||
      trimmed.startsWith('Network is unreachable') ||
      trimmed.startsWith('No route to host') ||
      trimmed.startsWith('No space left on device') ||
      trimmed.startsWith('HandshakeException') ||
      trimmed.startsWith('Operation timed out') ||
      trimmed.startsWith('OS Error:') ||
      trimmed.startsWith('PathAccessException') ||
      trimmed.startsWith('PathExistsException') ||
      trimmed.startsWith('PathNotFoundException') ||
      trimmed.startsWith('PlatformException') ||
      trimmed.startsWith('Permission denied') ||
      trimmed.startsWith('RangeError') ||
      trimmed.startsWith('SocketException') ||
      trimmed.startsWith('StateError:') ||
      trimmed.startsWith('TimeoutException') ||
      trimmed.startsWith('TlsException') ||
      trimmed.startsWith('UnknownHostException') ||
      trimmed.startsWith('UnimplementedError:') ||
      trimmed.startsWith('Unsupported operation:') ||
      trimmed.startsWith('XMLHttpRequest error');
}
