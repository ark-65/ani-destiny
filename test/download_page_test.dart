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
    expect(find.text('Clear 4 ended tasks from list'), findsOneWidget);

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

    expect(
      find.byKey(const ValueKey('downloads-clear-ended-tasks')),
      findsNothing,
    );
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
          'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. After you delete it, return here and tap Check again on that task.',
        ),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(repository.deletedTaskIds, ['completed']);
      expect(
        find.text(
          'Cleared 1 ended tasks from the list.\nTasks marked Needs cleanup stay in the list until that leftover partial file is gone. After you delete it, return here and tap Check again on that task.',
        ),
        findsOneWidget,
      );
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
          'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. After you delete it, return here and tap Check again on that task.',
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
        find.text(
          'That leftover partial file is gone. You can remove this task from the list now.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clear 1 ended task from list'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone.',
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

  testWidgets(
    'clear ended tasks result points multi-leftover follow-up at the batch recheck action',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB});
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(repository.deletedTaskIds, ['completed']);
      expect(
        find.text(
          'Cleared 1 ended tasks from the list.\nTasks marked Needs cleanup stay in the list until those leftover partial files are gone. After you delete them, use "Check 2 leftover files again" above or tap Check again on each task.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'page-level cleanup recheck refreshes multiple leftover-file tasks together',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB});
      final repository = _FakeDownloadRepository([
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(find.text('Check 2 leftover files again'), findsOneWidget);
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until those leftover partial files are gone. After you delete them, use "Check 2 leftover files again" above or tap Check again on each task.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then use "Check 2 leftover files again" above or tap Check again here.',
        ),
        findsNWidgets(2),
      );
      expect(
        find.byKey(const ValueKey('downloads-recheck-manual-cleanup')),
        findsOneWidget,
      );

      _stubCleanupPathExists({partialPathB});
      await tester.tap(
        find.byKey(const ValueKey('downloads-recheck-manual-cleanup')),
      );
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. 1 still needs cleanup.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('downloads-recheck-manual-cleanup')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled-b')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'manual cleanup recheck explains when the leftover file is still there',
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

      await tester.tap(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
      );
      await tester.pump();

      expect(
        find.text(
          'That leftover partial file is still on your device. Delete it first, then check again.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'active stop keeps an in-flight stopping message until cleanup settles',
    (tester) async {
      final settlePause = Completer<void>();
      final repository = _FakeDownloadRepository([
        _task('downloading', DownloadStatus.downloading).copyWith(
          localPath: '/tmp/partial-video.mp4',
        ),
      ]);
      final service = _PauseInFlightDownloadService(
        repository,
        settlePause.future,
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester.tap(
        find.byKey(const ValueKey('download-task-pause-downloading')),
      );
      await tester.pump();

      expect(find.text('Stopping...'), findsOneWidget);
      expect(
        find.text(
          'AniDestiny is still stopping this download and clearing its partial file. This task will show Stopped when that cleanup finishes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Stopped'), findsNothing);

      settlePause.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('Stopping...'), findsNothing);
    },
  );

  testWidgets(
    'active discard keeps an in-flight discard message until cleanup settles',
    (tester) async {
      final settleCancel = Completer<void>();
      final repository = _FakeDownloadRepository([
        _task('downloading', DownloadStatus.downloading).copyWith(
          localPath: '/tmp/partial-video.mp4',
        ),
      ]);
      final service = _CancelInFlightDownloadService(
        repository,
        settleCancel.future,
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester.tap(
        find.byKey(const ValueKey('download-task-cancel-downloading')),
      );
      await tester.pump();

      expect(find.text('Discarding...'), findsOneWidget);
      expect(
        find.text(
          'AniDestiny is still discarding this download and clearing its partial file. The final cleanup result will appear here when it finishes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Discarded'), findsNothing);

      settleCancel.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Discarded'), findsOneWidget);
      expect(find.text('Discarding...'), findsNothing);
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
    'manual cleanup guidance uses the localized needs-cleanup status wording',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(
        tester,
        repository,
        locale: const Locale('zh'),
      );

      expect(
        find.text(
          '标成“待清理残留文件”的任务会继续留在列表里，直到这份半截文件已经被手动删掉，或 AniDestiny 成功把它清掉。删完后回到这里点一下“重新检查”。',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('“已取消”任务'), findsNothing);
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

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

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
      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. You can remove that task from the list now.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resume does not show a cleared message while leftover cleanup is still needed',
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

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
        findsOneWidget,
      );
      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. You can remove that task from the list now.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'resume explains how many leftover files were cleared and how many still need cleanup',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB});
      final repository = _FakeDownloadRepository([
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      _stubCleanupPathExists({partialPathB});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. 1 still needs cleanup.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled-b')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'page-level cleanup recheck restores batch clear when all leftovers are gone',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB});
      final repository = _FakeDownloadRepository([
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      _stubCleanupPathExists(const {});
      await tester.tap(
        find.byKey(const ValueKey('downloads-recheck-manual-cleanup')),
      );
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that all 2 leftover partial files are gone. You can remove those tasks from the list now.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clear 2 ended tasks from list'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsOneWidget,
      );
      expect(find.text('Check 2 leftover files again'), findsNothing);
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
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    _TestApp(
      repository: repository,
      showDebugMockAction: showDebugMockAction,
      downloadService: downloadService,
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.repository,
    required this.showDebugMockAction,
    this.downloadService,
    required this.locale,
  });

  final DownloadRepository repository;
  final bool showDebugMockAction;
  final DownloadService? downloadService;
  final Locale locale;

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
        locale: locale,
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

class _CancelInFlightDownloadService extends _FakeDownloadService {
  _CancelInFlightDownloadService(
    super.repository,
    this.settleFuture,
  );

  final Future<void> settleFuture;

  @override
  Future<void> cancel(String taskId) async {
    final task = await repository.getTask(taskId);
    if (task == null) {
      return;
    }
    await repository.upsertTask(
      task.copyWith(
        status: DownloadStatus.canceled,
        failureReason: DownloadFailureReason.canceled,
        failureMessage: null,
        progress: 0,
        totalBytes: null,
        downloadedBytes: 0,
        localPath: null,
      ),
    );
    await settleFuture;
  }
}

class _PauseInFlightDownloadService extends _FakeDownloadService {
  _PauseInFlightDownloadService(
    super.repository,
    this.settleFuture,
  );

  final Future<void> settleFuture;

  @override
  Future<void> pause(String taskId) async {
    final task = await repository.getTask(taskId);
    if (task == null) {
      return;
    }
    await repository.upsertTask(
      task.copyWith(
        status: DownloadStatus.paused,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 0,
        totalBytes: null,
        downloadedBytes: 0,
        localPath: '/tmp/partial-video.mp4',
      ),
    );
    await settleFuture;
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
  final StreamController<List<DownloadTask>> _controller =
      StreamController<List<DownloadTask>>.broadcast();

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
    _tasks.removeWhere((task) => task.id == taskId);
    _controller.add(List.unmodifiable(_tasks));
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
    final index = _tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    _controller.add(List.unmodifiable(_tasks));
  }

  @override
  Stream<List<DownloadTask>> watchTasks() {
    return Stream<List<DownloadTask>>.multi((controller) {
      controller.add(List.unmodifiable(_tasks));
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = subscription.cancel;
    });
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
