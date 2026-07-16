import 'dart:async';

import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/core/error/app_exception.dart';
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

  testWidgets('download page load surfaces repository errors calmly', (
    tester,
  ) async {
    const l10n = AppLocalizations(Locale('en'));

    await _pumpDownloadPage(
      tester,
      _FakeDownloadRepository(const []),
      downloadTasksStream: Stream<List<DownloadTask>>.error(
        const AppException(
          'Downloads are temporarily unavailable.',
          code: 'download_busy',
        ),
      ),
    );

    expect(find.text(l10n.downloadActionBusyMessage), findsOneWidget);
    expect(find.textContaining('AppException'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'download page load hides raw app-exception wrappers behind calm fallback copy',
    (tester) async {
      const l10n = AppLocalizations(Locale('en'));

      await _pumpDownloadPage(
        tester,
        _FakeDownloadRepository(const []),
        downloadTasksStream: Stream<List<DownloadTask>>.error(
          const AppException(
            'AppException: [download_failed] DioException: socket closed',
          ),
        ),
      );

      expect(
        find.text(l10n.downloadActionFailedMessage),
        findsOneWidget,
      );
      expect(find.textContaining('AppException'), findsNothing);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('socket closed'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'download page load hides raw non-app exceptions behind calm fallback copy',
    (tester) async {
      await _pumpDownloadPage(
        tester,
        _FakeDownloadRepository(const []),
        downloadTasksStream: Stream<List<DownloadTask>>.error(
          StateError('database handshake failed'),
        ),
      );

      expect(
        find.text(
          'Downloads are temporarily unavailable. Try again in a moment.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('database handshake failed'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'pending and preparing downloads wait to show progress until transfer begins',
    (tester) async {
      final repository = _FakeDownloadRepository([
        _task('pending', DownloadStatus.pending),
        _task('preparing', DownloadStatus.preparing),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.text(
          'This download is ready to start. AniDestiny will show progress after the file transfer begins.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'AniDestiny is preparing this download. Progress will appear here after the file transfer begins.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-progress-pending')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-progress-preparing')),
        findsNothing,
      );
      expect(find.textContaining('Progress:'), findsNothing);
    },
  );

  testWidgets(
    'single ended task keeps page-level clear hidden',
    (tester) async {
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-completed')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('download-task-remove-completed')),
          matching: find.text('Remove from list'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('download page shows the newly added task first when focused', (
    tester,
  ) async {
    final repository = _FakeDownloadRepository([
      _task('older-1', DownloadStatus.pending),
      _task('target', DownloadStatus.unsupported),
      _task('older-2', DownloadStatus.completed),
    ]);

    await _pumpDownloadPage(
      tester,
      repository,
      focusedTaskId: 'target',
    );

    expect(
      find.text(
        'Showing the download you just added first so you can keep going.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('download-task-focus-indicator-target')),
      findsOneWidget,
    );

    final targetTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('download-task-card-target')),
    );
    final olderTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('download-task-card-older-1')),
    );
    expect(targetTopLeft.dy, lessThan(olderTopLeft.dy));
  });

  testWidgets(
    'single failed task with a partial file keeps page-level clear hidden and exposes discard copy',
    (tester) async {
      _stubCleanupPathExists({'/tmp/failed-partial.mp4'});
      final repository = _FakeDownloadRepository([
        _task('failed', DownloadStatus.failed).copyWith(
          localPath: '/tmp/failed-partial.mp4',
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-failed')),
        findsOneWidget,
      );
      expect(find.byTooltip('Discard download'), findsOneWidget);
      expect(find.byTooltip('Remove from list'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('download-task-remove-failed')),
          matching: find.text('Discard download'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'This download did not finish successfully. You can retry it now, or discard this download to clear the partial file from this failed attempt.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'single failed task with a stale partial path falls back to remove copy',
    (tester) async {
      _stubCleanupPathExists(const {});
      final repository = _FakeDownloadRepository([
        _task('failed', DownloadStatus.failed).copyWith(
          localPath: '/tmp/failed-partial-missing.mp4',
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-failed')),
        findsOneWidget,
      );
      expect(find.byTooltip('Remove from list'), findsOneWidget);
      expect(find.byTooltip('Discard download'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('download-task-remove-failed')),
          matching: find.text('Remove from list'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'This download did not finish successfully. You can retry it now, or remove it from the list if you no longer need this record.',
        ),
        findsOneWidget,
      );
    },
  );

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
    'single removable task keeps discarded leftovers visible for manual cleanup',
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
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('downloads-remove-ready-task')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. You can use "Remove from list" on the task that is already ready now. After you delete that file, return here and tap Check again on this task.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'This download was discarded, but AniDestiny could not clear the partial file automatically. You can use "Remove from list" on the task that is already ready now. For this leftover partial file, remove it from your device if you no longer need it, then return here and tap Check again.',
        ),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-remove-ready-task')));
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(repository.deletedTaskIds, ['completed']);
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. After you delete it, return here and tap Check again on that task.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'single leftover guidance points at batch clear when other ended tasks are already ready',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      final repository = _FakeDownloadRepository([
        _task('completed-a', DownloadStatus.completed),
        _task('completed-b', DownloadStatus.completed),
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: partialPath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until that leftover partial file is gone. You can use "Clear 2 ended tasks from list" above for the other ended tasks now. After you delete that file, return here and tap Check again on this task.',
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
    'manual cleanup tasks become removable again after users check the leftover file status',
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
      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
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
      expect(
        find.widgetWithText(SnackBarAction, 'Remove from list'),
        findsOneWidget,
      );
      tester
          .widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Remove from list'),
          )
          .onPressed();
      await tester.pumpAndSettle();

      expect(repository.deletedTaskIds, ['canceled']);
    },
  );

  testWidgets(
    'single cleanup recheck offers the batch clear action when other ended tasks are ready',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const stalePath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({stalePath});
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('canceled', DownloadStatus.canceled).copyWith(
          localPath: stalePath,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      _stubCleanupPathExists(const {});
      await tester.tap(
        find.byKey(const ValueKey('download-task-refresh-cleanup-canceled')),
      );
      await tester.pump();

      expect(
        find.text(
          'That leftover partial file is gone. You can use "Clear 2 ended tasks from list" above now, or remove this task from the list.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clear 2 ended tasks from list'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsOneWidget,
      );

      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Clear 2 ended tasks from list'),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(repository.deletedTaskIds, ['completed', 'canceled']);
    },
  );

  testWidgets(
    'single removable task still leaves multi-leftover follow-up visible',
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

      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsNothing,
      );

      await tester
          .tap(find.byKey(const ValueKey('download-task-remove-completed')));
      await tester.pump();

      expect(repository.deleteAttempts, ['completed']);
      expect(repository.deletedTaskIds, ['completed']);
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until those leftover partial files are gone. After you delete them, use "Check 2 leftover files again" above or tap Check again on each task.',
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
          'AniDestiny confirmed that 1 leftover partial file is gone. You can use "Remove from list" on the task that is already ready now. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
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

  testWidgets(
    'retry action keeps failed downloads in an explicit retrying state until transfer resumes',
    (tester) async {
      final settleStart = Completer<void>();
      final repository = _FakeDownloadRepository([
        _task('failed', DownloadStatus.failed).copyWith(
          failureReason: DownloadFailureReason.networkError,
          failureMessage: 'The source stopped responding.',
          progress: 0.42,
          totalBytes: 100,
          downloadedBytes: 42,
        ),
      ]);
      final service = _StartInFlightDownloadService(
        repository,
        settleStart.future,
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester.tap(
        find.byKey(const ValueKey('download-task-retry-failed')),
      );
      await tester.pump();

      expect(find.text('Retrying...'), findsOneWidget);
      expect(
        find.text(
          'AniDestiny is retrying this download. Progress will appear here after the file transfer resumes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Failed'), findsNothing);
      expect(find.text('Network error'), findsNothing);
      expect(find.text('The source stopped responding.'), findsNothing);
      expect(
        find.byKey(const ValueKey('download-task-progress-failed')),
        findsNothing,
      );

      settleStart.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Retrying...'), findsNothing);
      expect(
        find.text(
          'AniDestiny is preparing this download. Progress will appear here after the file transfer begins.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'start handoff unlocks task actions once the download reaches preparing',
    (tester) async {
      final startPreparing = Completer<void>();
      final finishStart = Completer<void>();
      final repository = _FakeDownloadRepository([
        _task('pending', DownloadStatus.pending),
      ]);
      final service = _PreparingInFlightDownloadService(
        repository,
        startPreparing.future,
        finishStart.future,
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester.tap(
        find.byKey(const ValueKey('download-task-start-pending')),
      );
      await tester.pump();

      expect(find.text('Starting...'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('download-task-busy-pending')),
        findsOneWidget,
      );

      startPreparing.complete();
      await service.enteredPreparing.future;
      await tester.pump();

      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Starting...'), findsNothing);
      expect(
        find.byKey(const ValueKey('download-task-busy-pending')),
        findsNothing,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('download-task-cancel-pending')),
            )
            .onPressed,
        isNotNull,
      );

      finishStart.complete();
      await tester.pump();
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
    expect(find.text('Discard download'), findsNWidgets(2));
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
      find.byKey(const ValueKey('download-task-progress-paused')),
      findsNothing,
    );
    expect(find.textContaining('Progress:'), findsOneWidget);
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
      const l10n = AppLocalizations(Locale('en'));
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
        find.textContaining('Cleared 3 ended tasks from the list, 1 failed.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.downloadActionFailedMessage),
        findsOneWidget,
      );
      expect(find.textContaining('delete failed for failed'), findsNothing);
    },
  );

  testWidgets(
    'batch clear failures show readable action reason for app exceptions',
    (tester) async {
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('failed', DownloadStatus.failed),
      ]);
      final service = _RemoveEndedTaskFailureDownloadService(
        repository,
        const AppException(
          'AppException: [download_not_found] task is not in the list anymore',
          code: 'download_not_found',
        ),
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(
        find.textContaining('Cleared 0 ended tasks from the list, 2 failed.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'This download task was not found or was already removed. Please try again later.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('AppException'), findsNothing);
      expect(find.textContaining('[download_not_found]'), findsNothing);
    },
  );

  testWidgets(
    'batch clear failures show readable action reason for non-app exceptions',
    (tester) async {
      const l10n = AppLocalizations(Locale('en'));
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('failed', DownloadStatus.failed),
      ]);
      final service = _RemoveEndedTaskFailureDownloadService(
        repository,
        StateError('remove failed because of a filesystem lock'),
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(
        find.textContaining('Cleared 0 ended tasks from the list, 2 failed.'),
        findsOneWidget,
      );
      expect(find.textContaining(l10n.downloadActionFailedMessage), findsOneWidget);
      expect(find.textContaining('filesystem lock'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    },
  );

  testWidgets(
    'batch clear failures show readable action reasons for mixed outcomes',
    (tester) async {
      const l10n = AppLocalizations(Locale('en'));
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('failed', DownloadStatus.failed),
      ]);
      final service = _RemoveEndedTaskSequentialFailureDownloadService(
        repository,
        [
          const AppException(
            'AppException: [download_not_found] task is not in the list anymore',
            code: 'download_not_found',
          ),
          const AppException(
            'AppException: [download_manual_cleanup_required] manual cleanup still needed',
            code: 'download_manual_cleanup_required',
          ),
        ],
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(
        find.textContaining('Cleared 0 ended tasks from the list, 2 failed.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.downloadActionTaskNotFoundMessage),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.downloadManualCleanupRequiredError),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'batch clear failures with manual cleanup still offer a check again action',
    (tester) async {
      const l10n = AppLocalizations(Locale('en'));
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('failed', DownloadStatus.failed),
      ]);
      final service = _RemoveEndedTaskSequentialFailureDownloadService(
        repository,
        [
          const AppException(
            'AppException: [download_not_found] task is not in the list anymore',
            code: 'download_not_found',
          ),
          const AppException(
            'AppException: [download_manual_cleanup_required] manual cleanup still needed',
            code: 'download_manual_cleanup_required',
          ),
        ],
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(
        find.textContaining('Cleared 0 ended tasks from the list, 2 failed.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.downloadActionTaskNotFoundMessage),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.downloadManualCleanupRequiredError),
        findsOneWidget,
      );
      final recheckAction =
          find.widgetWithText(SnackBarAction, l10n.checkAgain);
      expect(recheckAction, findsOneWidget);

      tester.widget<SnackBarAction>(recheckAction).onPressed();
      await tester.pump();

      expect(
        find.textContaining(
          l10n.downloadManualCleanupRecheckClearedAction(
            l10n.clearEndedDownloadsCount(2),
          ),
        ),
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

  testWidgets(
    'batch clear keeps each ended task in an explicit removing state until deletion finishes',
    (tester) async {
      final deleteBlocker = Completer<void>();
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
        _task('failed', DownloadStatus.failed),
      ]);
      final service = _RemoveEndedTaskInFlightDownloadService(
        repository,
        deleteBlocker.future,
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('downloads-clear-ended-tasks')));
      await tester.pump();

      expect(find.text('Removing...'), findsNWidgets(2));
      expect(find.text('Completed'), findsNothing);
      expect(find.text('Failed'), findsNothing);
      expect(
        find.text(
          'AniDestiny is still removing this task from the list. Any file already on your device will stay there.',
        ),
        findsNWidgets(2),
      );

      deleteBlocker.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Removing...'), findsNothing);
      expect(repository.deletedTaskIds, ['completed', 'failed']);
    },
  );

  testWidgets('remove action failures keep raw errors out of the snackbar',
      (tester) async {
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
    expect(
      find.text(
        'AniDestiny could not finish that download action right now. Try again in a moment.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Bad state'), findsNothing);
    expect(find.textContaining('delete failed'), findsNothing);
  });

  testWidgets(
    'remove action failures hide raw app-exception wrappers from the snackbar',
    (tester) async {
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
      ]);
      final service = _RemoveEndedTaskFailureDownloadService(
        repository,
        const AppException(
          'AppException: [download_failed] DioException: socket closed',
        ),
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('download-task-remove-completed')));
      await tester.pump();

      expect(
        find.text(
          'AniDestiny could not finish that download action right now. Try again in a moment.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('AppException'), findsNothing);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('socket closed'), findsNothing);
    },
  );

  testWidgets(
    'remove action failures keep manual cleanup actionable',
    (tester) async {
      const l10n = AppLocalizations(Locale('en'));
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
      ]);
      final service = _RemoveEndedTaskFailureDownloadService(
        repository,
        const AppException(
          'AppException: [download_manual_cleanup_required] manual cleanup still needed',
          code: 'download_manual_cleanup_required',
        ),
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester.tap(
        find.byKey(const ValueKey('download-task-remove-completed')),
      );
      await tester.pump();

      expect(
        find.text(l10n.downloadManualCleanupRequiredError),
        findsOneWidget,
      );
      final recheckAction =
          find.widgetWithText(SnackBarAction, l10n.checkAgain);
      expect(recheckAction, findsOneWidget);
      tester.widget<SnackBarAction>(recheckAction).onPressed();
      await tester.pump();

      expect(
        find.text(l10n.downloadManualCleanupRecheckCleared),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'remove action failures keep manual cleanup actionable from plain wrapper',
    (tester) async {
      const l10n = AppLocalizations(Locale('en'));
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
      ]);
      final service = _RemoveEndedTaskFailureDownloadService(
        repository,
        'AppException [download_manual_cleanup_required] manual cleanup still needed',
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester.tap(
        find.byKey(const ValueKey('download-task-remove-completed')),
      );
      await tester.pump();

      expect(
        find.text(l10n.downloadManualCleanupRequiredError),
        findsOneWidget,
      );
      final recheckAction =
          find.widgetWithText(SnackBarAction, l10n.checkAgain);
      expect(recheckAction, findsOneWidget);
      tester.widget<SnackBarAction>(recheckAction).onPressed();
      await tester.pump();

      expect(
        find.text(l10n.downloadManualCleanupRecheckCleared),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'remove action failures keep product-facing app exceptions visible',
    (tester) async {
      final repository = _FakeDownloadRepository([
        _task('completed', DownloadStatus.completed),
      ]);
      final service = _RemoveEndedTaskFailureDownloadService(
        repository,
        const AppException('Downloads are temporarily locked. Try again.'),
      );

      await _pumpDownloadPage(
        tester,
        repository,
        downloadService: service,
      );

      await tester
          .tap(find.byKey(const ValueKey('download-task-remove-completed')));
      await tester.pump();

      expect(
        find.text('Downloads are temporarily locked. Try again.'),
        findsOneWidget,
      );
    },
  );

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
          '标记为“待清理残留文件”的任务会继续留在列表里，直到这份半截文件已经被手动删掉，或 AniDestiny 成功把它清掉。删完后回到这里点一下“重新检查”。',
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
          'AniDestiny confirmed that 1 leftover partial file is gone. You can use "Remove from list" on the task that is already ready now. 1 still needs cleanup. Delete that leftover file first, then tap Check again on that task.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled-a')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SnackBarAction, 'Remove from list'),
        findsOneWidget,
      );
      tester
          .widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Remove from list'),
          )
          .onPressed();
      await tester.pumpAndSettle();

      expect(repository.deletedTaskIds, ['canceled-a']);
    },
  );

  testWidgets(
    'multi-leftover guidance also points at batch clear when other ended tasks are ready',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB});
      final repository = _FakeDownloadRepository([
        _task('completed-a', DownloadStatus.completed),
        _task('completed-b', DownloadStatus.completed),
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

      expect(find.text('Clear 2 ended tasks from list'), findsOneWidget);
      expect(find.text('Check 2 leftover files again'), findsOneWidget);
      expect(
        find.text(
          'Tasks marked Needs cleanup stay in the list until those leftover partial files are gone. You can use "Clear 2 ended tasks from list" above for the other ended tasks now. After you delete the leftover files, use "Check 2 leftover files again" above or tap Check again on each task.',
        ),
        findsOneWidget,
      );
      final tileGuidance = find.textContaining(
        'For the leftover partial files, remove them from your device if you no longer need them, then use "Check 2 leftover files again" above or tap Check again here.',
      );
      await tester.scrollUntilVisible(tileGuidance, 200);
      expect(
        tileGuidance,
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'partial batch recheck keeps direct remove available for the task that is already ready',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      const partialPathC = '/tmp/partial-video-c.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB, partialPathC});
      final repository = _FakeDownloadRepository([
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-c', DownloadStatus.canceled).copyWith(
          localPath: partialPathC,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      _stubCleanupPathExists({partialPathB, partialPathC});
      await tester.tap(
        find.byKey(const ValueKey('downloads-recheck-manual-cleanup')),
      );
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. You can use "Remove from list" on the task that is already ready now. 2 still need cleanup. After you delete them, use "Check 2 leftover files again" above or tap Check again on each task.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SnackBarAction, 'Remove from list'),
        findsOneWidget,
      );
      expect(find.text('Check 2 leftover files again'), findsOneWidget);

      tester
          .widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Remove from list'),
          )
          .onPressed();
      await tester.pumpAndSettle();

      expect(repository.deletedTaskIds, ['canceled-a']);
    },
  );

  testWidgets(
    'partial batch recheck also points at batch clear when other tasks are ready now',
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

      _stubCleanupPathExists({partialPathB});
      await tester.tap(
        find.byKey(const ValueKey('downloads-recheck-manual-cleanup')),
      );
      await tester.pump();

      expect(
        find.textContaining(
          'AniDestiny confirmed that 1 leftover partial file is gone.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('still needs cleanup'),
        findsOneWidget,
      );
      expect(find.text('Clear 2 ended tasks from list'), findsNWidgets(2));
    },
  );

  testWidgets(
    'page-level cleanup recheck offers batch clear when all leftovers are gone',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
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
          'AniDestiny confirmed that all 2 leftover partial files are gone. You can use "Clear 2 ended tasks from list" above now, or remove those tasks one by one.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clear 2 ended tasks from list'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('downloads-clear-ended-tasks')),
        findsOneWidget,
      );
      expect(find.text('Check 2 leftover files again'), findsNothing);

      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Clear 2 ended tasks from list'),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(repository.deletedTaskIds, ['canceled-a', 'canceled-b']);
    },
  );

  testWidgets(
    'resume offers batch clear after recovered leftovers become removable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
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

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      _stubCleanupPathExists(const {});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that 2 leftover partial files are gone. You can use "Clear 3 ended tasks from list" above now, or remove those tasks one by one.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clear 3 ended tasks from list'), findsNWidgets(2));

      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Clear 3 ended tasks from list'),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(
        repository.deletedTaskIds,
        ['completed', 'canceled-a', 'canceled-b'],
      );
    },
  );

  testWidgets(
    'resume keeps single-task cleanup copy explicit when batch clear also becomes available',
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

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      _stubCleanupPathExists(const {});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. You can use "Clear 2 ended tasks from list" above now, or remove this task from the list.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clear 2 ended tasks from list'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resume keeps batch clear visible when one leftover still needs manual cleanup',
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

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      _stubCleanupPathExists({partialPathB});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.textContaining(
          'AniDestiny confirmed that 1 leftover partial file is gone.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 still needs cleanup. Delete that leftover file first'),
        findsOneWidget,
      );
      expect(find.text('Clear 2 ended tasks from list'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('download-task-remove-canceled-a')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resume keeps batch clear action available when multiple leftovers remain',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      const partialPathC = '/tmp/partial-video-c.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB, partialPathC});
      final repository = _FakeDownloadRepository([
        _task('completed-a', DownloadStatus.completed),
        _task('completed-b', DownloadStatus.completed),
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-c', DownloadStatus.canceled).copyWith(
          localPath: partialPathC,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      _stubCleanupPathExists({partialPathB, partialPathC});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.textContaining(
          'AniDestiny confirmed that 1 leftover partial file is gone.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resume keeps direct remove available when one recovered task is ready but other leftovers remain',
    (tester) async {
      const partialPathA = '/tmp/partial-video-a.mp4';
      const partialPathB = '/tmp/partial-video-b.mp4';
      const partialPathC = '/tmp/partial-video-c.mp4';
      _stubCleanupPathExists({partialPathA, partialPathB, partialPathC});
      final repository = _FakeDownloadRepository([
        _task('canceled-a', DownloadStatus.canceled).copyWith(
          localPath: partialPathA,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-b', DownloadStatus.canceled).copyWith(
          localPath: partialPathB,
          failureReason: DownloadFailureReason.canceled,
        ),
        _task('canceled-c', DownloadStatus.canceled).copyWith(
          localPath: partialPathC,
          failureReason: DownloadFailureReason.canceled,
        ),
      ]);

      await _pumpDownloadPage(tester, repository);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      _stubCleanupPathExists({partialPathB, partialPathC});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.text(
          'AniDestiny confirmed that 1 leftover partial file is gone. You can use "Remove from list" on the task that is already ready now. 2 still need cleanup. After you delete them, use "Check 2 leftover files again" above or tap Check again on each task.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SnackBarAction, 'Remove from list'),
        findsOneWidget,
      );

      tester
          .widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Remove from list'),
          )
          .onPressed();
      await tester.pumpAndSettle();

      expect(repository.deletedTaskIds, ['canceled-a']);
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
    expect(tester.widget<TextButton>(removeButton).onPressed, isNull);

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
      expect(clearButton, findsNothing);

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
  String? focusedTaskId,
  DownloadService? downloadService,
  Stream<List<DownloadTask>>? downloadTasksStream,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    _TestApp(
      repository: repository,
      showDebugMockAction: showDebugMockAction,
      focusedTaskId: focusedTaskId,
      downloadService: downloadService,
      downloadTasksStream: downloadTasksStream,
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.repository,
    required this.showDebugMockAction,
    this.focusedTaskId,
    this.downloadService,
    this.downloadTasksStream,
    required this.locale,
  });

  final DownloadRepository repository;
  final bool showDebugMockAction;
  final String? focusedTaskId;
  final DownloadService? downloadService;
  final Stream<List<DownloadTask>>? downloadTasksStream;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final effectiveDownloadService =
        downloadService ?? _FakeDownloadService(repository);
    return ProviderScope(
      overrides: [
        downloadRepositoryProvider.overrideWithValue(repository),
        httpDownloadServiceProvider.overrideWithValue(effectiveDownloadService),
        if (downloadTasksStream != null)
          downloadTasksProvider.overrideWith((ref) => downloadTasksStream!),
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
          body: DownloadPage(
            showDebugMockAction: showDebugMockAction,
            focusTaskId: focusedTaskId,
          ),
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

class _RemoveEndedTaskInFlightDownloadService extends _FakeDownloadService {
  _RemoveEndedTaskInFlightDownloadService(
    super.repository,
    this.settleFuture,
  );

  final Future<void> settleFuture;

  @override
  Future<void> removeEndedTask(String taskId) async {
    await settleFuture;
    return super.removeEndedTask(taskId);
  }
}

class _RemoveEndedTaskFailureDownloadService extends _FakeDownloadService {
  _RemoveEndedTaskFailureDownloadService(
    super.repository,
    this.error,
  );

  final Object error;

  @override
  Future<void> removeEndedTask(String taskId) async {
    throw error;
  }
}

class _RemoveEndedTaskSequentialFailureDownloadService
    extends _FakeDownloadService {
  _RemoveEndedTaskSequentialFailureDownloadService(
    super.repository,
    this.errors,
  );

  final List<Object> errors;
  var _attemptIndex = 0;

  @override
  Future<void> removeEndedTask(String taskId) async {
    final index = _attemptIndex;
    _attemptIndex += 1;
    if (index >= errors.length) {
      return super.removeEndedTask(taskId);
    }
    final error = errors[index];
    throw error;
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

class _StartInFlightDownloadService extends _FakeDownloadService {
  _StartInFlightDownloadService(
    super.repository,
    this.settleFuture,
  );

  final Future<void> settleFuture;

  @override
  Future<void> start(String taskId) async {
    await settleFuture;
    final task = await repository.getTask(taskId);
    if (task == null) {
      return;
    }
    await repository.upsertTask(
      task.copyWith(
        status: DownloadStatus.preparing,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 0,
        totalBytes: null,
        downloadedBytes: 0,
      ),
    );
  }
}

class _PreparingInFlightDownloadService extends _FakeDownloadService {
  _PreparingInFlightDownloadService(
    super.repository,
    this.startPreparingFuture,
    this.finishFuture,
  );

  final Future<void> startPreparingFuture;
  final Future<void> finishFuture;
  final Completer<void> enteredPreparing = Completer<void>();

  @override
  Future<void> start(String taskId) async {
    await startPreparingFuture;
    final task = await repository.getTask(taskId);
    if (task == null) {
      return;
    }
    await repository.upsertTask(
      task.copyWith(
        status: DownloadStatus.preparing,
        failureReason: DownloadFailureReason.none,
        failureMessage: null,
        progress: 0,
        totalBytes: null,
        downloadedBytes: 0,
      ),
    );
    if (!enteredPreparing.isCompleted) {
      enteredPreparing.complete();
    }
    await finishFuture;
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
