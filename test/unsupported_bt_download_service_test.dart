import 'package:ani_destiny/core/error/app_exception.dart';
import 'package:ani_destiny/features/download/data/services/unsupported_bt_download_service.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = UnsupportedBtDownloadService();

  test(
      'createTask reports unsupported BT downloads without raw placeholder text',
      () async {
    final call = service.createTask(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      source: const DownloadSource(
        url: 'magnet:?xt=urn:btih:abc123',
        kind: DownloadKind.bt,
      ),
      title: 'Anime 1',
      episodeTitle: 'Episode 1',
    );

    await expectLater(
      call,
      throwsA(
        isA<AppException>()
            .having(
              (error) => error.message,
              'message',
              'AniDestiny cannot save BT or magnet downloads offline yet.',
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('not implemented')),
            )
            .having(
              (error) => error.toString(),
              'string form',
              isNot(contains('UnimplementedError')),
            ),
      ),
    );
  });

  test('watchProgress stays quiet for unsupported BT downloads', () {
    expect(service.watchProgress('task-1'), emitsDone);
  });
}
