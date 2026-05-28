import '../entities/source_diagnostic.dart';

abstract class SourceDiagnosticRecorder {
  void record(SourceDiagnostic diagnostic);

  List<SourceDiagnostic> latest({String? sourceId});

  void clear({String? sourceId});
}

class NoopSourceDiagnosticRecorder implements SourceDiagnosticRecorder {
  const NoopSourceDiagnosticRecorder();

  @override
  void clear({String? sourceId}) {}

  @override
  List<SourceDiagnostic> latest({String? sourceId}) => const [];

  @override
  void record(SourceDiagnostic diagnostic) {}
}
