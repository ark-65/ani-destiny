import '../adapters/player_controller_adapter.dart';

abstract class PlayerRepository {
  PlayerControllerAdapter createController();
}
