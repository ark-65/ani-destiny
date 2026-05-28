import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../providers/favorite_providers.dart';
import '../widgets/favorite_tile.dart';

class FavoritePage extends ConsumerWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteListProvider);

    return SafeArea(
      child: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.favorites,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: favorites.when(
                loading: () =>
                    AppLoadingView(message: context.l10n.loadingFavorites),
                error: (error, stackTrace) => AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(favoriteListProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyView(
                      message: context.l10n.favoriteEmpty,
                      icon: Icons.favorite_outline,
                    );
                  }
                  return ListView.separated(
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FavoriteTile(
                        favorite: item,
                        onOpen: () => context.push('/anime/${item.animeId}'),
                        onRemove: () => ref
                            .read(favoriteRepositoryProvider)
                            .remove(item.animeId),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
