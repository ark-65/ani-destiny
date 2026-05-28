import 'dart:async';

import 'package:media_kit/media_kit.dart' as media;

import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/entities/player_state.dart';

class MediaKitPlayerAdapter implements PlayerControllerAdapter {
  MediaKitPlayerAdapter() {
    _emit(_state);
  }

  final media.Player _player = media.Player();
  final _controller = StreamController<PlayerState>.broadcast();
  PlayerState _state = PlayerState.initial();

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> load(String url) async {
    _state = _state.copyWith(isBuffering: true);
    _emit(_state);
    await _player.open(media.Media(url), play: false);
    _state = _state.copyWith(
      isInitialized: true,
      isBuffering: false,
    );
    _emit(_state);
  }

  @override
  Future<void> play() async {
    await _player.play();
    _state = _state.copyWith(isPlaying: true);
    _emit(_state);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _state = _state.copyWith(isPlaying: false);
    _emit(_state);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _state = _state.copyWith(position: position);
    _emit(_state);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
    _state = _state.copyWith(speed: speed);
    _emit(_state);
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _controller.close();
  }

  void _emit(PlayerState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }
}
