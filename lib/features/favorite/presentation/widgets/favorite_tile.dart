import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/favorite_anime.dart';

class FavoriteTile extends StatelessWidget {
  const FavoriteTile({
    required this.favorite,
    required this.onOpen,
    required this.onRemove,
    super.key,
  });

  final FavoriteAnime favorite;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpen,
      leading: const CircleAvatar(child: Icon(Icons.favorite)),
      title: Text(favorite.title),
      subtitle: Text(
        context.l10n.sourceDisplayName(favorite.sourceId, favorite.sourceId),
      ),
      trailing: IconButton(
        tooltip: context.l10n.removeFavorite,
        onPressed: onRemove,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}
