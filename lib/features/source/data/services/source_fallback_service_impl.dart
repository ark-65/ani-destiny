import '../../../../core/constants/app_constants.dart';
import '../../../../core/diagnostics/diagnostic_sanitizer.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/adapters/anime_source_adapter.dart';
import '../../domain/entities/source_diagnostic.dart';
import '../../domain/entities/source_fallback_event.dart';
import '../../domain/entities/source_fallback_result.dart';
import '../../domain/repositories/source_repository.dart';
import '../../domain/services/source_diagnostic_recorder.dart';
import '../../domain/services/source_failure_summary.dart';
import '../../domain/services/source_fallback_service.dart';
import '../../domain/services/source_health_service.dart';
import '../registry/source_registry.dart';

class SourceFallbackServiceImpl implements SourceFallbackService {
  static final RegExp _fallbackAttemptPrefix =
      RegExp(r'^Source attempt \d+:\s*');

  const SourceFallbackServiceImpl({
    required SourceRepository sourceRepository,
    required SourceRegistry registry,
    required SourceHealthService healthService,
    required SourceDiagnosticRecorder diagnosticRecorder,
    required void Function(SourceFallbackEvent event) onFallbackEvent,
  })  : _sourceRepository = sourceRepository,
        _registry = registry,
        _healthService = healthService,
        _diagnosticRecorder = diagnosticRecorder,
        _onFallbackEvent = onFallbackEvent;

  final SourceRepository _sourceRepository;
  final SourceRegistry _registry;
  final SourceHealthService _healthService;
  final SourceDiagnosticRecorder _diagnosticRecorder;
  final void Function(SourceFallbackEvent event) _onFallbackEvent;

  @override
  Future<SourceFallbackResult<T>> run<T>({
    required String operation,
    required Future<T> Function(AnimeSourceAdapter adapter) action,
    String? preferredSourceId,
    bool allowMockFallback = true,
    bool Function(T value)? isFailureValue,
  }) async {
    final selectedSourceId =
        preferredSourceId ?? await _sourceRepository.getCurrentSourceId();
    final adapters = _fallbackAdapters(
      selectedSourceId,
      allowMockFallback: allowMockFallback,
    );
    final failures = <String>[];
    Object? lastError;

    for (final adapter in adapters) {
      try {
        final value = await action(adapter);
        if (isFailureValue?.call(value) ?? false) {
          throw const AppException(
            'Source returned no usable data.',
            code: 'source_empty_result',
          );
        }
        _healthService.recordSuccess(
          sourceId: adapter.id,
          operation: operation,
        );
        if (adapter.id != selectedSourceId) {
          final reason = _buildFallbackReason(failures);
          _recordFallback(
            fromSourceId: selectedSourceId,
            toSourceId: adapter.id,
            operation: operation,
            reason: reason,
          );
        }
        return SourceFallbackResult<T>(
          value: value,
          sourceId: adapter.id,
          usedFallback: adapter.id != selectedSourceId,
          fromSourceId:
              adapter.id == selectedSourceId ? null : selectedSourceId,
          message: adapter.id == selectedSourceId
              ? null
              : _buildFallbackResultMessage(failures),
        );
      } on Object catch (error) {
        lastError = error;
        failures.add(summarizeSourceFailure(error, maxLength: 120));
        _healthService.recordFailure(
          sourceId: adapter.id,
          operation: operation,
          error: error,
        );
        _diagnosticRecorder.record(
          SourceDiagnostic(
            sourceId: adapter.id,
            operation: operation,
            level: SourceDiagnosticLevel.warning,
            message: '',
            exceptionType: error.runtimeType.toString(),
            timestamp: DateTime.now(),
            reason: summarizeSourceFailure(error, maxLength: 120),
          ),
        );
      }
    }

    final reason = _buildFallbackReason(failures);
    throw AppException(
      failures.isEmpty
          ? 'No source is currently available. Try another source or retry later.'
          : 'No source is currently available. Try another source or retry later. '
              'Fallback attempts: $reason',
      code: 'source_fallback_exhausted',
      cause: lastError,
    );
  }

  List<AnimeSourceAdapter> _fallbackAdapters(
    String selectedSourceId, {
    required bool allowMockFallback,
  }) {
    final ids = <String>[
      selectedSourceId,
      if (selectedSourceId != AppConstants.defaultSourceId)
        AppConstants.defaultSourceId,
      if (allowMockFallback && selectedSourceId != 'mock') 'mock',
    ];
    final seen = <String>{};
    return ids
        .where(seen.add)
        .map(_registry.getById)
        .whereType<AnimeSourceAdapter>()
        .where(
          (adapter) =>
              adapter.id != 'remote-proxy' || adapter.id == selectedSourceId,
        )
        .toList(growable: false);
  }

  void _recordFallback({
    required String fromSourceId,
    required String toSourceId,
    required String operation,
    required String reason,
  }) {
    final event = SourceFallbackEvent(
      fromSourceId: fromSourceId,
      toSourceId: toSourceId,
      operation: operation,
      reason: reason,
      timestamp: DateTime.now(),
    );
    _onFallbackEvent(event);
    _diagnosticRecorder.record(
      SourceDiagnostic(
        sourceId: fromSourceId,
        operation: operation,
        level: SourceDiagnosticLevel.warning,
        message: '',
        timestamp: event.timestamp,
        fromSourceId: fromSourceId,
        toSourceId: toSourceId,
        usedFallback: true,
        reason: reason,
      ),
    );
  }

  String _buildFallbackReason(List<String> failures) {
    if (failures.isEmpty) return 'No additional fallback context.';
    return failures
        .map((reason) => reason.replaceFirst(_fallbackAttemptPrefix, ''))
        .join(' · ');
  }

  String _buildFallbackResultMessage(List<String> failures) {
    final reason = sanitizeSourceFallbackNoticeReason(_buildFallbackReason(failures));
    return reason == null || reason.isEmpty
        ? 'Selected source is temporarily unavailable. AniDestiny is showing another source instead.'
        : 'Selected source is temporarily unavailable. AniDestiny is showing another source instead. '
            '$reason';
  }
}
