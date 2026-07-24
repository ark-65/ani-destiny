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
  final parsedUri = Uri.tryParse(manifestLine);
  if (parsedUri == null) return null;
  if (!parsedUri.hasScheme) {
    return p.join(manifestDirectory, manifestLine);
  }
  if (parsedUri.scheme.toLowerCase() == 'file') {
    return parsedUri.toFilePath();
  }
  return null;
}
