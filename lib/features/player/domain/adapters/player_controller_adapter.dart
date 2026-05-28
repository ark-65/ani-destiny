import '../entities/player_state.dart';

abstract class PlayerControllerAdapter {
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> setSpeed(double speed);

  Stream<PlayerState> get stateStream;

  Future<void> dispose();
}
