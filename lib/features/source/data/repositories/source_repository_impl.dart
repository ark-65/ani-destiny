import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/adapters/anime_source_adapter.dart';
import '../../domain/entities/anime_source.dart';
import '../../domain/repositories/source_repository.dart';
import '../registry/source_registry.dart';

class SourceRepositoryImpl implements SourceRepository {
  SourceRepositoryImpl({
    required SourceRegistry registry,
    required Future<SharedPreferences> Function() preferences,
    bool allowDebugSources = kDebugMode,
  })  : _registry = registry,
        _preferences = preferences,
        _allowDebugSources = allowDebugSources;

  static const _currentSourceKey = 'current_source_id';
  static const _sourceDefaultVersionKey = 'source_default_version';
  static const _currentSourceDefaultVersion = 3;
  static const _legacyMockDefaultSourceId = 'mock';

  final SourceRegistry _registry;
  final Future<SharedPreferences> Function() _preferences;
  final bool _allowDebugSources;

  @override
  List<AnimeSource> getSources() {
    return _registry.adapters
        .where((adapter) => _isUserSelectableSource(adapter.id))
        .map(
          (adapter) => AnimeSource(
            id: adapter.id,
            name: adapter.name,
            description: adapter.description,
            enabled: adapter.id == AppConstants.defaultSourceId,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> getCurrentSourceId() async {
    final preferences = await _preferences();
    final stored = preferences.getString(_currentSourceKey);
    final defaultVersion = preferences.getInt(_sourceDefaultVersionKey) ?? 1;
    if (stored != null &&
        !_isUserSelectableSource(stored) &&
        _registry.getById(AppConstants.defaultSourceId) != null) {
      return _migrateCurrentSourceToDefault(preferences);
    }
    if (defaultVersion < _currentSourceDefaultVersion) {
      await preferences.setInt(
        _sourceDefaultVersionKey,
        _currentSourceDefaultVersion,
      );
    }
    if (stored != null && _registry.getById(stored) != null) {
      return stored;
    }
    return _registry.defaultAdapter.id;
  }

  @override
  Future<void> setCurrentSourceId(String sourceId) async {
    final adapter = _registry.getById(sourceId);
    if (adapter == null) {
      throw ArgumentError.value(sourceId, 'sourceId', 'Unknown source id');
    }
    if (!_isUserSelectableSource(sourceId)) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'Source is not user-selectable',
      );
    }
    final preferences = await _preferences();
    await preferences.setString(_currentSourceKey, sourceId);
    await preferences.setInt(
      _sourceDefaultVersionKey,
      _currentSourceDefaultVersion,
    );
  }

  @override
  Future<AnimeSourceAdapter> getCurrentAdapter() async {
    final sourceId = await getCurrentSourceId();
    return _registry.getById(sourceId) ?? _registry.defaultAdapter;
  }

  bool _isUserSelectableSource(String sourceId) {
    return _allowDebugSources || sourceId != _legacyMockDefaultSourceId;
  }

  Future<String> _migrateCurrentSourceToDefault(
    SharedPreferences preferences,
  ) async {
    await preferences.setString(
      _currentSourceKey,
      AppConstants.defaultSourceId,
    );
    await preferences.setInt(
      _sourceDefaultVersionKey,
      _currentSourceDefaultVersion,
    );
    return AppConstants.defaultSourceId;
  }
}
