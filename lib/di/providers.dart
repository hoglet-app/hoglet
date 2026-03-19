import 'package:disco/disco.dart';

import '../services/posthog_client.dart';
import '../services/storage_service.dart';
import '../state/dashboard_state.dart';
import '../state/events_state.dart';
import '../state/flags_state.dart';
import '../state/insights_state.dart';

/// Global provider identities used throughout the app.
/// These are registered once in the root [ProviderScope] in app.dart.
///
/// Note: Disco providers in the same scope cannot reference each other
/// via .of(context) in their creation functions (the context is above
/// the InheritedProvider in the tree). So we create instances explicitly
/// in app.dart and use simple providers that return pre-built values.

final posthogClientProvider = Provider<PosthogClient>(
  (_) => PosthogClient(),
);

final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);

// State providers need references to services, so they are created
// with explicit instances passed from app.dart rather than looking
// up sibling providers via context.

late final Provider<DashboardState> dashboardStateProvider;
late final Provider<InsightsState> insightsStateProvider;
late final Provider<FlagsState> flagsStateProvider;
late final Provider<EventsState> eventsStateProvider;

/// Initialize state providers with pre-built instances.
/// Must be called before building the ProviderScope.
void initStateProviders({
  required PosthogClient client,
  required StorageService storage,
}) {
  dashboardStateProvider = Provider<DashboardState>(
    (_) => DashboardState(client: client),
    dispose: (state) => state.dispose(),
  );
  insightsStateProvider = Provider<InsightsState>(
    (_) => InsightsState(client: client),
    dispose: (state) => state.dispose(),
  );
  flagsStateProvider = Provider<FlagsState>(
    (_) => FlagsState(client: client),
    dispose: (state) => state.dispose(),
  );
  eventsStateProvider = Provider<EventsState>(
    (_) => EventsState(client: client, storage: storage),
    dispose: (state) => state.dispose(),
  );
}
