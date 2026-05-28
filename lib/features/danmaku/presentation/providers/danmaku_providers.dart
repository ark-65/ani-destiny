import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/dandanplay_danmaku_datasource.dart';
import '../../data/datasources/mock_danmaku_datasource.dart';
import '../../data/repositories/danmaku_repository_impl.dart';
import '../../domain/entities/danmaku_item.dart';
import '../../domain/entities/danmaku_settings.dart';
import '../../domain/repositories/danmaku_repository.dart';

final mockDanmakuDataSourceProvider = Provider<MockDanmakuDataSource>((ref) {
  return MockDanmakuDataSource();
});

final dandanplayDanmakuDataSourceProvider =
    Provider<DandanplayDanmakuDataSource>((ref) {
  return DandanplayDanmakuDataSource(ref.watch(dioProvider));
});

final danmakuRepositoryProvider = Provider<DanmakuRepository>((ref) {
  return DanmakuRepositoryImpl(
    mockDataSource: ref.watch(mockDanmakuDataSourceProvider),
  );
});

final danmakuSettingsProvider = StateProvider<DanmakuSettings>((ref) {
  return const DanmakuSettings.defaults();
});

final danmakuItemsProvider = FutureProvider.autoDispose
    .family<List<DanmakuItem>, ({String animeId, String episodeId})>(
  (ref, request) {
    return ref.watch(danmakuRepositoryProvider).getDanmaku(
          animeId: request.animeId,
          episodeId: request.episodeId,
        );
  },
);
