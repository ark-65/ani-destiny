import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/adapters/media_kit_player_adapter.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/services/playback_diagnostics.dart';
import 'playback_buffering_providers.dart';

typedef ExternalPlayerLauncher = Future<bool> Function(Uri uri);

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final settings = ref.watch(playbackBufferingSettingsProvider);
  return PlayerRepositoryImpl(
    settings: settings,
    controllerFactory: (settings) => MediaKitPlayerAdapter(
      bufferSizeBytes: settings.bufferSizeBytes,
    ),
  );
});

final externalPlayerLauncherProvider = Provider<ExternalPlayerLauncher>((ref) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

final lastPlaybackDiagnosticsProvider =
    StateProvider<PlaybackDiagnostics?>((ref) => null);
