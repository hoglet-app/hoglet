import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/activity/activity_screen.dart';
import '../screens/cohorts/cohort_detail_screen.dart';
import '../screens/cohorts/cohorts_list_screen.dart';
import '../screens/insights/insights_list_screen.dart';
import '../screens/flags/flag_detail_screen.dart';
import '../screens/flags/flags_list_screen.dart';
import '../screens/home/dashboard_detail_screen.dart';
import '../screens/home/dashboard_list_screen.dart';
import '../screens/insights/insight_detail_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/persons/person_detail_screen.dart';
import '../screens/persons/persons_list_screen.dart';
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
              builder: (context, state) => const ActivityScreen(),
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
    // Drawer routes (full-screen, outside shell)
    GoRoute(
      path: RoutePaths.insights,
      name: RouteNames.insights,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const InsightsListScreen(),
      routes: [
        GoRoute(
          path: ':insightId',
          builder: (context, state) => InsightDetailScreen(
            insightId: state.pathParameters['insightId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.persons,
      name: RouteNames.persons,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PersonsListScreen(),
      routes: [
        GoRoute(
          path: RoutePaths.personDetail,
          name: RouteNames.personDetail,
          builder: (context, state) => PersonDetailScreen(
            personId: state.pathParameters['personId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.cohorts,
      name: RouteNames.cohorts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CohortsListScreen(),
      routes: [
        GoRoute(
          path: RoutePaths.cohortDetail,
          name: RouteNames.cohortDetail,
          builder: (context, state) => CohortDetailScreen(
            cohortId: state.pathParameters['cohortId']!,
          ),
        ),
      ],
    ),
  ],
);

