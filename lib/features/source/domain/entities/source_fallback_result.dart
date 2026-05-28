class SourceFallbackResult<T> {
  const SourceFallbackResult({
    required this.value,
    required this.sourceId,
    required this.usedFallback,
    this.fromSourceId,
    this.message,
  });

  final T value;
  final String sourceId;
  final bool usedFallback;
  final String? fromSourceId;
  final String? message;

  SourceFallbackResult<R> mapValue<R>(R Function(T value) mapper) {
    return SourceFallbackResult<R>(
      value: mapper(value),
      sourceId: sourceId,
      usedFallback: usedFallback,
      fromSourceId: fromSourceId,
      message: message,
    );
  }
}
