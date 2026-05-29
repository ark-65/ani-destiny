import '../diagnostics/diagnostic_sanitizer.dart' as diagnostics;

String sanitizeUrlForDiagnostics(String rawUrl) {
  return diagnostics.sanitizeUrl(rawUrl);
}
