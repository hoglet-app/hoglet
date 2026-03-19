import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/shell/app_shell.dart';
import '../screens/flags/flag_detail_screen.dart';
import '../screens/flags/flags_list_screen.dart';
import '../screens/home/dashboard_list_screen.dart';
import '../screens/home/dashboard_detail_screen.dart';
import '../screens/insights/insight_detail_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _activityNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'activity');
final _flagsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'flags');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

GoRouter createRouter({required bool isAuthenticated}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isAuthenticated ? RouteNames.home : RouteNames.welcome,
    routes: [
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const DashboardListScreen(),
                routes: [
                  GoRoute(
                    path: RouteNames.dashboardDetail,
                    builder: (context, state) {
                      final id =
                          int.parse(state.pathParameters['dashboardId']!);
                      return DashboardDetailScreen(dashboardId: id);
                    },
                    routes: [
                      GoRoute(
                        path: RouteNames.insightDetail,
                        builder: (context, state) {
                          final id =
                              int.parse(state.pathParameters['insightId']!);
                          return InsightDetailScreen(insightId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _activityNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.activity,
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _flagsNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.flags,
                builder: (context, state) => const FlagsListScreen(),
                routes: [
                  GoRoute(
                    path: RouteNames.flagDetail,
                    builder: (context, state) {
                      final id =
                          int.parse(state.pathParameters['flagId']!);
                      return FlagDetailScreen(flagId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
