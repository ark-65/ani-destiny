String sanitizeUrlForDiagnostics(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) return 'invalid-url';
  final path = uri.path.isEmpty ? '/' : uri.path;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port$path';
}
