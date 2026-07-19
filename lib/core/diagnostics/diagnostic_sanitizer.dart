const _hiddenValue = '[hidden]';

final _urlPattern = RegExp(r'(?:https?|ftp)://[^\s<>)\]]+');
final _htmlPattern = RegExp(
  r'<!doctype|<html|<body|<script',
  caseSensitive: false,
);
final _sensitiveAssignmentPattern = RegExp(
  r'\b(token|secret|cookie|authorization|password|api[_-]?key|access[_-]?key|session|signature|sign)\b\s*[:=]\s*([^\s,&;]+)',
  caseSensitive: false,
);
final _dandanplayEnvPattern = RegExp(
  r'\bDANDANPLAY_APP_(?:ID|SECRET)\b\s*[:=]\s*([^\s,&;]+)',
  caseSensitive: false,
);
final _bearerPattern = RegExp(
  r'\bBearer\s+[A-Za-z0-9._~+/=-]+',
  caseSensitive: false,
);
final _sourceFallbackAttemptPrefix = RegExp(
  r'^Source attempt \d+:\s*',
  caseSensitive: false,
);
final _fallbackReasonMarkerPattern = RegExp(
  r'Fallback reason\s*[:＝=]\s*(?<reason>.*)$',
  caseSensitive: false,
);
final _sourceFallbackMessageBoilerplate = RegExp(
  r'^source fallback used[\s:：。！!;；,，/\|｜\-–—.·\(（【\[\]<>→=＝]*(?<reason>.*)$',
  caseSensitive: false,
);

String sanitizeUrl(String url) {
  final raw = url.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme) return 'invalid-url';

  if (uri.host.isEmpty) return '${uri.scheme}:$_hiddenValue';

  final port = uri.hasPort ? ':${uri.port}' : '';
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
  final basename = segments.isEmpty ? '' : segments.last;
  final path = basename.isEmpty ? '/' : '/.../$basename';
  return '${uri.scheme}://${uri.host}$port$path';
}

Map<String, String> sanitizeHeaders(Map<String, String> headers) {
  final entries = headers.entries.map(
    (entry) => MapEntry(entry.key.trim(), _hiddenValue),
  );
  return Map.unmodifiable(Map.fromEntries(entries));
}

String sanitizePath(String path) {
  return path
      .replaceAllMapped(
        RegExp(r'([A-Z]:\\Users\\)[^\\/\s]+', caseSensitive: false),
        (match) => '${match.group(1)}<user>',
      )
      .replaceAllMapped(
        RegExp(r'(/Users/)[^/\s]+'),
        (match) => '${match.group(1)}<user>',
      )
      .replaceAllMapped(
        RegExp(r'(/home/)[^/\s]+'),
        (match) => '${match.group(1)}<user>',
      );
}

String sanitizeError(Object error) {
  final raw = error.toString();
  if (_htmlPattern.hasMatch(raw)) return 'HTML document omitted';

  var text = raw
      .replaceAllMapped(_urlPattern, (match) => sanitizeUrl(match.group(0)!))
      .replaceAll(_dandanplayEnvPattern, '[sensitive]=$_hiddenValue')
      .replaceAll(_bearerPattern, 'Bearer $_hiddenValue')
      .replaceAllMapped(
        _sensitiveAssignmentPattern,
        (match) => '[sensitive]=$_hiddenValue',
      );

  text = sanitizePath(text).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return 'Unavailable';
  if (text.length <= 220) return text;
  return '${text.substring(0, 217)}...';
}

String? sanitizeSourceFallbackNoticeReason(String? reason) {
  final normalized = reason?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final fallbackReason = _fallbackReasonMarkerPattern.firstMatch(normalized);
  final extractedReason = _stripSourceFallbackBoilerplate(
    fallbackReason?.namedGroup('reason')?.trim() ?? normalized,
  );
  if (extractedReason == null || extractedReason.isEmpty) return null;

  final sourceFallbackMatch = _sourceFallbackMessageBoilerplate.firstMatch(
    extractedReason,
  );
  final extracted = _stripSourceFallbackBoilerplate(
    sourceFallbackMatch?.namedGroup('reason')?.trim() ?? extractedReason,
  );
  if (extracted == null || extracted.isEmpty) return null;

  if (!_sourceFallbackAttemptPrefix.hasMatch(extracted)) {
    return extracted;
  }

  final reasons = extracted
      .split(' · ')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .map((entry) => entry.replaceFirst(_sourceFallbackAttemptPrefix, ''))
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);

  if (reasons.isEmpty) return null;
  if (reasons.length == 1) return reasons.single;

  return reasons.join('\n');
}

String? _stripSourceFallbackBoilerplate(String? reason) {
  final normalized = reason?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  if ((normalized.startsWith('(') && normalized.endsWith(')')) ||
      (normalized.startsWith('[') && normalized.endsWith(']')) ||
      (normalized.startsWith('<') && normalized.endsWith('>')) ||
      (normalized.startsWith('（') && normalized.endsWith('）')) ||
      (normalized.startsWith('【') && normalized.endsWith('】'))) {
    if (normalized.length <= 2) return null;
    return normalized.substring(1, normalized.length - 1).trim();
  }

  return normalized;
}
