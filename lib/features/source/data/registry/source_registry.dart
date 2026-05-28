import '../../../../core/constants/app_constants.dart';
import '../../domain/adapters/anime_source_adapter.dart';

class SourceRegistry {
  SourceRegistry({
    required List<AnimeSourceAdapter> adapters,
  }) : _adapters = List.unmodifiable(adapters);

  final List<AnimeSourceAdapter> _adapters;

  List<AnimeSourceAdapter> get adapters => _adapters;

  AnimeSourceAdapter? getById(String id) {
    for (final adapter in _adapters) {
      if (adapter.id == id) return adapter;
    }
    return null;
  }

  AnimeSourceAdapter get defaultAdapter => _adapters.firstWhere(
        (adapter) => adapter.id == AppConstants.defaultSourceId,
        orElse: () => _adapters.first,
      );
}
