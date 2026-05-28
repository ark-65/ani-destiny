import 'dart:async';

import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/entities/player_state.dart';

class MockPlayerAdapter implements PlayerControllerAdapter {
  MockPlayerAdapter() {
    _emit(_state);
  }

  final _controller = StreamController<PlayerState>.broadcast();
  Timer? _timer;
  PlayerState _state = PlayerState.initial();

  @override
  Stream<PlayerState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    _state = PlayerState.initial().copyWith(
      isInitialized: true,
      duration: const Duration(minutes: 24, seconds: 12),
    );
    _emit(_state);
  }

  @override
  Future<void> play() async {
    _state = _state.copyWith(isPlaying: true);
    _emit(_state);
    _timer ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_state.isPlaying) return;
      final nextPosition = _state.position +
          Duration(
            milliseconds: (500 * _state.speed).round(),
          );
      _state = _state.copyWith(
        position:
            nextPosition > _state.duration ? _state.duration : nextPosition,
        isPlaying: nextPosition < _state.duration,
      );
      _emit(_state);
    });
  }

  @override
  Future<void> pause() async {
    _state = _state.copyWith(isPlaying: false);
    _emit(_state);
  }

  @override
  Future<void> seek(Duration position) async {
    _state = _state.copyWith(
      position: position < Duration.zero ? Duration.zero : position,
    );
    _emit(_state);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _state = _state.copyWith(speed: speed);
    _emit(_state);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
  }

  void _emit(PlayerState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }
}
