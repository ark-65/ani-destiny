import 'package:flutter/material.dart';

import '../../../anime/domain/entities/anime.dart';

class AnimeCard extends StatelessWidget {
  const AnimeCard({
    required this.anime,
    required this.onTap,
    super.key,
    this.imageAspectRatio = 0.78,
  });

  final Anime anime;
  final VoidCallback onTap;
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    final status = anime.status?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: imageAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CoverImage(url: anime.coverUrl),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x33000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.45, 0.72, 1],
                  ),
                ),
              ),
              if (status != null && status.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _StatusBadge(status: status),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  anime.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
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
      return _CoverFallback(
        icon: Icons.movie_filter_outlined,
        iconColor: colors.onSecondaryContainer,
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _CoverFallback(
          icon: Icons.broken_image_outlined,
          iconColor: colors.onSecondaryContainer,
        );
      },
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({
    required this.icon,
    required this.iconColor,
  });

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.secondaryContainer,
            colors.surfaceContainerHighest,
          ],
        ),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}
