import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/anime_source.dart';

class SourceSelector extends StatelessWidget {
  const SourceSelector({
    required this.sources,
    required this.currentSourceId,
    required this.onSelected,
    super.key,
  });

  final List<AnimeSource> sources;
  final String currentSourceId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: currentSourceId,
      onChanged: (value) {
        if (value == null) return;
        onSelected(value);
      },
      child: Column(
        children: [
          for (final source in sources)
            RadioListTile<String>(
              value: source.id,
              title: Text(
                context.l10n.sourceDisplayName(source.id, source.name),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('id: ${source.id}'),
                  Text(
                    context.l10n.sourceDisplayDescription(
                      source.id,
                      source.description ?? source.id,
                    ),
                  ),
                  if (source.id == currentSourceId)
                    Text(context.l10n.sourceCurrent),
                  if (source.id == 'sakura')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            context.l10n.sourceExperimentalBadge,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              secondary: Icon(
                switch (source.id) {
                  'mock' => Icons.check_circle_outline,
                  'sakura' => Icons.science_outlined,
                  'remote-proxy' => Icons.cloud_queue_outlined,
                  _ => Icons.construction_outlined,
                },
              ),
            ),
        ],
      ),
    );
  }
}
