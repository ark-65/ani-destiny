import '../../domain/adapters/player_controller_adapter.dart';
import '../../domain/entities/playback_buffering_settings.dart';
import '../../domain/repositories/player_repository.dart';
import '../adapters/mock_player_adapter.dart';

typedef PlayerControllerFactory = PlayerControllerAdapter Function(
  PlaybackBufferingSettings settings,
);

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl({
    PlaybackBufferingSettings settings =
        const PlaybackBufferingSettings.defaults(),
    PlayerControllerFactory? controllerFactory,
  })  : _settings = settings,
        _controllerFactory = controllerFactory;

  final PlaybackBufferingSettings _settings;
  final PlayerControllerFactory? _controllerFactory;

  @override
  PlayerControllerAdapter createController() {
    return _controllerFactory?.call(_settings) ?? MockPlayerAdapter();
  }
}
