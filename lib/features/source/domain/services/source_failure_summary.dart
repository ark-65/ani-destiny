import '../../../../core/diagnostics/diagnostic_sanitizer.dart';

String summarizeSourceFailure(
  Object error, {
  int maxLength = 140,
}) {
  final text = sanitizeError(error);
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}
