import 'package:disco/disco.dart';

import '../services/posthog_client.dart';
import '../services/storage_service.dart';
import '../state/dashboard_state.dart';
import '../state/flags_state.dart';
import '../state/insights_state.dart';

/// Global provider identities used throughout the app.
/// These are registered once in the root [ProviderScope] in app.dart.

final posthogClientProvider = Provider<PosthogClient>(
  (_) => PosthogClient(),
);

final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);

final dashboardStateProvider = Provider<DashboardState>(
  (context) => DashboardState(client: posthogClientProvider.of(context)),
  dispose: (state) => state.dispose(),
);

final insightsStateProvider = Provider<InsightsState>(
  (context) => InsightsState(client: posthogClientProvider.of(context)),
  dispose: (state) => state.dispose(),
);

final flagsStateProvider = Provider<FlagsState>(
  (context) => FlagsState(client: posthogClientProvider.of(context)),
  dispose: (state) => state.dispose(),
);
