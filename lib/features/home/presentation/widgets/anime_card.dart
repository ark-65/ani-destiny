import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../anime/domain/entities/anime.dart';

class AnimeCard extends StatelessWidget {
  const AnimeCard({
    required this.anime,
    required this.onTap,
    super.key,
  });

  final Anime anime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: _CoverImage(url: anime.coverUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    anime.description ?? context.l10n.noDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in anime.tags.take(3))
                        Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (url == null || url!.isEmpty) {
      return ColoredBox(
        color: colors.secondaryContainer,
        child: Icon(
          Icons.movie_filter_outlined,
          color: colors.onSecondaryContainer,
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: colors.secondaryContainer,
          child: Icon(
            Icons.broken_image_outlined,
            color: colors.onSecondaryContainer,
          ),
        );
      },
    );
  }
}
