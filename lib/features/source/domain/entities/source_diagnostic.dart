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
    this.fromSourceId,
    this.toSourceId,
    this.usedFallback = false,
    this.reason,
  });

  final String sourceId;
  final String operation;
  final SourceDiagnosticLevel level;
  final String message;
  final String? url;
  final int? statusCode;
  final String? exceptionType;
  final DateTime? timestamp;
  final String? fromSourceId;
  final String? toSourceId;
  final bool usedFallback;
  final String? reason;
}
