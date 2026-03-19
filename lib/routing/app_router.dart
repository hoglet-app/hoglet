import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/flags/flag_detail_screen.dart';
import '../screens/flags/flags_list_screen.dart';
import '../screens/home/dashboard_detail_screen.dart';
import '../screens/home/dashboard_list_screen.dart';
import '../screens/insights/insight_detail_screen.dart';
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
        // Home tab — Dashboards
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: RoutePaths.home,
              name: RouteNames.home,
              builder: (context, state) => const DashboardListScreen(),
              routes: [
                GoRoute(
                  path: RoutePaths.dashboardDetail,
                  name: RouteNames.dashboardDetail,
                  builder: (context, state) => DashboardDetailScreen(
                    dashboardId: state.pathParameters['dashboardId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: RoutePaths.insightDetail,
                      name: RouteNames.insightDetail,
                      builder: (context, state) => InsightDetailScreen(
                        insightId: state.pathParameters['insightId']!,
                      ),
                    ),
                  ],
                ),
              ],
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
              builder: (context, state) => const FlagsListScreen(),
              routes: [
                GoRoute(
                  path: RoutePaths.flagDetail,
                  name: RouteNames.flagDetail,
                  builder: (context, state) => FlagDetailScreen(
                    flagId: state.pathParameters['flagId']!,
                  ),
                ),
              ],
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
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
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
