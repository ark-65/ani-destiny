import 'dart:async';

import 'package:media_kit/media_kit.dart' as media;
import 'package:media_kit_video/media_kit_video.dart' as video;

import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/entities/player_state.dart';

class MediaKitPlayerAdapter implements PlayerControllerAdapter {
  MediaKitPlayerAdapter() {
    videoController = video.VideoController(_player);
    _subscriptions.addAll([
      _player.stream.playing.listen(
        (isPlaying) => _update(isPlaying: isPlaying, clearErrorMessage: true),
      ),
      _player.stream.buffering.listen(
        (isBuffering) => _update(isBuffering: isBuffering),
      ),
      _player.stream.position.listen(
        (position) => _update(position: position),
      ),
      _player.stream.duration.listen(
        (duration) => _update(duration: duration),
      ),
      _player.stream.rate.listen(
        (speed) => _update(speed: speed),
      ),
      _player.stream.error.listen(
        (message) => _update(
          isBuffering: false,
          isPlaying: false,
          errorMessage: message,
        ),
      ),
    ]);
    _emit(_state);
  }

  final media.Player _player = media.Player();
  final _controller = StreamController<PlayerState>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  PlayerState _state = PlayerState.initial();

  late final video.VideoController videoController;

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    try {
      _update(isBuffering: true, clearErrorMessage: true);
      await _player.open(
        media.Media(
          url,
          httpHeaders: headers.isEmpty ? null : headers,
        ),
        play: false,
      );
      _update(
        isInitialized: true,
        isBuffering: false,
        duration: _player.state.duration,
        position: _player.state.position,
        speed: _player.state.rate,
        clearErrorMessage: true,
      );
    } on Object catch (error) {
      _update(
        isBuffering: false,
        isPlaying: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    _update(isPlaying: true, clearErrorMessage: true);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _update(isPlaying: false);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _update(position: position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
    _update(speed: speed);
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _controller.close();
  }

  void _update({
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    _state = _state.copyWith(
      isInitialized: isInitialized,
      isPlaying: isPlaying,
      isBuffering: isBuffering,
      position: position,
      duration: duration,
      speed: speed,
      errorMessage: errorMessage,
      clearErrorMessage: clearErrorMessage,
    );
    _emit(_state);
  }

  void _emit(PlayerState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }
}
