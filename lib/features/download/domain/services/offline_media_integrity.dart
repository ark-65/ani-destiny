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
    final segmentPaths = _segmentPathCandidatesFromManifestLine(
      line,
      manifestDirectory,
    );
    if (segmentPaths.isEmpty) {
      return false;
    }

    final hasPlayableSegmentFile = segmentPaths.any((segmentPath) {
      final segmentFile = File(segmentPath);
      return segmentFile.existsSync() && segmentFile.lengthSync() > 0;
    });
    if (!hasPlayableSegmentFile) {
      return false;
    }
    hasPlayableSegment = true;
  }

  return hasPlayableSegment;
}

Iterable<String> _segmentPathCandidatesFromManifestLine(
  String manifestLine,
  String manifestDirectory,
) {
  final normalizedLine = manifestLine.trim();
  if (normalizedLine.isEmpty) {
    return const Iterable<String>.empty();
  }

  final parsedUri = Uri.tryParse(normalizedLine);
  if (parsedUri == null) {
    return const Iterable<String>.empty();
  }

  final windowsPathPattern = RegExp(r'^[a-zA-Z]:[\\/].+');

  if (parsedUri.hasScheme && parsedUri.scheme.length == 1) {
    final windowsDrivePath = '${parsedUri.scheme}:${parsedUri.path}';
    final windowsDriveCandidates = <String>{
      _normalizeAndDecodePath(windowsDrivePath),
      ..._decodePathCandidateVariants(windowsDrivePath),
    };
    final validWindowsDrivePaths = windowsDriveCandidates
        .where((segmentPath) => segmentPath.isNotEmpty)
        .where(windowsPathPattern.hasMatch)
        .toList(growable: false);
    if (validWindowsDrivePaths.isNotEmpty) {
      return validWindowsDrivePaths;
    }
    return const Iterable<String>.empty();
  }

  if (parsedUri.hasScheme) {
    if (parsedUri.scheme.toLowerCase() == 'file') {
      return [parsedUri.toFilePath()];
    }
    return const Iterable<String>.empty();
  }

  final segmentPathCandidates = <String>{
    _normalizePath(parsedUri.path),
    ..._decodePathCandidateVariants(parsedUri.path),
  };
  final candidateValues = segmentPathCandidates
      .where((segmentPath) => segmentPath.isNotEmpty)
      .map(
        (segmentPath) => windowsPathPattern.hasMatch(segmentPath)
            ? segmentPath
            : p.join(manifestDirectory, segmentPath),
      )
      .toList(growable: false);
  if (candidateValues.isEmpty) {
    return const Iterable<String>.empty();
  }

  return candidateValues;
}

String _decodeManifestPath(String value) {
  try {
    return Uri.decodeFull(value);
  } on FormatException {
    return value;
  }
}

Iterable<String> _decodePathCandidateVariants(String value) sync* {
  var decodedPath = value;
  for (var i = 0; i < 2; i++) {
    final nextPath = _decodeManifestPath(decodedPath);
    if (nextPath == decodedPath) {
      break;
    }
    decodedPath = nextPath;
    if (decodedPath.isNotEmpty) {
      yield _normalizePath(decodedPath);
    }
  }
}

String _normalizePath(String value) {
  return value.replaceAll('\\', '/');
}

String _normalizeAndDecodePath(String value) {
  return _normalizePath(_decodeManifestPath(value));
}
