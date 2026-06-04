import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/download/domain/repositories/download_repository.dart';
import 'package:ani_destiny/features/download/presentation/pages/download_page.dart';
import 'package:ani_destiny/features/download/presentation/providers/download_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clear ended tasks removes removable download entries', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('pending', DownloadStatus.pending),
      _task('completed', DownloadStatus.completed),
      _task('failed', DownloadStatus.failed),
      _task('canceled', DownloadStatus.canceled),
      _task('unsupported', DownloadStatus.unsupported),
    ]);

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pump();

    final clearButton = find.widgetWithText(
      OutlinedButton,
      'Clear ended tasks',
    );
    expect(clearButton, findsOneWidget);

    await tester.tap(clearButton);
    await tester.pump();

    expect(
      repository.deletedTaskIds,
      ['completed', 'failed', 'canceled', 'unsupported'],
    );
  });

  testWidgets('clear ended tasks stays hidden when all tasks are active', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('pending', DownloadStatus.pending),
      _task('downloading', DownloadStatus.downloading),
      _task('paused', DownloadStatus.paused),
    ]);

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pump();

    expect(find.text('Clear ended tasks'), findsNothing);
    expect(repository.deletedTaskIds, isEmpty);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository});

  final DownloadRepository repository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        downloadRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(body: DownloadPage()),
      ),
    );
  }
}

class _FakeDownloadRepository implements DownloadRepository {
  _FakeDownloadRepository(this._tasks);

  final List<DownloadTask> _tasks;
  final List<String> deletedTaskIds = [];

  @override
  Future<void> deleteTask(String taskId) async {
    deletedTaskIds.add(taskId);
  }

  @override
  Future<DownloadTask?> getTask(String taskId) async {
    for (final task in _tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  @override
  Future<void> upsertTask(DownloadTask task) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<DownloadTask>> watchTasks() {
    return Stream.value(List.unmodifiable(_tasks));
  }
}

DownloadTask _task(String id, DownloadStatus status) {
  final now = DateTime(2026, 6, 5, 1, 0);
  return DownloadTask(
    id: id,
    animeId: 'anime-1',
    episodeId: 'episode-1',
    sourceId: 'sakura',
    title: 'AniDestiny',
    episodeTitle: 'Episode 1',
    url: 'https://cdn.example.test/video.mp4',
    kind: DownloadKind.directFile,
    status: status,
    failureReason: status == DownloadStatus.failed
        ? DownloadFailureReason.networkError
        : DownloadFailureReason.none,
    progress: 0.5,
    downloadedBytes: 512,
    totalBytes: 1024,
    createdAt: now,
    updatedAt: now,
  );
}
