import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/player/domain/entities/player_state.dart';
import 'package:ani_destiny/features/player/presentation/widgets/player_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fullscreen controls expose the next episode action', (
    tester,
  ) async {
    var tapped = 0;

    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: () => tapped++,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Next episode'), findsOneWidget);
    await tester.tap(find.byTooltip('Next episode'));
    expect(tapped, 1);
    expect(find.byTooltip('External player'), findsOneWidget);
  });

  testWidgets('embedded controls keep next episode in the app bar only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Next episode'), findsNothing);
    expect(find.byTooltip('External player'), findsNothing);
    expect(find.byTooltip('Enter fullscreen'), findsOneWidget);
  });

  testWidgets(
      'fullscreen switching state keeps exit fullscreen available while other controls stay busy',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: null,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Loading next episode...',
          onDownload: null,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: true,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Loading next episode...'), findsNWidgets(4));
    final playButton = tester.widget<IconButton>(
      find.byType(IconButton).first,
    );
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Loading next episode...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Loading next episode...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
    expect(slider.value, 0);
    expect(find.text('--:-- / --:--'), findsOneWidget);
    expect(find.text('03:00 / 24:00'), findsNothing);

    final externalPlayerButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.open_in_new),
    );
    expect(externalPlayerButton.onPressed, isNull);
    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(downloadButton.onPressed, isNull);

    final fullscreenButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.fullscreen_exit),
    );
    expect(fullscreenButton.onPressed, isNotNull);
    expect(fullscreenButton.tooltip, 'Exit fullscreen');
  });

  testWidgets('embedded switching state disables entering fullscreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: null,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Loading next episode...',
          onDownload: null,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: true,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    final fullscreenButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.fullscreen),
    );
    expect(fullscreenButton.onPressed, isNull);
    expect(fullscreenButton.tooltip, 'Loading next episode...');
  });

  testWidgets('fullscreen controls expose the external player action', (
    tester,
  ) async {
    var tapped = 0;

    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: () => tapped++,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byTooltip('External player'));
    expect(tapped, 1);
  });

  testWidgets(
      'fullscreen external player action can show an unavailable reason',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: null,
          externalPlayerTooltip:
              'This stream needs request headers, so it cannot be opened in an external player yet.',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    expect(
      find.byTooltip(
        'This stream needs request headers, so it cannot be opened in an external player yet.',
      ),
      findsOneWidget,
    );
    final externalPlayerButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.open_in_new),
    );
    expect(externalPlayerButton.onPressed, isNull);
  });

  testWidgets('fullscreen external player action shows a busy opening state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: null,
          externalPlayerTooltip: 'Opening external player...',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: true,
        ),
      ),
    );

    await tester.pump();

    final externalPlayerButton =
        tester.widgetList<IconButton>(find.byType(IconButton)).singleWhere(
              (button) =>
                  button.tooltip == 'Opening external player...' &&
                  button.icon is SizedBox,
            );
    expect(externalPlayerButton.onPressed, isNull);
    expect(externalPlayerButton.tooltip, 'Opening external player...');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Opening external player...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Opening external player...');

    final nextEpisodeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.skip_next),
    );
    expect(nextEpisodeButton.onPressed, isNull);
    expect(nextEpisodeButton.tooltip, 'Opening external player...');

    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(downloadButton.onPressed, isNull);
    expect(downloadButton.tooltip, 'Opening external player...');

    final fullscreenButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.fullscreen_exit),
    );
    expect(fullscreenButton.onPressed, isNull);
    expect(fullscreenButton.tooltip, 'Opening external player...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('fullscreen toggle tooltip reflects the current fullscreen state',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Exit fullscreen'), findsOneWidget);
    expect(find.byTooltip('Enter fullscreen'), findsNothing);
  });

  testWidgets('controls show hour-aware playback timestamps for long videos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state.copyWith(
            position: const Duration(hours: 1, minutes: 5, seconds: 9),
            duration: const Duration(hours: 2, minutes: 3, seconds: 4),
          ),
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('1:05:09 / 2:03:04'), findsOneWidget);
  });

  testWidgets(
      'controls disable playback actions when no playable source exists',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          hasPlayableSource: false,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(
      playButton.tooltip,
      'No playable source found. Try another source or retry later.',
    );

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(
      speedButton.tooltip,
      'No playable source found. Try another source or retry later.',
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('controls stay disabled while playback is still preparing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: PlayerState.initial(),
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(playButton.tooltip, 'Preparing playback...');

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(speedButton.tooltip, 'Preparing playback...');

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('controls stay disabled after playback load fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: PlayerState.initial().copyWith(
            errorMessage:
                'Playback temporarily failed. Retry later or try another playback line.',
          ),
          hasPlayableSource: true,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          externalPlayerTooltip: 'External player',
          downloadTooltip: 'Download',
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: false,
          isOpeningExternalPlayer: false,
        ),
      ),
    );

    await tester.pump();

    final playButton = tester.widget<IconButton>(find.byType(IconButton).first);
    expect(playButton.onPressed, isNull);
    expect(
      playButton.tooltip,
      'Playback temporarily failed. Retry later or try another playback line.',
    );

    final speedButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.speed),
    );
    expect(speedButton.onPressed, isNull);
    expect(
      speedButton.tooltip,
      'Playback temporarily failed. Retry later or try another playback line.',
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });
}

Widget _buildApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: home),
  );
}

void _noop() {}

const _state = PlayerState(
  isInitialized: true,
  isPlaying: false,
  isBuffering: false,
  position: Duration(minutes: 3),
  duration: Duration(minutes: 24),
  speed: 1,
);
