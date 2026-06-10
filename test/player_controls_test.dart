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
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: () => tapped++,
          onOpenExternalPlayer: _noop,
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
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
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: false,
          isSwitchingEpisode: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Next episode'), findsNothing);
    expect(find.byTooltip('External player'), findsNothing);
    expect(find.byTooltip('Enter fullscreen'), findsOneWidget);
  });

  testWidgets('fullscreen next episode action shows busy state while switching',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: null,
          onOpenExternalPlayer: _noop,
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: true,
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('fullscreen controls expose the external player action', (
    tester,
  ) async {
    var tapped = 0;

    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: () => tapped++,
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byTooltip('External player'));
    expect(tapped, 1);
  });

  testWidgets('fullscreen toggle tooltip reflects the current fullscreen state',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        PlayerControls(
          state: _state,
          onPlayPause: _noop,
          onSeek: (_) {},
          onSpeed: _noop,
          onNextEpisode: _noop,
          onOpenExternalPlayer: _noop,
          onDownload: _noop,
          onToggleDanmaku: _noop,
          onToggleFullscreen: _noop,
          danmakuEnabled: true,
          isFullscreen: true,
          isSwitchingEpisode: false,
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Exit fullscreen'), findsOneWidget);
    expect(find.byTooltip('Enter fullscreen'), findsNothing);
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
