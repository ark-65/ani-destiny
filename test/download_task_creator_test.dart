import 'package:ani_destiny/features/download/data/services/download_task_creator.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_progress.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/services/download_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create returns direct-file result for downloadable urls', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    final result = await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-1',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/video.mp4',
      title: 'Anime 1',
      episodeTitle: 'Episode 1',
    );

    expect(result.taskId, 'task-1');
    expect(result.kind, DownloadKind.directFile);
    expect(result.isSupported, isTrue);
    expect(service.lastSource?.kind, DownloadKind.directFile);
    expect(service.lastEpisodeTitle, 'Episode 1');
  });

  test('create returns unsupported result for HLS urls', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    final result = await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-2',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/playlist.m3u8',
      title: 'Anime 1',
      episodeTitle: 'Episode 2',
    );

    expect(result.taskId, 'task-1');
    expect(result.kind, DownloadKind.hls);
    expect(result.isSupported, isFalse);
    expect(service.lastSource?.kind, DownloadKind.hls);
    expect(service.lastEpisodeTitle, 'Episode 2');
  });

  test('create appends the selected line title for new download entries', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-3',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/video.mp4',
      title: 'Anime 1',
      episodeTitle: 'Episode 3',
      lineTitle: 'Line 2',
    );

    expect(service.lastEpisodeTitle, 'Episode 3 - Line 2');
  });

  test('create avoids repeating the line title when it is already present', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-4',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/video.mp4',
      title: 'Anime 1',
      episodeTitle: 'Episode 4 - Line 3',
      lineTitle: 'Line 3',
    );

    expect(service.lastEpisodeTitle, 'Episode 4 - Line 3');
  });

  test('create avoids repeating the line title with casing differences', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-5',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/video.mp4',
      title: 'Anime 1',
      episodeTitle: 'Episode 5 - line 3',
      lineTitle: 'LINE 3',
    );

    expect(service.lastEpisodeTitle, 'Episode 5 - line 3');
  });

  test(
    'create avoids repeating line title only for boundary matches',
    () async {
      final service = _CapturingDownloadService();
      final creator = DownloadTaskCreator(service);

      await creator.create(
        animeId: 'anime-1',
        episodeId: 'episode-6',
        sourceId: 'sakura',
        url: 'https://cdn.example.test/video.mp4',
        title: 'Anime 1',
        episodeTitle: 'Episode 6 - Line 3A',
        lineTitle: 'Line 3',
      );

      expect(service.lastEpisodeTitle, 'Episode 6 - Line 3A - Line 3');
    },
  );

  test('create avoids repeating the line title with extra spaces', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-6b',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/video.mp4',
      title: 'Anime 1',
      episodeTitle: 'Episode 6 - Line 3',
      lineTitle: ' line   3',
    );

    expect(service.lastEpisodeTitle, 'Episode 6 - Line 3');
  });

  test('create avoids repeating line title with full-width punctuation', () async {
    final service = _CapturingDownloadService();
    final creator = DownloadTaskCreator(service);

    await creator.create(
      animeId: 'anime-1',
      episodeId: 'episode-7',
      sourceId: 'sakura',
      url: 'https://cdn.example.test/video.mp4',
      title: 'Anime 1',
      episodeTitle: 'Episode 7（Line 3）',
      lineTitle: 'Line 3',
    );

    expect(service.lastEpisodeTitle, 'Episode 7（Line 3）');
  });

  test(
    'create avoids repeating the line title with full-width minus separator',
    () async {
      final service = _CapturingDownloadService();
      final creator = DownloadTaskCreator(service);

      await creator.create(
        animeId: 'anime-1',
        episodeId: 'episode-8',
        sourceId: 'sakura',
        url: 'https://cdn.example.test/video.mp4',
        title: 'Anime 1',
        episodeTitle: 'Episode 8－Line 3',
        lineTitle: 'Line 3',
      );

      expect(service.lastEpisodeTitle, 'Episode 8－Line 3');
    },
  );
}

class _CapturingDownloadService implements DownloadService {
  DownloadSource? lastSource;
  String? lastEpisodeTitle;

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<String> createTask({
    required String animeId,
    required String episodeId,
    required String sourceId,
    required DownloadSource source,
    required String title,
    required String episodeTitle,
  }) async {
    lastSource = source;
    lastEpisodeTitle = episodeTitle;
    return 'task-1';
  }

  @override
  Future<void> pause(String taskId) async {}

  @override
  Future<void> removeEndedTask(String taskId) async {}

  @override
  Future<void> start(String taskId) async {}

  @override
  Stream<DownloadProgress> watchProgress(String taskId) => const Stream.empty();
}
