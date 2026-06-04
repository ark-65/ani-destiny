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
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: DownloadTaskTile(
            task: _task(status: DownloadStatus.completed),
            onStart: () {},
            onPause: () {},
            onCancel: () {},
            onRemove: () {
              removeTapped = true;
            },
          ),
        ),
      ),
    );

    final removeButton = find.byTooltip('Remove');
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
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: DownloadTaskTile(
            task: _task(status: DownloadStatus.failed),
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
      ),
    );

    final retryButton = find.byTooltip('Start');
    final removeButton = find.byTooltip('Remove');

    expect(retryButton, findsOneWidget);
    expect(removeButton, findsOneWidget);
    expect(find.byTooltip('Cancel'), findsNothing);
    expect(
      find.text('Pause is basic support and may restart the download when resumed.'),
      findsNothing,
    );

    await tester.tap(retryButton);
    await tester.pump();
    await tester.tap(removeButton);
    await tester.pump();

    expect(startTapped, isTrue);
    expect(removeTapped, isTrue);
  });
}

DownloadTask _task({required DownloadStatus status}) {
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
    failureReason: DownloadFailureReason.none,
    progress: 1,
    totalBytes: 1024,
    downloadedBytes: 1024,
    createdAt: now,
    updatedAt: now,
    localPath: '/tmp/video.mp4',
  );
}
