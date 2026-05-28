import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../providers/anime_providers.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_query));

    return SafeArea(
      child: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.search,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: context.l10n.search,
                  onPressed: () {
                    setState(() => _query = _controller.text);
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _query.trim().isEmpty
                  ? AppEmptyView(
                      message: context.l10n.searchEmpty,
                      icon: Icons.search,
                    )
                  : results.when(
                      loading: () =>
                          AppLoadingView(message: context.l10n.searching),
                      error: (error, stackTrace) => AppErrorView(
                        message:
                            '${context.l10n.sourceTemporarilyUnavailable}\n'
                            '${context.l10n.sourceUnavailableSuggestion}',
                        onRetry: () =>
                            ref.invalidate(searchResultsProvider(_query)),
                      ),
                      data: (result) {
                        final items = result.value;
                        if (items.isEmpty) {
                          return AppEmptyView(
                            message: context.l10n.noMatchingAnime,
                          );
                        }
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
                              child: ListView.separated(
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return SearchResultTile(
                                    result: item,
                                    onTap: () => context.push(
                                      '/anime/${item.animeId}?sourceId=${Uri.encodeQueryComponent(item.sourceId)}',
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemCount: items.length,
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
