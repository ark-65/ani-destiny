class PlayerState {
  const PlayerState({
    required this.isInitialized,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.speed,
    this.errorMessage,
  });

  factory PlayerState.initial() {
    return const PlayerState(
      isInitialized: false,
      isPlaying: false,
      isBuffering: false,
      position: Duration.zero,
      duration: Duration(minutes: 24),
      speed: 1,
    );
  }

  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? errorMessage;

  PlayerState copyWith({
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PlayerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
