import '../entities/download_kind.dart';

DownloadKind detectDownloadKind(String url, {String? contentType}) {
  final normalizedUrl = url.trim().toLowerCase();
  final normalizedContentType = contentType?.trim().toLowerCase() ?? '';

  if (normalizedUrl.startsWith('magnet:')) {
    return DownloadKind.bt;
  }
  if (_isHlsContentType(normalizedContentType) ||
      _pathEndsWith(normalizedUrl, '.m3u8')) {
    return DownloadKind.hls;
  }
  if (_directFileExtensions.any((extension) {
    return _pathEndsWith(normalizedUrl, extension);
  })) {
    return DownloadKind.directFile;
  }
  return DownloadKind.unknown;
}

const _directFileExtensions = [
  '.mp4',
  '.mkv',
  '.webm',
  '.mov',
];

bool _isHlsContentType(String contentType) {
  return contentType.contains('application/vnd.apple.mpegurl') ||
      contentType.contains('application/x-mpegurl') ||
      contentType.contains('audio/mpegurl') ||
      contentType.contains('audio/x-mpegurl');
}

bool _pathEndsWith(String url, String extension) {
  final parsed = Uri.tryParse(url);
  final path = parsed?.path.toLowerCase() ?? url;
  return path.endsWith(extension);
}
