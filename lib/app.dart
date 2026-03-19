import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'di/providers.dart';
import 'routing/app_router.dart';
import 'services/posthog_client.dart';
import 'services/storage_service.dart';
import 'state/actions_state.dart';
import 'state/alerts_state.dart';
import 'state/annotations_state.dart';
import 'state/cohorts_state.dart';
import 'state/dashboard_state.dart';
import 'state/data_management_state.dart';
import 'state/early_access_state.dart';
import 'state/error_tracking_state.dart';
import 'state/events_state.dart';
import 'state/experiments_state.dart';
import 'state/flags_state.dart';
import 'state/groups_state.dart';
import 'state/insights_state.dart';
import 'state/llm_analytics_state.dart';
import 'state/logs_state.dart';
import 'state/persons_state.dart';
import 'state/product_tours_state.dart';
import 'state/recordings_state.dart';
import 'state/revenue_analytics_state.dart';
import 'state/sql_editor_state.dart';
import 'state/surveys_state.dart';
import 'state/web_analytics_state.dart';

class HogletApp extends StatefulWidget {
  const HogletApp({super.key});

  @override
  State<HogletApp> createState() => _HogletAppState();
}

class _HogletAppState extends State<HogletApp> {
  ThemeMode _themeMode = ThemeMode.light;
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
  late final ErrorTrackingState _errorTrackingState;
  late final AlertsState _alertsState;
  late final WebAnalyticsState _webAnalyticsState;
  late final RecordingsState _recordingsState;
  late final AnnotationsState _annotationsState;
  late final SqlEditorState _sqlEditorState;
  late final ActionsState _actionsState;
  late final DataManagementState _dataManagementState;
  late final GroupsState _groupsState;
  late final EarlyAccessState _earlyAccessState;
  late final ProductToursState _productToursState;
  late final LogsState _logsState;
  late final LlmAnalyticsState _llmAnalyticsState;
  late final RevenueAnalyticsState _revenueAnalyticsState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _client = PosthogClient();
    _storage = StorageService();
    _router = createAppRouter(_storage);
    _dashboardState = DashboardState();
    _insightsState = InsightsState();
    _flagsState = FlagsState();
    _eventsState = EventsState();
    _personsState = PersonsState();
    _cohortsState = CohortsState();
    _experimentsState = ExperimentsState();
    _surveysState = SurveysState();
    _errorTrackingState = ErrorTrackingState();
    _alertsState = AlertsState();
    _webAnalyticsState = WebAnalyticsState();
    _recordingsState = RecordingsState();
    _annotationsState = AnnotationsState();
    _sqlEditorState = SqlEditorState();
    _actionsState = ActionsState();
    _dataManagementState = DataManagementState();
    _groupsState = GroupsState();
    _earlyAccessState = EarlyAccessState();
    _productToursState = ProductToursState();
    _logsState = LogsState();
    _llmAnalyticsState = LlmAnalyticsState();
    _revenueAnalyticsState = RevenueAnalyticsState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await _storage.read('theme_mode') == 'dark';
    if (mounted) setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    _storage.write('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
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
    _errorTrackingState.dispose();
    _alertsState.dispose();
    _webAnalyticsState.dispose();
    _recordingsState.dispose();
    _annotationsState.dispose();
    _sqlEditorState.dispose();
    _actionsState.dispose();
    _dataManagementState.dispose();
    _groupsState.dispose();
    _earlyAccessState.dispose();
    _productToursState.dispose();
    _logsState.dispose();
    _llmAnalyticsState.dispose();
    _revenueAnalyticsState.dispose();
    _router.dispose();
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
      errorTrackingState: _errorTrackingState,
      alertsState: _alertsState,
      webAnalyticsState: _webAnalyticsState,
      recordingsState: _recordingsState,
      annotationsState: _annotationsState,
      sqlEditorState: _sqlEditorState,
      actionsState: _actionsState,
      dataManagementState: _dataManagementState,
      groupsState: _groupsState,
      earlyAccessState: _earlyAccessState,
      productToursState: _productToursState,
      logsState: _logsState,
      llmAnalyticsState: _llmAnalyticsState,
      revenueAnalyticsState: _revenueAnalyticsState,
      themeMode: _themeMode,
      onToggleTheme: toggleTheme,
      child: MaterialApp.router(
        title: 'Hoglet',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _themeMode,
        routerConfig: _router,
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
      cardTheme: const CardThemeData(color: Colors.white),
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

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFFF15A24);
    const background = Color(0xFF1C1B19);
    const surface = Color(0xFF252420);
    const textPrimary = Color(0xFFE3DED6);
    const textSecondary = Color(0xFF9B9588);
    const border = Color(0xFF3A3834);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        surface: background,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).apply(
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
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
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
