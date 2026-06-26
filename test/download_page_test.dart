import 'dart:async';

import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_progress.dart';
import 'package:ani_destiny/features/download/domain/entities/download_source.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/download/domain/repositories/download_repository.dart';
import 'package:ani_destiny/features/download/domain/services/download_service.dart';
import 'package:ani_destiny/features/download/presentation/download_task_cleanup_state.dart';
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

    expect(find.text('Clear ended tasks from list'), findsNothing);
    expect(repository.deletedTaskIds, isEmpty);
  });

  testWidgets('clear ended tasks explains completed files stay on device', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('completed', DownloadStatus.completed),
      _task('failed', DownloadStatus.failed),
    ]);

    await _pumpDownloadPage(tester, repository);

    expect(
      find.text(
        'This only clears ended tasks from the list. Completed files stay on your device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'clear ended tasks note stays hidden without completed downloads',
    (tester) async {
      final repository = _FakeDownloadRepository([
        _task('failed', DownloadStatus.failed),
        _task('canceled', DownloadStatus.canceled),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.text(
          'This only clears ended tasks from the list. Completed files stay on your device.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'clear ended tasks keeps discarded leftovers visible for manual cleanup',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.text(
          'Discarded tasks that still show a leftover file path stay in the list until that partial file is gone. After you delete it, return here and tap Check again on that task.',
        ),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(repository.deletedTaskIds, ['completed']);
    },
  );

  testWidgets(
    'clear ended tasks action stays hidden when only retained discarded leftovers remain',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );
      expect(
        find.text(
          'Discarded tasks that still show a leftover file path stay in the list until that partial file is gone. After you delete it, return here and tap Check again on that task.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'manual cleanup tasks become clearable again after users check the leftover file status',
    (tester) async {
      const stalePath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({stalePath});
      final repository = _FakeDownloadRepository([
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: stalePath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsNothing,
      );

      _stubCleanupPathExists(const {});
      await tester.tap(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Discarded tasks that still show a leftover file path stay in the list until that partial file is gone.',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsOneWidget,
      );
      expect(find.text('Check again'), findsNothing);

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(repository.deletedTaskIds, ['canceled']);
    },
  );

  testWidgets('direct downloads use honest stop and retry wording', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('downloading', DownloadStatus.downloading),
      _task('paused', DownloadStatus.paused),
    ]);

    await _pumpDownloadPage(tester, repository);

    expect(find.byTooltip('Stop for now'), findsOneWidget);
    expect(find.byTooltip('Discard download'), findsNWidgets(2));
    expect(
      find.text(
        'Stopping this download keeps the task, but the next retry may restart from the beginning. Discarding it clears any partial file.',
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
        'This download is stopped for now. Retrying may restart it from the beginning. Discarding it clears any partial file.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Pause'), findsNothing);
  });

  testWidgets('completed downloads explain that list cleanup keeps the file', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('completed', DownloadStatus.completed),
    ]);

    await _pumpDownloadPage(tester, repository);

    expect(find.byTooltip('Remove from list'), findsOneWidget);
    expect(
      find.text(
        'Removing this task only clears it from the list. The downloaded file stays on your device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'canceled downloads explain when a leftover partial file needs manual cleanup',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.text(
          'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then return here and tap Check again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Local path: $partialPath'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    },
  );

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
      expect(
        find.text('Cleared 3 ended tasks from the list, 1 failed.'),
        findsOneWidget,
      );
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

  testWidgets(
    'retained discarded leftovers do not expose a single-item remove action',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);
      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsNothing,
      );
      expect(repository.deleteAttempts, isEmpty);
      expect(
        find.text(
          'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then return here and tap Check again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Check again'), findsOneWidget);
    },
  );

  testWidgets(
    'manual cleanup tasks recheck leftover files when the app resumes',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
        findsOneWidget,
      );

      _stubCleanupPathExists(const {});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
        findsNothing,
      );
    },
  );

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
  DownloadService? downloadService,
}) async {
  await tester.pumpWidget(
    _TestApp(
      repository: repository,
      showDebugMockAction: showDebugMockAction,
      downloadService: downloadService,
    ),
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.repository,
    required this.showDebugMockAction,
    this.downloadService,
  });

  final DownloadRepository repository;
  final bool showDebugMockAction;
  final DownloadService? downloadService;

  @override
  Widget build(BuildContext context) {
    final effectiveDownloadService =
        downloadService ?? _FakeDownloadService(repository);
    return ProviderScope(
      overrides: [
        downloadRepositoryProvider.overrideWithValue(repository),
        httpDownloadServiceProvider.overrideWithValue(effectiveDownloadService),
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

class _FakeDownloadService implements DownloadService {
  _FakeDownloadService(this.repository);

  final DownloadRepository repository;

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
    return 'mock-task';
  }

  @override
  Future<void> pause(String taskId) async {}

  @override
  Future<void> removeEndedTask(String taskId) async {
    await repository.deleteTask(taskId);
  }

  @override
  Future<void> start(String taskId) async {}

  @override
  Stream<DownloadProgress> watchProgress(String taskId) {
    return const Stream<DownloadProgress>.empty();
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
    localPath: status == DownloadStatus.completed ? '/tmp/video.mp4' : null,
    createdAt: now,
    updatedAt: now,
  );
}

void _stubCleanupPathExists(Set<String> existingPaths) {
  debugSetDownloadCleanupPathExists(existingPaths.contains);
  addTearDown(() {
    debugSetDownloadCleanupPathExists(null);
  });
}
