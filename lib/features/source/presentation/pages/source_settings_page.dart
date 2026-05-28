import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../shared/widgets/adaptive_page.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/source_diagnostic.dart';
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
                    ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text(context.l10n.sourceDiagnostics),
                      subtitle: Text(context.l10n.sourceDiagnosticsSubtitle),
                      trailing: const Icon(Icons.tune_outlined),
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (_) => const _SourceDiagnosticsSheet(),
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

class _SourceDiagnosticsSheet extends ConsumerWidget {
  const _SourceDiagnosticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref
        .watch(sourceDiagnosticsControllerProvider)
        .toList(growable: false)
        .reversed
        .take(20)
        .toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.sourceDiagnostics,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: diagnostics.isEmpty
                        ? null
                        : () => ref
                            .read(sourceDiagnosticsControllerProvider.notifier)
                            .clear(),
                    icon: const Icon(Icons.clear_all),
                    label: Text(context.l10n.sourceDiagnosticsClear),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: diagnostics.isEmpty
                    ? Center(child: Text(context.l10n.sourceDiagnosticsEmpty))
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          return _SourceDiagnosticTile(
                            diagnostic: diagnostics[index],
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: diagnostics.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceDiagnosticTile extends StatelessWidget {
  const _SourceDiagnosticTile({required this.diagnostic});

  final SourceDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnostic.level) {
      SourceDiagnosticLevel.info => Theme.of(context).colorScheme.primary,
      SourceDiagnosticLevel.warning => Theme.of(context).colorScheme.tertiary,
      SourceDiagnosticLevel.error => Theme.of(context).colorScheme.error,
    };
    final timestamp = diagnostic.timestamp;
    final details = [
      if (diagnostic.url != null) diagnostic.url!,
      if (diagnostic.statusCode != null) 'HTTP ${diagnostic.statusCode}',
      if (diagnostic.exceptionType != null) diagnostic.exceptionType!,
      if (timestamp != null)
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, color: color, size: 12),
      title: Text('${diagnostic.sourceId} · ${diagnostic.operation}'),
      subtitle: Text(
        [
          diagnostic.message,
          if (details.isNotEmpty) details.join(' · '),
        ].join('\n'),
      ),
    );
  }
}
