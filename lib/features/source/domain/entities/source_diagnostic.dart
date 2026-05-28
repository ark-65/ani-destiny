enum SourceDiagnosticLevel {
  info,
  warning,
  error,
}

class SourceDiagnostic {
  const SourceDiagnostic({
    required this.sourceId,
    required this.operation,
    required this.level,
    required this.message,
    this.url,
    this.statusCode,
    this.exceptionType,
    this.timestamp,
  });

  final String sourceId;
  final String operation;
  final SourceDiagnosticLevel level;
  final String message;
  final String? url;
  final int? statusCode;
  final String? exceptionType;
  final DateTime? timestamp;
}
