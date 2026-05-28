import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/player_repository_impl.dart';
import '../../domain/repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return const PlayerRepositoryImpl();
});
