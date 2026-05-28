import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/repositories/player_repository.dart';
import '../adapters/mock_player_adapter.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl({
    PlayerControllerAdapter Function()? controllerFactory,
  }) : _controllerFactory = controllerFactory;

  final PlayerControllerAdapter Function()? _controllerFactory;

  @override
  PlayerControllerAdapter createController() {
    return _controllerFactory?.call() ?? MockPlayerAdapter();
  }
}
