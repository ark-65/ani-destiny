import 'dart:async';

import 'package:ani_destiny/app/l10n/app_localizations.dart';
import 'package:ani_destiny/features/player/domain/adapters/player_controller_adapter.dart';
import 'package:ani_destiny/features/player/domain/entities/player_state.dart';
import 'package:ani_destiny/features/player/presentation/widgets/player_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PlayerSurface uses neutral ready copy for fallback preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [AppLocalizations.delegate],
        home: Scaffold(
          body: PlayerSurface(
            controller: _FakePlayerControllerAdapter(),
            title: 'Episode 1',
            playUrl: 'https://cdn.example.test/video.m3u8',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Playback preview ready'), findsOneWidget);
    expect(find.textContaining('Mock'), findsNothing);
    expect(find.textContaining('mock'), findsNothing);
  });
}

class _FakePlayerControllerAdapter implements PlayerControllerAdapter {
  const _FakePlayerControllerAdapter();

  @override
  Stream<PlayerState> get stateStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}
}
