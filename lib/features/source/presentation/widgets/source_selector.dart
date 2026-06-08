import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/anime_source.dart';
import '../../domain/entities/source_health.dart';

class SourceSelector extends StatelessWidget {
  const SourceSelector({
    required this.sources,
    required this.currentSourceId,
    required this.healthBySourceId,
    required this.onSelected,
    required this.onResetHealth,
    super.key,
  });

  final List<AnimeSource> sources;
  final String currentSourceId;
  final Map<String, SourceHealth> healthBySourceId;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onResetHealth;

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
            _SourceOption(
              source: source,
              currentSourceId: currentSourceId,
              health: healthBySourceId[source.id] ??
                  SourceHealth.initial(source.id),
              onResetHealth: onResetHealth,
            ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.source,
    required this.currentSourceId,
    required this.health,
    required this.onResetHealth,
  });

  final AnimeSource source;
  final String currentSourceId;
  final SourceHealth health;
  final ValueChanged<String> onResetHealth;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: source.id,
      title: Text(context.l10n.sourceDisplayName(source.id, source.name)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.sourceDisplayDescription(
              source.id,
              source.description ?? source.id,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HealthChip(health: health),
              Text(
                context.l10n.sourceFailureCount(health.failureCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (health.lastErrorMessage != null)
                Text(
                  context.l10n.sourceLastError(health.lastErrorMessage!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              TextButton(
                onPressed: () => onResetHealth(source.id),
                child: Text(context.l10n.sourceResetStatus),
              ),
            ],
          ),
          if (source.id == currentSourceId) Text(context.l10n.sourceCurrent),
          if (source.id == 'sakura')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    context.l10n.sourceDefaultBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.health});

  final SourceHealth health;

  @override
  Widget build(BuildContext context) {
    final (label, color, foreground) = switch (health.status) {
      SourceHealthStatus.healthy => (
          context.l10n.sourceHealthHealthy,
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      SourceHealthStatus.degraded => (
          context.l10n.sourceHealthDegraded,
          Theme.of(context).colorScheme.tertiaryContainer,
          Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      SourceHealthStatus.unavailable => (
          context.l10n.sourceHealthUnavailable,
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
              ),
        ),
      ),
    );
  }
}
