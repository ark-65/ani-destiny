import 'package:ani_destiny/core/storage/preferences_provider.dart';
import 'package:ani_destiny/features/player/domain/entities/playback_buffering_settings.dart';
import 'package:ani_destiny/features/player/presentation/providers/playback_buffering_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('default playback buffering keeps media_kit default buffer size', () {
    const settings = PlaybackBufferingSettings.defaults();

    expect(settings.forceAheadBuffering, isFalse);
    expect(
      settings.bufferSizeBytes,
      PlaybackBufferingSettings.defaultBufferSizeBytes,
    );
  });

  test('force-ahead playback buffering maps to the larger buffer size', () {
    const settings = PlaybackBufferingSettings(
      forceAheadBuffering: true,
    );

    expect(
      settings.bufferSizeBytes,
      PlaybackBufferingSettings.forceAheadBufferSizeBytes,
    );
  });

  test('provider defaults force-ahead playback buffering to disabled',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(playbackBufferingSettingsProvider).forceAheadBuffering,
      isFalse,
    );

    await container.read(sharedPreferencesProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(playbackBufferingSettingsProvider).forceAheadBuffering,
      isFalse,
    );
  });

  test('provider restores persisted force-ahead playback buffering', () async {
    SharedPreferences.setMockInitialValues({
      PlaybackBufferingSettingsController.forceAheadBufferingKey: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(playbackBufferingSettingsProvider);
    await container.read(sharedPreferencesProvider.future);
    await Future<void>.delayed(Duration.zero);

    final settings = container.read(playbackBufferingSettingsProvider);
    expect(settings.forceAheadBuffering, isTrue);
    expect(
      settings.bufferSizeBytes,
      PlaybackBufferingSettings.forceAheadBufferSizeBytes,
    );
  });

  test('controller persists force-ahead playback buffering changes', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(playbackBufferingSettingsProvider.notifier)
        .setForceAheadBuffering(true);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        PlaybackBufferingSettingsController.forceAheadBufferingKey,
      ),
      isTrue,
    );
    expect(
      container.read(playbackBufferingSettingsProvider).forceAheadBuffering,
      isTrue,
    );
  });
}
