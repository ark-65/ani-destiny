import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/preferences_provider.dart';
import '../../domain/entities/playback_buffering_settings.dart';

final playbackBufferingSettingsProvider = NotifierProvider<
    PlaybackBufferingSettingsController, PlaybackBufferingSettings>(
  PlaybackBufferingSettingsController.new,
);

class PlaybackBufferingSettingsController
    extends Notifier<PlaybackBufferingSettings> {
  static const forceAheadBufferingKey =
      'playback_force_ahead_buffering_enabled';

  bool _hasUserChanged = false;

  @override
  PlaybackBufferingSettings build() {
    unawaited(_load());
    return const PlaybackBufferingSettings.defaults();
  }

  Future<void> setForceAheadBuffering(bool enabled) async {
    _hasUserChanged = true;
    state = state.copyWith(forceAheadBuffering: enabled);
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setBool(forceAheadBufferingKey, enabled);
  }

  Future<void> _load() async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    if (_hasUserChanged) return;
    state = PlaybackBufferingSettings(
      forceAheadBuffering: preferences.getBool(forceAheadBufferingKey) ?? false,
    );
  }
}
