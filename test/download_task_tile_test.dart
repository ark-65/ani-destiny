import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/download/domain/entities/download_failure_reason.dart';
import 'package:ani_destiny/features/download/domain/entities/download_kind.dart';
import 'package:ani_destiny/features/download/domain/entities/download_task.dart';
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
    await tester.pumpAndSettle();

    final removeButton =
        find.byKey(const ValueKey('download-task-remove-task-1'));
    expect(removeButton, findsOneWidget);

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
    await tester.pumpAndSettle();

    final retryButton =
        find.byKey(const ValueKey('download-task-retry-task-1'));
    final removeButton =
        find.byKey(const ValueKey('download-task-remove-task-1'));

    expect(retryButton, findsOneWidget);
    expect(removeButton, findsOneWidget);
    expect(find.byTooltip('Cancel'), findsNothing);
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

    await tester.tap(removeButton);
    await tester.pump();

    expect(removeTapped, isTrue);
  });

  testWidgets('download progress label stays within 0 to 100 percent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTileApp(
        Column(
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
    await tester.pumpAndSettle();

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
  DownloadFailureReason failureReason = DownloadFailureReason.none,
  String? failureMessage,
}) {
  final now = DateTime(2026, 6, 4, 1, 0);
  return DownloadTask(
    id: 'task-1',
    animeId: 'anime-1',
    episodeId: 'episode-1',
    sourceId: 'sakura',
    title: 'AniDestiny',
    episodeTitle: 'Episode 1',
    url: 'https://cdn.example.test/video.mp4',
    kind: DownloadKind.directFile,
    status: status,
    failureReason: failureReason,
    failureMessage: failureMessage,
    progress: progress,
    totalBytes: 1024,
    downloadedBytes: 1024,
    createdAt: now,
    updatedAt: now,
    localPath: '/tmp/video.mp4',
  );
}
