import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/onboarding/welcome_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/app_shell.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _activityNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'activity');
final _flagsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'flags');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RoutePaths.welcome,
  routes: [
    GoRoute(
      path: RoutePaths.welcome,
      name: RouteNames.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // Home tab
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: RoutePaths.home,
              name: RouteNames.home,
              builder: (context, state) =>
                  const _PlaceholderScreen(title: 'Dashboards', icon: Icons.dashboard),
            ),
          ],
        ),
        // Activity tab
        StatefulShellBranch(
          navigatorKey: _activityNavigatorKey,
          routes: [
            GoRoute(
              path: RoutePaths.activity,
              name: RouteNames.activity,
              builder: (context, state) =>
                  const _PlaceholderScreen(title: 'Activity', icon: Icons.bolt),
            ),
          ],
        ),
        // Flags tab
        StatefulShellBranch(
          navigatorKey: _flagsNavigatorKey,
          routes: [
            GoRoute(
              path: RoutePaths.flags,
              name: RouteNames.flags,
              builder: (context, state) =>
                  const _PlaceholderScreen(title: 'Feature Flags', icon: Icons.flag),
            ),
          ],
        ),
        // Settings tab
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              name: RouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Temporary placeholder for tabs that will be implemented in later phases.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in a future phase',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
