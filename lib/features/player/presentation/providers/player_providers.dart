import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/adapters/media_kit_player_adapter.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../../domain/repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return const PlayerRepositoryImpl(
    controllerFactory: MediaKitPlayerAdapter.new,
  );
});
