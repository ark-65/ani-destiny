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
  });
}

class _CapturingDownloadService implements DownloadService {
  DownloadSource? lastSource;

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
