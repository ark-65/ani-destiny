import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../providers/anime_providers.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);

    return SafeArea(
      child: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.schedule,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: schedule.when(
                loading: () =>
                    AppLoadingView(message: context.l10n.loadingSchedule),
                error: (error, stackTrace) => AppErrorView(
                  message: '${context.l10n.sourceTemporarilyUnavailable}\n'
                      '${context.l10n.sourceUnavailableSuggestion}',
                  onRetry: () => ref.invalidate(scheduleProvider),
                ),
                data: (result) {
                  final items = result.value;
                  if (items.isEmpty) {
                    return AppEmptyView(message: context.l10n.noScheduleData);
                  }
                  final grouped = items.groupListsBy((item) => item.weekday);
                  final weekdays = grouped.keys.toList()..sort();
                  return Column(
                    children: [
                      if (result.usedFallback)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FallbackNotice(
                            message: context.l10n.sourceFallbackNotice,
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: weekdays.length,
                          itemBuilder: (context, index) {
                            final weekday = weekdays[index];
                            final dayItems = grouped[weekday] ?? [];
                            return ExpansionTile(
                              initiallyExpanded: index == 0,
                              title: Text(_weekdayName(context, weekday)),
                              children: [
                                for (final item in dayItems)
                                  ListTile(
                                    title: Text(item.title),
                                    subtitle: Text(
                                      item.updateTime ??
                                          context.l10n.sourceDisplayName(
                                            item.sourceId,
                                            item.sourceId,
                                          ),
                                    ),
                                    leading: const Icon(Icons.event_available),
                                    onTap: () => context.push(
                                      '/anime/${item.animeId}?sourceId=${Uri.encodeQueryComponent(item.sourceId)}',
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayName(BuildContext context, int weekday) {
    return switch (weekday) {
      1 => context.l10n.monday,
      2 => context.l10n.tuesday,
      3 => context.l10n.wednesday,
      4 => context.l10n.thursday,
      5 => context.l10n.friday,
      6 => context.l10n.saturday,
      7 => context.l10n.sunday,
      _ => context.l10n.dayLabel(weekday),
    };
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.swap_horiz_outlined),
        title: Text(message),
        dense: true,
      ),
    );
  }
}
