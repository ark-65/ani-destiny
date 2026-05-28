import '../entities/source_health.dart';

abstract class SourceHealthService {
  SourceHealth getHealth(String sourceId);

  List<SourceHealth> getAllHealth();

  void recordSuccess({
    required String sourceId,
    required String operation,
  });

  void recordFailure({
    required String sourceId,
    required String operation,
    required Object error,
  });

  bool shouldFallback(String sourceId);

  void reset(String sourceId);
}
