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
  if (path.endsWith(extension)) {
    return true;
  }

  if (parsed == null) {
    return false;
  }

  return parsed.queryParameters.values.any((value) {
    final decoded = Uri.decodeComponent(value);
    final valueUri = Uri.tryParse(decoded);
    final candidatePath = valueUri?.path.toLowerCase() ?? decoded;
    return candidatePath.endsWith(extension);
  }) ||
      _endsWithPathLikeExtension(parsed.fragment, extension);
}

bool _endsWithPathLikeExtension(String fragment, String extension) {
  if (fragment.trim().isEmpty) return false;

  final decoded = Uri.decodeComponent(fragment);
  final normalized = decoded.toLowerCase().replaceAll('\n', '').replaceAll('\r', '');
  final path = normalized.split('#').first;
  return path.endsWith(extension);
}
