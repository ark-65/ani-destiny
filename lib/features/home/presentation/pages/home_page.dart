import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../source/presentation/providers/source_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/anime_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(homeRecommendationsProvider);
    final currentSource = ref.watch(currentSourceAdapterProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeRecommendationsProvider);
          await ref.read(homeRecommendationsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AdaptivePage(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.appName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              currentSource.when(
                                data: (source) => Text(
                                  context.l10n.sourceName(
                                    context.l10n.sourceDisplayName(
                                      source.id,
                                      source.name,
                                    ),
                                  ),
                                ),
                                loading: () => Text(context.l10n.sourceLoading),
                                error: (_, __) =>
                                    Text(context.l10n.sourceUnknown),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: context.l10n.schedule,
                          onPressed: () => context.push('/schedule'),
                          icon: const Icon(Icons.calendar_month_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.l10n.recommendations,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            recommendations.when(
              loading: () => SliverFillRemaining(
                child: AppLoadingView(message: context.l10n.loadingAnime),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                child: AppErrorView(
                  message:
                      '${context.l10n.sourceTemporarilyUnavailable}\n'
                      '${context.l10n.sourceUnavailableSuggestion}',
                  onRetry: () => ref.invalidate(homeRecommendationsProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: AppEmptyView(
                      message: context.l10n.sourceUnavailableSuggestion,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.64,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final anime = items[index];
                      return AnimeCard(
                        anime: anime,
                        onTap: () => context.push('/anime/${anime.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
