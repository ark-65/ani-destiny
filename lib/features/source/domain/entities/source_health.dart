enum SourceHealthStatus {
  healthy,
  degraded,
  unavailable,
}

class SourceHealth {
  const SourceHealth({
    required this.sourceId,
    required this.status,
    required this.failureCount,
    this.lastFailureAt,
    this.lastSuccessAt,
    this.lastErrorMessage,
  });

  const SourceHealth.initial(this.sourceId)
      : status = SourceHealthStatus.healthy,
        failureCount = 0,
        lastFailureAt = null,
        lastSuccessAt = null,
        lastErrorMessage = null;

  final String sourceId;
  final SourceHealthStatus status;
  final int failureCount;
  final DateTime? lastFailureAt;
  final DateTime? lastSuccessAt;
  final String? lastErrorMessage;

  SourceHealth copyWith({
    SourceHealthStatus? status,
    int? failureCount,
    DateTime? lastFailureAt,
    DateTime? lastSuccessAt,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
  }) {
    return SourceHealth(
      sourceId: sourceId,
      status: status ?? this.status,
      failureCount: failureCount ?? this.failureCount,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastErrorMessage: clearLastErrorMessage
          ? null
          : lastErrorMessage ?? this.lastErrorMessage,
    );
  }
}

SourceHealthStatus sourceHealthStatusForFailureCount(int failureCount) {
  if (failureCount >= 3) return SourceHealthStatus.unavailable;
  if (failureCount >= 2) return SourceHealthStatus.degraded;
  return SourceHealthStatus.healthy;
}
