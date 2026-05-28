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
                  message: error.toString(),
                  onRetry: () => ref.invalidate(scheduleProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyView(message: context.l10n.noScheduleData);
                  }
                  final grouped = items.groupListsBy((item) => item.weekday);
                  final weekdays = grouped.keys.toList()..sort();
                  return ListView.builder(
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
                              subtitle: Text(item.updateTime ?? item.sourceId),
                              leading: const Icon(Icons.event_available),
                              onTap: () =>
                                  context.push('/anime/${item.animeId}'),
                            ),
                        ],
                      );
                    },
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
