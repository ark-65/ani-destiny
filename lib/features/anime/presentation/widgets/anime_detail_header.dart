import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/anime_detail.dart';

class AnimeDetailHeader extends StatelessWidget {
  const AnimeDetailHeader({
    required this.detail,
    required this.isFavorite,
    required this.onToggleFavorite,
    super.key,
  });

  final AnimeDetail detail;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 116,
            height: 164,
            child: detail.coverUrl == null
                ? const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.movie_outlined),
                  )
                : Image.network(
                    detail.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.movie_outlined),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (detail.aliases.isNotEmpty)
                Text(
                  detail.aliases.join(' / '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in detail.tags)
                    Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_outline,
                ),
                label: Text(
                  isFavorite ? context.l10n.favorited : context.l10n.favorite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
