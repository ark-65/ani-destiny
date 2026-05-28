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
              subtitle: Text(
                context.l10n.sourceDisplayDescription(
                  source.id,
                  source.description ?? source.id,
                ),
              ),
              secondary: Icon(
                source.id == 'mock'
                    ? Icons.check_circle_outline
                    : Icons.construction_outlined,
              ),
            ),
        ],
      ),
    );
  }
}
