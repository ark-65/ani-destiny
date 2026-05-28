import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    required this.location,
    super.key,
  });

  final String location;

  int get _currentIndex {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/favorites')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
          case 1:
            context.go('/search');
          case 2:
            context.go('/favorites');
          case 3:
            context.go('/history');
          case 4:
            context.go('/settings');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: context.l10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: context.l10n.search,
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_outline),
          selectedIcon: const Icon(Icons.favorite),
          label: context.l10n.favorites,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: context.l10n.history,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: context.l10n.settings,
        ),
      ],
    );
  }
}
