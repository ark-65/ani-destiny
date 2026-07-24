import 'dart:io';

import 'package:path/path.dart' as p;

bool isPlayableOfflineMediaUrl(String value) {
  final rawUrl = value.trim();
  final uri = Uri.tryParse(rawUrl);
  if (rawUrl.isEmpty || uri == null || !uri.hasScheme) {
    return false;
  }
  if (uri.scheme.toLowerCase() != 'file') {
    return true;
  }

  try {
    return isPlayableOfflineMediaPath(uri.toFilePath());
  } on FormatException {
    return false;
  } on FileSystemException {
    return false;
  }
}

bool isPlayableOfflineMediaPath(String manifestPath) {
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync() || manifestFile.lengthSync() == 0) {
    return false;
  }

  final manifestDirectory = p.dirname(manifestPath);
  final content = manifestFile.readAsStringSync();
  final lines = content
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.isEmpty) {
    return false;
  }
  if (lines.first != '#EXTM3U') {
    return true;
  }

  var hasPlayableSegment = false;
  for (final line in lines.skip(1)) {
    if (line.startsWith('#')) continue;
    final segmentPath = _segmentPathFromManifestLine(
      line,
      manifestDirectory,
    );
    if (segmentPath == null) {
      return false;
    }
    final segmentFile = File(segmentPath);
    if (!segmentFile.existsSync() || segmentFile.lengthSync() == 0) {
      return false;
    }
    hasPlayableSegment = true;
  }

  return hasPlayableSegment;
}

String? _segmentPathFromManifestLine(
  String manifestLine,
  String manifestDirectory,
) {
  final normalizedLine = manifestLine.trim();
  if (normalizedLine.isEmpty) {
    return null;
  }

  final normalizedPath = _removeQueryAndFragment(normalizedLine)
      .replaceAll('\\', '/');
  final decodedPath = _decodeManifestPath(normalizedPath);

  final windowsPathPattern = RegExp(r'^[a-zA-Z]:[\\/].+');
  if (windowsPathPattern.hasMatch(decodedPath)) {
    return decodedPath;
  }

  final parsedUri = Uri.tryParse(decodedPath);
  if (parsedUri == null) return null;
  if (!parsedUri.hasScheme) {
    final segmentPath = _decodeManifestPath(parsedUri.path);
    if (segmentPath.isEmpty) {
      return null;
    }
    return p.join(manifestDirectory, segmentPath);
  }
  if (parsedUri.scheme.toLowerCase() == 'file') {
    return parsedUri.toFilePath();
  }
  return null;
}

String _removeQueryAndFragment(String rawValue) {
  final withoutQuery = rawValue.split('?').first;
  return withoutQuery.split('#').first;
}

String _decodeManifestPath(String value) {
  try {
    return Uri.decodeFull(value);
  } on FormatException {
    return value;
  }
}
