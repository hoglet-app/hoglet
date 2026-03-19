import 'package:flutter/material.dart';

import '../services/posthog_client.dart';
import '../services/storage_service.dart';
import '../state/dashboard_state.dart';
import '../state/events_state.dart';
import '../state/flags_state.dart';
import '../state/insights_state.dart';

/// Simple DI container using InheritedWidget.
/// Access via `AppProviders.of(context)`.
class AppProviders extends InheritedWidget {
  const AppProviders({
    super.key,
    required this.client,
    required this.storage,
    required this.dashboardState,
    required this.insightsState,
    required this.flagsState,
    required this.eventsState,
    required super.child,
  });

  final PosthogClient client;
  final StorageService storage;
  final DashboardState dashboardState;
  final InsightsState insightsState;
  final FlagsState flagsState;
  final EventsState eventsState;

  static AppProviders of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppProviders>();
    assert(result != null, 'No AppProviders found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppProviders oldWidget) => false;
}
