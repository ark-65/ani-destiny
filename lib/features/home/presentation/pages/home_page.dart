import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
                  message: '${context.l10n.sourceTemporarilyUnavailable}\n'
                      '${context.l10n.sourceUnavailableSuggestion}',
                  onRetry: () => ref.invalidate(homeRecommendationsProvider),
                ),
              ),
              data: (result) {
                final items = result.value;
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: AppEmptyView(
                      message: context.l10n.sourceUnavailableSuggestion,
                    ),
                  );
                }
                return SliverMainAxisGroup(
                  slivers: [
                    if (result.usedFallback)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: _FallbackNotice(
                            message: context.l10n.sourceFallbackNotice,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final columnCount = homeMasonryColumnCountForWidth(
                            constraints.crossAxisExtent,
                          );

                          return SliverMasonryGrid.count(
                            crossAxisCount: columnCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childCount: items.length,
                            itemBuilder: (context, index) {
                              final anime = items[index];
                              final sourceId =
                                  anime.sourceId ?? result.sourceId;
                              return AnimeCard(
                                anime: anime,
                                imageAspectRatio:
                                    homeAnimeTileAspectRatio(index),
                                onTap: () => context.push(
                                  '/anime/${anime.id}?sourceId=${Uri.encodeQueryComponent(sourceId)}',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
int homeMasonryColumnCountForWidth(double width) {
  if (width >= 1680) return 6;
  if (width >= 1360) return 5;
  if (width >= 1024) return 4;
  if (width >= 720) return 3;
  return 2;
}

@visibleForTesting
double homeAnimeTileAspectRatio(int index) {
  const ratios = <double>[
    1.18,
    0.82,
    0.62,
    1.06,
    0.74,
    1.30,
    0.92,
    0.68,
  ];
  return ratios[index % ratios.length];
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.swap_horiz_outlined,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
