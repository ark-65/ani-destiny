import '../entities/download_kind.dart';

DownloadKind detectDownloadKind(String url, {String? contentType}) {
  final trimmedUrl = url.trim();
  final normalizedUrl = trimmedUrl.toLowerCase();
  final normalizedContentType = contentType?.trim().toLowerCase() ?? '';
  final parsedUrl = Uri.tryParse(trimmedUrl);

  if (normalizedUrl.startsWith('magnet:')) {
    return DownloadKind.bt;
  }
  if (_isHlsContentType(normalizedContentType) ||
      _pathEndsWith(normalizedUrl, '.m3u8') ||
      _uriContainsM3u8Marker(parsedUrl)) {
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

bool _uriContainsM3u8Marker(Uri? uri) {
  if (uri == null) {
    return false;
  }

  if (_pathEndsWith(uri.path, '.m3u8')) {
    return true;
  }

  final valuesToProbe = <String>[
    uri.fragment,
    ...uri.queryParameters.values,
  ];

  return valuesToProbe.any(_looksLikeM3u8Path);
}

bool _looksLikeM3u8Path(String value) {
  if (_pathEndsWith(value, '.m3u8')) {
    return true;
  }

  try {
    final decoded = Uri.decodeComponent(value).toLowerCase();
    if (_pathEndsWith(decoded, '.m3u8')) {
      return true;
    }
  } on FormatException {
    return false;
  }

  final parsed = Uri.tryParse(value);
  if (parsed == null) {
    return false;
  }
  if (_pathEndsWith(parsed.path, '.m3u8')) {
    return true;
  }
  final parsedDecoded = parsed.toString();
  try {
    final decodedParsed = Uri.decodeComponent(parsedDecoded).toLowerCase();
    return _pathEndsWith(decodedParsed, '.m3u8');
  } on FormatException {
    return false;
  }
}
