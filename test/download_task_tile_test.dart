import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
import 'package:ani_destiny/features/download/presentation/download_task_cleanup_state.dart';
import 'package:ani_destiny/features/download/presentation/widgets/download_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completed download tasks can be removed from the list', (
    tester,
  ) async {
    var removeTapped = false;

    await tester.pumpWidget(
      _buildTileApp(
        DownloadTaskTile(
          task: _task(status: DownloadStatus.completed),
          isBusy: false,
          onStart: () {},
          onPause: () {},
          onCancel: () {},
          onRemove: () {
            removeTapped = true;
          },
        ),
      ),
    );
    await tester.pump();

    final removeButton =
        find.byKey(const ValueKey('download-task-remove-task-1'));
    expect(removeButton, findsOneWidget);
    expect(find.byTooltip('Remove from list'), findsOneWidget);
    expect(
      find.text(
        'Removing this task only clears it from the list. The downloaded file stays on your device.',
      ),
      findsOneWidget,
    );

    await tester.tap(removeButton);
    await tester.pump();

    expect(removeTapped, isTrue);
  });

  testWidgets('failed download tasks expose retry and remove actions', (
    tester,
  ) async {
    var startTapped = false;
    var removeTapped = false;

    await tester.pumpWidget(
      _buildTileApp(
        DownloadTaskTile(
          task: _task(status: DownloadStatus.failed),
          isBusy: false,
          onStart: () {
            startTapped = true;
          },
          onPause: () {},
          onCancel: () {},
          onRemove: () {
            removeTapped = true;
          },
        ),
      ),
    );
    await tester.pump();

    final retryButton =
        find.byKey(const ValueKey('download-task-retry-task-1'));
    final removeButton =
        find.byKey(const ValueKey('download-task-remove-task-1'));

    expect(retryButton, findsOneWidget);
    expect(removeButton, findsOneWidget);
    expect(find.byTooltip('Discard download'), findsNothing);
    expect(find.byTooltip('Remove from list'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(
      find.text(
        'Pause is basic support and may restart the download when resumed.',
      ),
      findsNothing,
    );

    await tester.tap(retryButton);
    await tester.pump();
    await tester.tap(removeButton);
    await tester.pump();

    expect(startTapped, isTrue);
    expect(removeTapped, isTrue);
  });

  testWidgets('canceled download tasks stay removable without error styling', (
    tester,
  ) async {
    var removeTapped = false;

    await tester.pumpWidget(
      _buildTileApp(
        DownloadTaskTile(
          task: _task(
            status: DownloadStatus.canceled,
            failureReason: DownloadFailureReason.canceled,
            failureMessage: 'Download canceled.',
          ),
          isBusy: false,
          onStart: () {},
          onPause: () {},
          onCancel: () {},
          onRemove: () {
            removeTapped = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final removeButton =
        find.byKey(const ValueKey('download-task-remove-task-1'));

    expect(removeButton, findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('Download canceled.'), findsNothing);
    expect(find.byTooltip('Remove from list'), findsOneWidget);
    expect(
      find.text(
        'This download was discarded. Any partial file was cleared. You can remove this task from the list when you are done.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('download-task-progress-task-1')),
      findsNothing,
    );
    expect(find.textContaining('Progress:'), findsNothing);
    expect(find.textContaining('Local path:'), findsNothing);

    await tester.tap(removeButton);
    await tester.pump();

    expect(removeTapped, isTrue);
  });

  testWidgets(
    'unsupported BT downloads replace placeholder copy with honest guidance',
    (tester) async {
      var removeTapped = false;
      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.unsupported,
              kind: DownloadKind.bt,
              failureReason: DownloadFailureReason.unsupportedType,
              failureMessage: 'BT download is not implemented yet.',
            ),
            isBusy: false,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {
              removeTapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BT / magnet'), findsOneWidget);
      expect(find.text('BT placeholder'), findsNothing);
      expect(
        find.text(
          'This download currently uses a BT / magnet link, and AniDestiny cannot handle that type directly yet.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'AniDestiny cannot take over this type of download yet. You can remove this task from the list for now.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('download-task-remove-task-1')),
          matching: find.text('Remove from list'),
        ),
        findsOneWidget,
      );
      expect(find.text('BT download is not implemented yet.'), findsNothing);
      expect(
        find.byKey(const ValueKey('download-task-progress-task-1')),
        findsNothing,
      );
      expect(find.textContaining('Progress:'), findsNothing);

      await tester
          .tap(find.byKey(const ValueKey('download-task-remove-task-1')));
      await tester.pump();

      expect(removeTapped, isTrue);
    },
  );

  testWidgets(
    'busy stopped downloads keep showing an in-flight stopping state until cleanup settles',
    (tester) async {
      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.paused,
              failureReason: DownloadFailureReason.none,
            ),
            isBusy: true,
            busyAction: DownloadTaskBusyAction.pause,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
          ),
        ),
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
      expect(
        find.text(
          'This download is stopped for now. Retrying may restart it from the beginning. Discarding it clears any partial file.',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-busy-task-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-progress-task-1')),
        findsNothing,
      );
      expect(find.textContaining('Progress:'), findsNothing);
    },
  );

  testWidgets(
    'busy discarded downloads keep showing an in-flight discard state until cleanup settles',
    (tester) async {
      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.canceled,
              failureReason: DownloadFailureReason.canceled,
            ),
            isBusy: true,
            busyAction: DownloadTaskBusyAction.cancel,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
          ),
        ),
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
      expect(
        find.text(
          'This download was discarded. Any partial file was cleared. You can remove this task from the list when you are done.',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('download-task-busy-task-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'canceled downloads show leftover local path when cleanup still needs help',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});
      var refreshTapped = false;
      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.canceled,
              failureReason: DownloadFailureReason.canceled,
              localPath: partialPath,
            ),
            isBusy: false,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
            onRefreshCleanupStatus: () {
              refreshTapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Needs cleanup'),
        findsOneWidget,
      );
      expect(
        find.text(
          'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then return here and tap Check again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Local path: $partialPath'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('download-task-progress-task-1')),
        findsNothing,
      );
      expect(find.textContaining('Progress:'), findsNothing);
      expect(
        find.byKey(const ValueKey('download-task-remove-task-1')),
        findsNothing,
      );
      expect(find.byTooltip('Remove from list'), findsNothing);
      expect(find.text('Check again'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('download-task-refresh-cleanup-task-1')),
      );
      await tester.pump();

      expect(refreshTapped, isTrue);
    },
  );

  testWidgets(
    'manual cleanup tiles mention the page-level batch recheck when it is available',
    (tester) async {
      const partialPath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists({partialPath});

      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.canceled,
              failureReason: DownloadFailureReason.canceled,
              localPath: partialPath,
            ),
            isBusy: false,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
            onRefreshCleanupStatus: () {},
            manualCleanupBatchRecheckLabel: 'Check 2 leftover files again',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'This download was discarded, but AniDestiny could not clear the partial file automatically. Remove the leftover file from your device if you no longer need it, then use "Check 2 leftover files again" above or tap Check again here.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'stopped direct downloads hide stale progress once the task is settled',
    (tester) async {
      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.paused,
              progress: 0,
            ),
            isBusy: false,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Stopped'), findsOneWidget);
      expect(
        find.text(
          'This download is stopped for now. Retrying may restart it from the beginning. Discarding it clears any partial file.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-progress-task-1')),
        findsNothing,
      );
      expect(find.textContaining('Progress:'), findsNothing);
    },
  );

  testWidgets(
    'canceled downloads with stale local paths become removable again',
    (tester) async {
      const stalePath = '/tmp/partial-video.mp4';
      _stubCleanupPathExists(const {});

      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.canceled,
              failureReason: DownloadFailureReason.canceled,
              localPath: stalePath,
            ),
            isBusy: false,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Needs cleanup'), findsNothing);
      expect(find.text('Discarded'), findsOneWidget);
      expect(
        find.text(
          'This download was discarded. Any partial file was cleared. You can remove this task from the list when you are done.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('download-task-progress-task-1')),
        findsNothing,
      );
      expect(find.textContaining('Progress:'), findsNothing);
      expect(find.textContaining('Local path:'), findsNothing);
      expect(
        find.byKey(const ValueKey('download-task-remove-task-1')),
        findsOneWidget,
      );
      expect(find.byTooltip('Remove from list'), findsOneWidget);
    },
  );

  testWidgets(
    'removable canceled downloads use the discarded status label',
    (tester) async {
      await tester.pumpWidget(
        _buildTileApp(
          DownloadTaskTile(
            task: _task(
              status: DownloadStatus.canceled,
              failureReason: DownloadFailureReason.canceled,
            ),
            isBusy: false,
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Discarded'), findsOneWidget);
      expect(find.text('Needs cleanup'), findsNothing);
    },
  );

  testWidgets('download progress label stays within 0 to 100 percent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTileApp(
        ListView(
          children: [
            DownloadTaskTile(
              task: _task(status: DownloadStatus.downloading, progress: 1.2),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
            DownloadTaskTile(
              task: _task(status: DownloadStatus.downloading, progress: -0.2),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progress: 100% · 1.0 KB / 1.0 KB'), findsOneWidget);
    expect(find.text('Progress: 0% · 1.0 KB / 1.0 KB'), findsOneWidget);
    expect(find.textContaining('Progress: 120%'), findsNothing);
    expect(find.textContaining('Progress: -20%'), findsNothing);
  });

  testWidgets('direct downloads use honest stop and retry copy',
      (tester) async {
    await tester.pumpWidget(
      _buildTileApp(
        ListView(
          children: [
            DownloadTaskTile(
              task: _task(status: DownloadStatus.downloading),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
            DownloadTaskTile(
              task: _task(status: DownloadStatus.paused),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Stop for now'), findsOneWidget);
    expect(find.byTooltip('Retry'), findsOneWidget);
    expect(find.byTooltip('Discard download'), findsNWidgets(2));
    expect(find.byTooltip('Pause'), findsNothing);
    expect(find.text('Stopped'), findsOneWidget);
    expect(
      find.text(
        'Stopping this download keeps the task, but the next retry may restart from the beginning. Discarding it clears any partial file.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'This download is stopped for now. Retrying may restart it from the beginning. Discarding it clears any partial file.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Local path:'), findsNothing);
  });

  testWidgets('only completed downloads show a local path', (tester) async {
    await tester.pumpWidget(
      _buildTileApp(
        ListView(
          children: [
            DownloadTaskTile(
              task: _task(status: DownloadStatus.downloading),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
            DownloadTaskTile(
              task: _task(status: DownloadStatus.failed),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
            DownloadTaskTile(
              task: _task(status: DownloadStatus.completed),
              isBusy: false,
              onStart: () {},
              onPause: () {},
              onCancel: () {},
              onRemove: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local path: /tmp/video.mp4'), findsOneWidget);
    expect(
      find.text(
        'Removing this task only clears it from the list. The downloaded file stays on your device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('busy download tasks disable actions and show inline progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTileApp(
        DownloadTaskTile(
          task: _task(status: DownloadStatus.failed),
          isBusy: true,
          onStart: () {},
          onPause: () {},
          onCancel: () {},
          onRemove: () {},
        ),
      ),
    );
    await tester.pump();

    final retryButton =
        find.byKey(const ValueKey('download-task-retry-task-1'));
    final removeButton =
        find.byKey(const ValueKey('download-task-remove-task-1'));

    expect(retryButton, findsOneWidget);
    expect(removeButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-task-busy-task-1')),
      findsOneWidget,
    );
    expect(tester.widget<IconButton>(retryButton).onPressed, isNull);
    expect(tester.widget<IconButton>(removeButton).onPressed, isNull);
  });
}

Widget _buildTileApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

DownloadTask _task({
  required DownloadStatus status,
  double progress = 1,
  DownloadKind kind = DownloadKind.directFile,
  DownloadFailureReason failureReason = DownloadFailureReason.none,
  String? failureMessage,
  String? localPath,
}) {
  final now = DateTime(2026, 6, 4, 1, 0);
  return DownloadTask(
    id: 'task-1',
    animeId: 'anime-1',
    episodeId: 'episode-1',
    sourceId: 'sakura',
    title: 'AniDestiny',
    episodeTitle: 'Episode 1',
    url: kind == DownloadKind.bt
        ? 'magnet:?xt=urn:btih:abc123'
        : 'https://cdn.example.test/video.mp4',
    kind: kind,
    status: status,
    failureReason: failureReason,
    failureMessage: failureMessage,
    progress: progress,
    totalBytes: 1024,
    downloadedBytes: 1024,
    createdAt: now,
    updatedAt: now,
    localPath: localPath ??
        (status == DownloadStatus.completed ? '/tmp/video.mp4' : null),
  );
}

void _stubCleanupPathExists(Set<String> existingPaths) {
  debugSetDownloadCleanupPathExists(existingPaths.contains);
  addTearDown(() {
    debugSetDownloadCleanupPathExists(null);
  });
}
