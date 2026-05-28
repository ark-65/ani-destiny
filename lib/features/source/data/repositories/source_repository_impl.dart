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
  })  : _registry = registry,
        _preferences = preferences;

  static const _currentSourceKey = 'current_source_id';

  final SourceRegistry _registry;
  final Future<SharedPreferences> Function() _preferences;

  @override
  List<AnimeSource> getSources() {
    return _registry.adapters
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
    final preferences = await _preferences();
    await preferences.setString(_currentSourceKey, sourceId);
  }

  @override
  Future<AnimeSourceAdapter> getCurrentAdapter() async {
    final sourceId = await getCurrentSourceId();
    return _registry.getById(sourceId) ?? _registry.defaultAdapter;
  }
}
