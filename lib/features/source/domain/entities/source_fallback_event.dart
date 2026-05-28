class SourceFallbackEvent {
  const SourceFallbackEvent({
    required this.fromSourceId,
    required this.toSourceId,
    required this.operation,
    required this.reason,
    required this.timestamp,
  });

  final String fromSourceId;
  final String toSourceId;
  final String operation;
  final String reason;
  final DateTime timestamp;
}
