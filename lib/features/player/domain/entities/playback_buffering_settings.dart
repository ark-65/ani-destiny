class PlaybackBufferingSettings {
  const PlaybackBufferingSettings({
    required this.forceAheadBuffering,
  });

  const PlaybackBufferingSettings.defaults() : forceAheadBuffering = false;

  static const defaultBufferSizeBytes = 32 * 1024 * 1024;
  static const forceAheadBufferSizeBytes = 256 * 1024 * 1024;

  final bool forceAheadBuffering;

  int get bufferSizeBytes =>
      forceAheadBuffering ? forceAheadBufferSizeBytes : defaultBufferSizeBytes;

  PlaybackBufferingSettings copyWith({
    bool? forceAheadBuffering,
  }) {
    return PlaybackBufferingSettings(
      forceAheadBuffering: forceAheadBuffering ?? this.forceAheadBuffering,
    );
  }
}
