import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/danmaku_item.dart';

class DandanplayDanmakuDataSource {
  const DandanplayDanmakuDataSource(this._dio);

  final Dio _dio;

  Future<List<DanmakuItem>> getDanmaku({
    required String animeTitle,
    required String episodeTitle,
  }) async {
    // TODO(anidestiny): Implement Dandanplay episode search, request signing, and
    // comment mapping after API credentials/configuration are added.
    _dio.options.baseUrl = 'https://api.dandanplay.net';
    await Future<void>.delayed(const Duration(milliseconds: 80));
    throw const AppException(
      'Dandanplay danmaku is not implemented yet.',
      code: 'dandanplay_not_implemented',
    );
  }
}
