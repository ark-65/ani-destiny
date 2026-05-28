import '../../domain/entities/danmaku_item.dart';
import '../../domain/repositories/danmaku_repository.dart';
import '../datasources/mock_danmaku_datasource.dart';

class DanmakuRepositoryImpl implements DanmakuRepository {
  const DanmakuRepositoryImpl({
    required MockDanmakuDataSource mockDataSource,
  }) : _mockDataSource = mockDataSource;

  final MockDanmakuDataSource _mockDataSource;

  @override
  Future<List<DanmakuItem>> getDanmaku({
    required String animeId,
    required String episodeId,
  }) {
    return _mockDataSource.getDanmaku(
      animeId: animeId,
      episodeId: episodeId,
    );
  }
}
