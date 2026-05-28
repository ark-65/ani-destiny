import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/source_providers.dart';
import '../widgets/source_selector.dart';

class SourceSettingsPage extends ConsumerWidget {
  const SourceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourceListProvider);
    final currentSource = ref.watch(currentSourceIdProvider);

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
                  context.l10n.sources,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: currentSource.when(
                loading: () =>
                    AppLoadingView(message: context.l10n.loadingCurrentSource),
                error: (error, stackTrace) =>
                    AppErrorView(message: error.toString()),
                data: (currentSourceId) => ListView(
                  children: [
                    SourceSelector(
                      sources: sources,
                      currentSourceId: currentSourceId,
                      onSelected: (sourceId) async {
                        await ref
                            .read(currentSourceIdProvider.notifier)
                            .setSource(sourceId);
                        ref.invalidate(homeRecommendationsProvider);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n.sourceSetTo(
                                context.l10n.sourceDisplayName(
                                  sourceId,
                                  sourceId,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.sourceV1Note,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
