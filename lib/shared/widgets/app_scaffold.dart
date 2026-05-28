import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_navigation_bar.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showBottomNavigation = !location.startsWith('/player');

    return Scaffold(
      body: child,
      bottomNavigationBar:
          showBottomNavigation ? AppNavigationBar(location: location) : null,
    );
  }
}
