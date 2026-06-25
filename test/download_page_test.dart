import 'dart:async';

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

    await _pumpDownloadPage(tester, repository);

    final clearButton =
        find.byKey(const ValueKey('downloads-clear-ended-tasks'));
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

    await _pumpDownloadPage(tester, repository);

    expect(find.text('Clear ended tasks'), findsNothing);
    expect(repository.deletedTaskIds, isEmpty);
  });

  testWidgets('direct downloads use honest stop and retry wording', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('downloading', DownloadStatus.downloading),
      _task('paused', DownloadStatus.paused),
    ]);

    await _pumpDownloadPage(tester, repository);

    expect(find.byTooltip('Stop for now'), findsOneWidget);
    expect(
      find.text(
        'Stopping this download keeps the task, but the next retry may restart from the beginning.',
      ),
      findsOneWidget,
    );

    expect(find.byTooltip('Retry'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-task-retry-paused')),
      findsOneWidget,
    );
    expect(find.text('Stopped'), findsOneWidget);
    expect(
      find.text(
        'This download is stopped for now. Retrying may restart it from the beginning.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Pause'), findsNothing);
  });

  testWidgets(
    'clear ended tasks continues after one deletion fails and shows summary',
    (tester) async {
      final repository = _FakeDownloadRepository(
        [
          _task('pending', DownloadStatus.pending),
          _task('completed', DownloadStatus.completed),
          _task('failed', DownloadStatus.failed),
          _task('canceled', DownloadStatus.canceled),
          _task('unsupported', DownloadStatus.unsupported),
        ],
        failingDeleteTaskIds: {'failed'},
      );

      await _pumpDownloadPage(tester, repository);

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(
        repository.deleteAttempts,
        ['completed', 'failed', 'canceled', 'unsupported'],
      );
      expect(
        repository.deletedTaskIds,
        ['completed', 'canceled', 'unsupported'],
      );
      expect(find.text('Cleared 3 ended tasks, 1 failed.'), findsOneWidget);
    },
  );

  testWidgets(
    'clear ended tasks stays disabled while cleanup is still running',
    (tester) async {
      final deleteBlocker = Completer<void>();
      final repository = _FakeDownloadRepository(
        [
          _task('completed', DownloadStatus.completed),
          _task('failed', DownloadStatus.failed),
        ],
        deleteBlocker: deleteBlocker.future,
      );

      await _pumpDownloadPage(tester, repository);

      final clearButton =
          find.byKey(const ValueKey('downloads-clear-ended-tasks'));
      await tester.tap(clearButton);
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(
        find.byKey(const ValueKey('download-task-busy-completed')),
        findsOneWidget,
      );
      expect(
        tester.widget<OutlinedButton>(clearButton).onPressed,
        isNull,
      );

      await tester.tap(clearButton, warnIfMissed: false);
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);

      deleteBlocker.complete();
      await tester.pump();
      await tester.pump();

      expect(repository.deletedTaskIds, ['completed', 'failed']);
      expect(
        find.byKey(const ValueKey('download-task-busy-completed')),
        findsNothing,
      );
    },
  );

  testWidgets('remove action failures surface a snackbar', (tester) async {
    final repository = _FakeDownloadRepository(
      [
        _task('completed', DownloadStatus.completed),
      ],
      failingDeleteTaskIds: {'completed'},
    );

    await _pumpDownloadPage(tester, repository);

    await tester
        .tap(find.byKey(const ValueKey('download-task-remove-completed')));
    await tester.pump();

    expect(repository.deleteAttempts, ['completed']);
    expect(find.text('Bad state: delete failed for completed'), findsOneWidget);
  });

  testWidgets('remove action stays disabled while deletion is still running', (
    tester,
  ) async {
    final deleteBlocker = Completer<void>();
    final repository = _FakeDownloadRepository(
      [
        _task('completed', DownloadStatus.completed),
      ],
      deleteBlocker: deleteBlocker.future,
    );

    await _pumpDownloadPage(tester, repository);

    final removeButton =
        find.byKey(const ValueKey('download-task-remove-completed'));
    await tester.tap(removeButton);
    await tester.pump();

    expect(repository.deleteAttempts, ['completed']);
    expect(
      find.byKey(const ValueKey('download-task-busy-completed')),
      findsOneWidget,
    );
    expect(tester.widget<IconButton>(removeButton).onPressed, isNull);

    await tester.tap(removeButton, warnIfMissed: false);
    await tester.pump();

    expect(repository.deleteAttempts, ['completed']);

    deleteBlocker.complete();
    await tester.pump();
    await tester.pump();

    expect(repository.deletedTaskIds, ['completed']);
    expect(
      find.byKey(const ValueKey('download-task-busy-completed')),
      findsNothing,
    );
  });

  testWidgets(
    'clear ended tasks skips entries already being removed individually',
    (tester) async {
      final deleteBlockers = {
        'completed': Completer<void>(),
      };
      final repository = _FakeDownloadRepository(
        [
          _task('completed', DownloadStatus.completed),
          _task('failed', DownloadStatus.failed),
        ],
        deleteBlockers: {
          for (final entry in deleteBlockers.entries)
            entry.key: entry.value.future,
        },
      );

      await _pumpDownloadPage(tester, repository);

      final removeButton =
          find.byKey(const ValueKey('download-task-remove-completed'));
      final clearButton =
          find.byKey(const ValueKey('downloads-clear-ended-tasks'));

      await tester.tap(removeButton);
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(tester.widget<OutlinedButton>(clearButton).onPressed, isNull);

      await tester.tap(clearButton, warnIfMissed: false);
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);

      deleteBlockers['completed']!.complete();
      await tester.pump();
      await tester.pump();
      expect(repository.deletedTaskIds, ['completed']);
    },
  );

  testWidgets('mock task action stays hidden outside debug mode', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('completed', DownloadStatus.completed),
    ]);

    await _pumpDownloadPage(
      tester,
      repository,
      showDebugMockAction: false,
    );

    expect(find.text('Mock'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}

Future<void> _pumpDownloadPage(
  WidgetTester tester,
  DownloadRepository repository, {
  bool showDebugMockAction = true,
}) async {
  await tester.pumpWidget(
    _TestApp(
      repository: repository,
      showDebugMockAction: showDebugMockAction,
    ),
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.repository,
    required this.showDebugMockAction,
  });

  final DownloadRepository repository;
  final bool showDebugMockAction;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        downloadRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: DownloadPage(showDebugMockAction: showDebugMockAction),
        ),
      ),
    );
  }
}

class _FakeDownloadRepository implements DownloadRepository {
  _FakeDownloadRepository(
    this._tasks, {
    this.failingDeleteTaskIds = const {},
    this.deleteBlocker,
    this.deleteBlockers = const {},
  });

  final List<DownloadTask> _tasks;
  final Set<String> failingDeleteTaskIds;
  final Future<void>? deleteBlocker;
  final Map<String, Future<void>> deleteBlockers;
  final List<String> deleteAttempts = [];
  final List<String> deletedTaskIds = [];

  @override
  Future<void> deleteTask(String taskId) async {
    deleteAttempts.add(taskId);
    if (deleteBlocker != null) {
      await deleteBlocker;
    }
    final perTaskBlocker = deleteBlockers[taskId];
    if (perTaskBlocker != null) {
      await perTaskBlocker;
    }
    if (failingDeleteTaskIds.contains(taskId)) {
      throw StateError('delete failed for $taskId');
    }
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
