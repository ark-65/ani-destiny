import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeDownloadTask sanitizes sensitive failure messages', () {
    final task = DownloadTask(
      id: 'task-1',
      animeId: 'anime-1',
      episodeId: 'ep-1',
      sourceId: 'src-1',
      title: 'Episode',
      episodeTitle: 'Episode 1',
      url: 'https://example.com',
      kind: DownloadKind.hls,
      status: DownloadStatus.failed,
      failureReason: DownloadFailureReason.networkError,
      failureMessage: 'Request failed for /tmp/ani-destiny/secret/session.txt',
      progress: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final normalized = normalizeDownloadTask(task);

    expect(
      normalized.failureMessage,
      isNot(contains('/tmp/ani-destiny/secret/session.txt')),
    );
    expect(normalized.failureMessage, contains('[path:[hidden]]'));
  });
}
