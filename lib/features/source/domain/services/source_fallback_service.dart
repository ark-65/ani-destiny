import '../adapters/anime_source_adapter.dart';
import '../entities/source_fallback_result.dart';

abstract class SourceFallbackService {
  Future<SourceFallbackResult<T>> run<T>({
    required String operation,
    required Future<T> Function(AnimeSourceAdapter adapter) action,
    String? preferredSourceId,
    bool allowMockFallback = true,
    bool Function(T value)? isFailureValue,
  });
}
