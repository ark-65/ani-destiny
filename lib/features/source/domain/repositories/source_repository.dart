import '../adapters/anime_source_adapter.dart';
import '../entities/anime_source.dart';

abstract class SourceRepository {
  List<AnimeSource> getSources();

  Future<String> getCurrentSourceId();

  Future<void> setCurrentSourceId(String sourceId);

  Future<AnimeSourceAdapter> getCurrentAdapter();
}
