import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'di/providers.dart';
import 'routing/app_router.dart';
import 'services/posthog_client.dart';
import 'services/storage_service.dart';
import 'state/cohorts_state.dart';
import 'state/dashboard_state.dart';
import 'state/events_state.dart';
import 'state/experiments_state.dart';
import 'state/flags_state.dart';
import 'state/insights_state.dart';
import 'state/persons_state.dart';
import 'state/surveys_state.dart';

class HogletApp extends StatefulWidget {
  const HogletApp({super.key});

  @override
  State<HogletApp> createState() => _HogletAppState();
}

class _HogletAppState extends State<HogletApp> {
  late final PosthogClient _client;
  late final StorageService _storage;
  late final DashboardState _dashboardState;
  late final InsightsState _insightsState;
  late final FlagsState _flagsState;
  late final EventsState _eventsState;
  late final PersonsState _personsState;
  late final CohortsState _cohortsState;
  late final ExperimentsState _experimentsState;
  late final SurveysState _surveysState;

  @override
  void initState() {
    super.initState();
    _client = PosthogClient();
    _storage = StorageService();
    _dashboardState = DashboardState();
    _insightsState = InsightsState();
    _flagsState = FlagsState();
    _eventsState = EventsState();
    _personsState = PersonsState();
    _cohortsState = CohortsState();
    _experimentsState = ExperimentsState();
    _surveysState = SurveysState();
  }

  @override
  void dispose() {
    _dashboardState.dispose();
    _insightsState.dispose();
    _flagsState.dispose();
    _eventsState.dispose();
    _personsState.dispose();
    _cohortsState.dispose();
    _experimentsState.dispose();
    _surveysState.dispose();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      client: _client,
      storage: _storage,
      dashboardState: _dashboardState,
      insightsState: _insightsState,
      flagsState: _flagsState,
      eventsState: _eventsState,
      personsState: _personsState,
      cohortsState: _cohortsState,
      experimentsState: _experimentsState,
      surveysState: _surveysState,
      child: MaterialApp.router(
        title: 'Hoglet',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: appRouter,
      ),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFFF15A24);
    const background = Color(0xFFF5F4EF);
    const textPrimary = Color(0xFF1C1B19);
    const textSecondary = Color(0xFF6F6A63);
    const border = Color(0xFFE3DED6);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: background,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.spaceGrotesk(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
