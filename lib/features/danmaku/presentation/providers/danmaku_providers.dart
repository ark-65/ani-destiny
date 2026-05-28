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
  const appId = String.fromEnvironment('DANDANPLAY_APP_ID');
  const appSecret = String.fromEnvironment('DANDANPLAY_APP_SECRET');
  return DioDandanplayDanmakuDataSource(
    dio: ref.watch(dioProvider),
    credentials: const DandanplayCredentials(
      appId: appId,
      appSecret: appSecret,
    ),
  );
});

final danmakuRepositoryProvider = Provider<DanmakuRepository>((ref) {
  return DanmakuRepositoryImpl(
    dandanplayDataSource: ref.watch(dandanplayDanmakuDataSourceProvider),
    mockDataSource: ref.watch(mockDanmakuDataSourceProvider),
  );
});

final danmakuSettingsProvider = StateProvider<DanmakuSettings>((ref) {
  return const DanmakuSettings.defaults();
});

typedef DanmakuRequest = ({
  String animeId,
  String episodeId,
  String animeTitle,
  String episodeTitle,
  int? episodeIndex,
});

final danmakuItemsProvider =
    FutureProvider.autoDispose.family<List<DanmakuItem>, DanmakuRequest>(
  (ref, request) {
    return ref.watch(danmakuRepositoryProvider).getDanmaku(
          animeId: request.animeId,
          episodeId: request.episodeId,
          animeTitle: request.animeTitle,
          episodeTitle: request.episodeTitle,
          episodeIndex: request.episodeIndex,
        );
  },
);
