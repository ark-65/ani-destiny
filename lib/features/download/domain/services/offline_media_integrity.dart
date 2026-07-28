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
  return _isPlayableOfflineMediaPath(manifestPath, <String>{});
}

bool _isPlayableOfflineMediaPath(String manifestPath, Set<String> visited) {
  final normalizedManifestPath = p.normalize(p.absolute(manifestPath));
  if (!visited.add(normalizedManifestPath)) {
    return false;
  }
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
  var nextSegmentIsGap = false;
  for (final line in lines.skip(1)) {
    if (line.startsWith('#EXT-X-MEDIA:')) {
      final renditionUri = _uriAttributeFromTag(line);
      if (renditionUri == null ||
          !_hasPlayableNestedManifest(
            renditionUri,
            manifestDirectory,
            visited,
          )) {
        return false;
      }
      continue;
    }
    if (line.startsWith('#EXT-X-KEY:')) {
      final keyUri = _uriAttributeFromTag(line);
      if (line.contains('METHOD=NONE')) continue;
      if (keyUri == null ||
          !_hasPlayableManifestAsset(
            keyUri,
            manifestDirectory,
            expectedLength: 16,
          )) {
        return false;
      }
      continue;
    }
    if (line.startsWith('#EXT-X-MAP:')) {
      final initializationUri = _uriAttributeFromTag(line);
      if (initializationUri == null ||
          !_hasPlayableManifestAsset(
            initializationUri,
            manifestDirectory,
          )) {
        return false;
      }
      continue;
    }
    if (line == '#EXT-X-GAP') {
      nextSegmentIsGap = true;
      continue;
    }
    if (line.startsWith('#')) continue;
    if (nextSegmentIsGap) {
      nextSegmentIsGap = false;
      continue;
    }
    final nestedManifestPaths = _nestedManifestPaths(line, manifestDirectory);
    if (nestedManifestPaths.isNotEmpty) {
      if (!nestedManifestPaths.any(
        (candidate) => _isPlayableOfflineMediaPath(candidate, visited),
      )) {
        return false;
      }
      hasPlayableSegment = true;
      continue;
    }
    if (!_hasPlayableManifestAsset(line, manifestDirectory)) {
      return false;
    }
    hasPlayableSegment = true;
  }

  return hasPlayableSegment;
}

bool _hasPlayableNestedManifest(
  String value,
  String manifestDirectory,
  Set<String> visited,
) {
  final candidates = _nestedManifestPaths(value, manifestDirectory);
  return candidates.isNotEmpty &&
      candidates.any(
        (candidate) => _isPlayableOfflineMediaPath(candidate, visited),
      );
}

Iterable<String> _nestedManifestPaths(
  String value,
  String manifestDirectory,
) {
  return _segmentPathCandidatesFromManifestLine(
    value,
    manifestDirectory,
  ).where((candidate) => p.extension(candidate).toLowerCase() == '.m3u8');
}

bool _hasPlayableManifestAsset(
  String value,
  String manifestDirectory, {
  int? expectedLength,
}) {
  final segmentPaths = _segmentPathCandidatesFromManifestLine(
    value,
    manifestDirectory,
  );
  return segmentPaths.any((segmentPath) {
    final segmentFile = File(segmentPath);
    return segmentFile.existsSync() &&
        (expectedLength == null
            ? segmentFile.lengthSync() > 0
            : segmentFile.lengthSync() == expectedLength);
  });
}

String? _uriAttributeFromTag(String line) {
  final quotedMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
  if (quotedMatch != null) {
    return quotedMatch.group(1);
  }
  return RegExp(r'URI=([^,]+)').firstMatch(line)?.group(1)?.trim();
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
