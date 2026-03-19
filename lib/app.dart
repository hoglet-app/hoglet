import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'di/providers.dart';
import 'routing/app_router.dart';
import 'services/posthog_client.dart';
import 'services/storage_service.dart';
import 'state/dashboard_state.dart';
import 'state/events_state.dart';
import 'state/flags_state.dart';
import 'state/insights_state.dart';

class HogletApp extends StatefulWidget {
  const HogletApp({super.key});

  @override
  State<HogletApp> createState() => _HogletAppState();
}

class _HogletAppState extends State<HogletApp> {
  late final _router = createRouter(isAuthenticated: true);

  final _client = PosthogClient();
  final _storage = StorageService();
  late final _dashboardState = DashboardState(client: _client);
  late final _insightsState = InsightsState(client: _client);
  late final _flagsState = FlagsState(client: _client);
  late final _eventsState = EventsState(client: _client, storage: _storage);

  @override
  void dispose() {
    _dashboardState.dispose();
    _insightsState.dispose();
    _flagsState.dispose();
    _eventsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme();

    return AppProviders(
      client: _client,
      storage: _storage,
      dashboardState: _dashboardState,
      insightsState: _insightsState,
      flagsState: _flagsState,
      eventsState: _eventsState,
      child: MaterialApp.router(
        title: 'Hoglet',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF15A24),
            brightness: Brightness.light,
          ),
          textTheme: textTheme,
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
