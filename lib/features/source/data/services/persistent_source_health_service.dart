import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/source_health.dart';
import '../../domain/services/source_health_service.dart';

class PersistentSourceHealthService implements SourceHealthService {
  PersistentSourceHealthService({
    required SharedPreferences preferences,
    Iterable<String> sourceIds = const [],
  })  : _preferences = preferences,
        _sourceIds = sourceIds.toSet() {
    for (final sourceId in _sourceIds) {
      _healthBySource[sourceId] = _read(sourceId);
    }
  }

  static const _prefix = 'source_health';
  static const _failureCount = 'failure_count';
  static const _lastFailureAt = 'last_failure_at';
  static const _lastSuccessAt = 'last_success_at';
  static const _lastErrorMessage = 'last_error_message';

  final SharedPreferences _preferences;
  final Set<String> _sourceIds;
  final Map<String, SourceHealth> _healthBySource = {};

  @override
  SourceHealth getHealth(String sourceId) {
    return _healthBySource[sourceId] ?? _read(sourceId);
  }

  @override
  List<SourceHealth> getAllHealth() {
    final ids = {..._sourceIds, ..._healthBySource.keys}.toList()..sort();
    return ids.map(getHealth).toList(growable: false);
  }

  @override
  void recordSuccess({
    required String sourceId,
    required String operation,
  }) {
    final next = getHealth(sourceId).copyWith(
      status: SourceHealthStatus.healthy,
      failureCount: 0,
      lastSuccessAt: DateTime.now(),
      clearLastErrorMessage: true,
    );
    _write(next);
  }

  @override
  void recordFailure({
    required String sourceId,
    required String operation,
    required Object error,
  }) {
    final current = getHealth(sourceId);
    final failureCount = current.failureCount + 1;
    final next = current.copyWith(
      status: sourceHealthStatusForFailureCount(failureCount),
      failureCount: failureCount,
      lastFailureAt: DateTime.now(),
      lastErrorMessage: _summarize(error),
    );
    _write(next);
  }

  @override
  bool shouldFallback(String sourceId) {
    return getHealth(sourceId).status == SourceHealthStatus.unavailable;
  }

  @override
  void reset(String sourceId) {
    _write(SourceHealth.initial(sourceId));
  }

  void save(SourceHealth health) {
    _write(health);
  }

  SourceHealth _read(String sourceId) {
    final failureCount =
        _preferences.getInt(_key(sourceId, _failureCount)) ?? 0;
    final health = SourceHealth(
      sourceId: sourceId,
      status: sourceHealthStatusForFailureCount(failureCount),
      failureCount: failureCount,
      lastFailureAt: _readDate(sourceId, _lastFailureAt),
      lastSuccessAt: _readDate(sourceId, _lastSuccessAt),
      lastErrorMessage: _preferences.getString(
        _key(sourceId, _lastErrorMessage),
      ),
    );
    _healthBySource[sourceId] = health;
    return health;
  }

  DateTime? _readDate(String sourceId, String field) {
    final value = _preferences.getString(_key(sourceId, field));
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  void _write(SourceHealth health) {
    _sourceIds.add(health.sourceId);
    _healthBySource[health.sourceId] = health;
    _preferences.setInt(
      _key(health.sourceId, _failureCount),
      health.failureCount,
    );
    _setDate(health.sourceId, _lastFailureAt, health.lastFailureAt);
    _setDate(health.sourceId, _lastSuccessAt, health.lastSuccessAt);
    final lastErrorMessage = health.lastErrorMessage;
    if (lastErrorMessage == null || lastErrorMessage.isEmpty) {
      _preferences.remove(_key(health.sourceId, _lastErrorMessage));
    } else {
      _preferences.setString(
        _key(health.sourceId, _lastErrorMessage),
        lastErrorMessage,
      );
    }
  }

  void _setDate(String sourceId, String field, DateTime? value) {
    final key = _key(sourceId, field);
    if (value == null) {
      _preferences.remove(key);
      return;
    }
    _preferences.setString(key, value.toIso8601String());
  }

  String _key(String sourceId, String field) {
    return '$_prefix.$sourceId.$field';
  }

  String _summarize(Object error) {
    final text = error
        .toString()
        .replaceAll(RegExp(r'(https?://[^\s?]+)\?[^\s]+'), r'$1?[hidden]')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= 140) return text;
    return '${text.substring(0, 137)}...';
  }
}
