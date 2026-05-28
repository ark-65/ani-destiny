import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/database_provider.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/watch_history.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.watch(appDatabaseProvider));
});

final watchHistoryProvider =
    StreamProvider.autoDispose<List<WatchHistory>>((ref) {
  return ref.watch(historyRepositoryProvider).watchHistory();
});
