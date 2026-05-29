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
