import '../../domain/entities/source_diagnostic.dart';
import '../../domain/services/source_diagnostic_recorder.dart';

class InMemorySourceDiagnosticRecorder implements SourceDiagnosticRecorder {
  InMemorySourceDiagnosticRecorder({
    this.capacity = 80,
  });

  final int capacity;
  final List<SourceDiagnostic> _items = [];

  @override
  void record(SourceDiagnostic diagnostic) {
    final item = SourceDiagnostic(
      sourceId: diagnostic.sourceId,
      operation: diagnostic.operation,
      level: diagnostic.level,
      message: diagnostic.message,
      url: diagnostic.url,
      statusCode: diagnostic.statusCode,
      exceptionType: diagnostic.exceptionType,
      timestamp: diagnostic.timestamp ?? DateTime.now(),
    );
    _items.add(item);
    if (_items.length > capacity) {
      _items.removeRange(0, _items.length - capacity);
    }
  }

  @override
  List<SourceDiagnostic> latest({String? sourceId}) {
    final values = sourceId == null
        ? _items
        : _items.where((item) => item.sourceId == sourceId);
    return List.unmodifiable(values.toList().reversed);
  }

  @override
  void clear({String? sourceId}) {
    if (sourceId == null) {
      _items.clear();
      return;
    }
    _items.removeWhere((item) => item.sourceId == sourceId);
  }
}
