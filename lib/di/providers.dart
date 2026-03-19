import 'package:flutter/material.dart';

import '../services/posthog_client.dart';
import '../services/storage_service.dart';
import '../state/actions_state.dart';
import '../state/alerts_state.dart';
import '../state/annotations_state.dart';
import '../state/cohorts_state.dart';
import '../state/dashboard_state.dart';
import '../state/data_management_state.dart';
import '../state/early_access_state.dart';
import '../state/error_tracking_state.dart';
import '../state/events_state.dart';
import '../state/experiments_state.dart';
import '../state/flags_state.dart';
import '../state/groups_state.dart';
import '../state/insights_state.dart';
import '../state/llm_analytics_state.dart';
import '../state/logs_state.dart';
import '../state/persons_state.dart';
import '../state/product_tours_state.dart';
import '../state/recordings_state.dart';
import '../state/revenue_analytics_state.dart';
import '../state/sql_editor_state.dart';
import '../state/surveys_state.dart';
import '../state/web_analytics_state.dart';

class AppProviders extends InheritedWidget {
  final PosthogClient client;
  final StorageService storage;
  final DashboardState dashboardState;
  final InsightsState insightsState;
  final FlagsState flagsState;
  final EventsState eventsState;
  final PersonsState personsState;
  final CohortsState cohortsState;
  final ExperimentsState experimentsState;
  final SurveysState surveysState;
  final ErrorTrackingState errorTrackingState;
  final AlertsState alertsState;
  final WebAnalyticsState webAnalyticsState;
  final RecordingsState recordingsState;
  final AnnotationsState annotationsState;
  final SqlEditorState sqlEditorState;
  final ActionsState actionsState;
  final DataManagementState dataManagementState;
  final GroupsState groupsState;
  final EarlyAccessState earlyAccessState;
  final ProductToursState productToursState;
  final LogsState logsState;
  final LlmAnalyticsState llmAnalyticsState;
  final RevenueAnalyticsState revenueAnalyticsState;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const AppProviders({
    super.key,
    required this.client,
    required this.storage,
    required this.dashboardState,
    required this.insightsState,
    required this.flagsState,
    required this.eventsState,
    required this.personsState,
    required this.cohortsState,
    required this.experimentsState,
    required this.surveysState,
    required this.errorTrackingState,
    required this.alertsState,
    required this.webAnalyticsState,
    required this.recordingsState,
    required this.annotationsState,
    required this.sqlEditorState,
    required this.actionsState,
    required this.dataManagementState,
    required this.groupsState,
    required this.earlyAccessState,
    required this.productToursState,
    required this.logsState,
    required this.llmAnalyticsState,
    required this.revenueAnalyticsState,
    required this.themeMode,
    required this.onToggleTheme,
    required super.child,
  });

  static AppProviders of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppProviders>();
    assert(result != null, 'No AppProviders found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppProviders oldWidget) =>
      client != oldWidget.client || storage != oldWidget.storage;
}
