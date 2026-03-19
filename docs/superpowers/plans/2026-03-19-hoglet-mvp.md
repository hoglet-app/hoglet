# Hoglet MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MVP of Hoglet — a Flutter mobile PostHog client with dashboard home, feature flags, events, and settings, organized via bottom tabs + navigation drawer.

**Architecture:** Solidart signals-based state management. GoRouter with StatefulShellRoute for tab navigation. Services layer (pure async) → State layer (Signal) → Screen layer (SignalBuilder). Disco for DI at app root.

**Tech Stack:** Flutter/Dart, solidart/flutter_solidart, disco (DI), go_router, fl_chart, http, flutter_secure_storage, google_fonts

**Spec:** `docs/superpowers/specs/2026-03-19-hoglet-mobile-client-design.md`

**Workflow:** Stacking PRs. Each phase is a branch stacked on the previous: `phase-0-foundation` → `phase-1-dashboards` → `phase-2-flags` → `phase-3-activity-refactor`.

**Quality gate:** Run `flutter analyze` after every task. Fix all warnings before committing.

---

## File Map

### New files (Phase 0: Foundation)

| File | Responsibility |
|------|---------------|
| `lib/app.dart` | MaterialApp + theme + Disco DI root |
| `lib/models/host_mode.dart` | HostMode enum + extension (extracted from activity_screen) |
| `lib/models/column_spec.dart` | ColumnSpec, ColumnOption, ColumnKind, ColumnCategory, BuiltinColumnId (extracted) |
| `lib/services/storage_service.dart` | FlutterSecureStorage wrapper with typed keys |
| `lib/services/auth_service.dart` | Connection config signals, save/load/clear credentials |
| `lib/services/posthog_api_error.dart` | Typed error hierarchy: PosthogApiError, AuthenticationError, RateLimitError, NetworkError |
| `lib/routing/route_names.dart` | Named route path constants |
| `lib/routing/app_router.dart` | GoRouter config: StatefulShellRoute + branches + drawer routes |
| `lib/screens/shell/app_shell.dart` | Scaffold with NavigationBar (4 tabs) + hamburger for drawer |
| `lib/screens/shell/app_drawer.dart` | Navigation drawer with sectioned menu + project switcher |
| `lib/screens/settings/settings_screen.dart` | Full-screen settings (promoted from modal) |
| `lib/screens/onboarding/welcome_screen.dart` | Region picker, API key, project selector, connection test |
| `lib/widgets/error_view.dart` | Reusable error state with retry button |
| `lib/widgets/loading_states.dart` | Shimmer/skeleton loading placeholder |

### New files (Phase 1: Dashboards)

| File | Responsibility |
|------|---------------|
| `lib/models/dashboard.dart` | Dashboard data class with fromJson |
| `lib/models/insight.dart` | Insight + InsightResult data classes with fromJson |
| `lib/state/dashboard_state.dart` | Resource for dashboard list + single dashboard |
| `lib/state/insights_state.dart` | Resource for insight detail |
| `lib/screens/home/dashboard_list_screen.dart` | Dashboard list with search, pull-to-refresh |
| `lib/screens/home/dashboard_detail_screen.dart` | Dashboard with scrolling insight tiles |
| `lib/screens/insights/insight_detail_screen.dart` | Full chart view for an insight |
| `lib/widgets/insight_card.dart` | Compact chart card for dashboard tiles |
| `lib/widgets/chart_renderer.dart` | Line, bar, funnel, number chart rendering |

### New files (Phase 2: Feature Flags)

| File | Responsibility |
|------|---------------|
| `lib/models/feature_flag.dart` | FeatureFlag data class with fromJson |
| `lib/state/flags_state.dart` | Resource for flags list + toggle |
| `lib/screens/flags/flags_list_screen.dart` | Flags list with search + quick toggle |
| `lib/screens/flags/flag_detail_screen.dart` | Flag detail with release conditions |
| `lib/widgets/status_badge.dart` | Active/inactive status indicator |

### New files (Phase 3: Activity Refactor)

| File | Responsibility |
|------|---------------|
| `lib/state/events_state.dart` | Signals for events list, loading, column config |

### Modified files

| File | Changes |
|------|---------|
| `lib/main.dart` | Simplify to just `runApp`, delegate to `app.dart` |
| `lib/screens/activity_screen.dart` | Remove embedded enums/classes, remove settings modal, use solidart state, integrate with shell |
| `lib/services/posthog_client.dart` | Add dashboard, insight, feature_flag, project, org endpoints. Add typed error handling. |
| `pubspec.yaml` | Add `flutter_solidart`, `go_router`, `fl_chart` dependencies |

---

## Phase 0: Foundation

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_solidart, disco, go_router, fl_chart to pubspec.yaml**

Add under `dependencies:` section, after the existing `http` line:

```yaml
  flutter_solidart: ^2.7.1
  disco: ^0.3.1
  go_router: ^17.0.0
  fl_chart: ^1.1.0
```

> **Note:** `Solid` widget and `Provider` were removed from flutter_solidart 2.x. Use the `disco` package instead for dependency injection (`Disco` widget, `context.get<T>()`).
> fl_chart 1.x has API changes from 0.70.x — the plan uses 1.x APIs.

- [ ] **Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: packages resolve successfully, no errors.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no new issues introduced.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add solidart, disco, go_router, fl_chart dependencies"
```

---

### Task 2: Extract models from activity_screen.dart

**Files:**
- Create: `lib/models/host_mode.dart`
- Create: `lib/models/column_spec.dart`
- Modify: `lib/screens/activity_screen.dart`

- [ ] **Step 1: Create lib/models/host_mode.dart**

Extract `HostMode` enum and `HostModeX` extension from `activity_screen.dart` (lines 1319-1348) into a new file:

```dart
enum HostMode {
  us,
  eu,
  custom,
}

extension HostModeX on HostMode {
  String get storageValue {
    switch (this) {
      case HostMode.us:
        return 'us';
      case HostMode.eu:
        return 'eu';
      case HostMode.custom:
        return 'custom';
    }
  }

  String get hostUrl {
    switch (this) {
      case HostMode.us:
        return 'https://us.posthog.com';
      case HostMode.eu:
        return 'https://eu.posthog.com';
      case HostMode.custom:
        return '';
    }
  }

  static HostMode fromStorage(String raw) {
    switch (raw) {
      case 'eu':
        return HostMode.eu;
      case 'custom':
        return HostMode.custom;
      case 'us':
      default:
        return HostMode.us;
    }
  }
}
```

- [ ] **Step 2: Create lib/models/column_spec.dart**

Extract `BuiltinColumnId`, `ColumnKind`, `ColumnCategory`, `ColumnSpec`, `ColumnOption` from `activity_screen.dart` (lines 1212-1317) into a new file. Keep the classes identical but add the necessary imports.

```dart
enum BuiltinColumnId {
  event,
  person,
  url,
  library,
  time,
}

enum ColumnKind {
  builtin,
  property,
}

enum ColumnCategory {
  event,
  person,
  session,
  flags,
}

class ColumnSpec {
  const ColumnSpec._({
    required this.key,
    required this.label,
    required this.flex,
    required this.kind,
    this.id,
    this.propertyKey,
    this.category,
  });

  final String key;
  final String label;
  final int flex;
  final ColumnKind kind;
  final BuiltinColumnId? id;
  final String? propertyKey;
  final ColumnCategory? category;

  factory ColumnSpec.builtin({
    required BuiltinColumnId id,
    required String label,
    required int flex,
  }) {
    return ColumnSpec._(
      key: 'builtin:${id.name}',
      label: label,
      flex: flex,
      kind: ColumnKind.builtin,
      id: id,
    );
  }

  factory ColumnSpec.property({
    required String propertyKey,
    required String label,
    required ColumnCategory category,
  }) {
    return ColumnSpec._(
      key: 'prop:${category.name}:$propertyKey',
      label: label,
      flex: 2,
      kind: ColumnKind.property,
      propertyKey: propertyKey,
      category: category,
    );
  }

  factory ColumnSpec.fallback(String key) {
    return ColumnSpec._(
      key: key,
      label: key,
      flex: 2,
      kind: ColumnKind.property,
      propertyKey: key,
      category: ColumnCategory.event,
    );
  }
}

class ColumnOption {
  const ColumnOption._({
    required this.key,
    required this.label,
    required this.category,
    required this.propertyKey,
  });

  final String key;
  final String label;
  final ColumnCategory category;
  final String propertyKey;

  factory ColumnOption.property({
    required ColumnCategory category,
    required String propertyKey,
  }) {
    final label = propertyKey;
    return ColumnOption._(
      key: 'prop:${category.name}:$propertyKey',
      label: label,
      category: category,
      propertyKey: propertyKey,
    );
  }
}
```

- [ ] **Step 3: Update activity_screen.dart imports**

Remove the embedded enum/class definitions (lines 1212-1349) from `activity_screen.dart`. Add imports at the top:

```dart
import '../models/column_spec.dart';
import '../models/host_mode.dart';
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors. The app should compile identically since the classes are unchanged.

- [ ] **Step 5: Commit**

```bash
git add lib/models/host_mode.dart lib/models/column_spec.dart lib/screens/activity_screen.dart
git commit -m "refactor: extract HostMode and ColumnSpec models from activity_screen"
```

---

### Task 3: Create storage_service.dart

**Files:**
- Create: `lib/services/storage_service.dart`

- [ ] **Step 1: Create lib/services/storage_service.dart**

Wrap FlutterSecureStorage with typed key constants:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const keyHost = 'posthog_host';
  static const keyHostMode = 'posthog_host_mode';
  static const keyCustomHost = 'posthog_custom_host';
  static const keyProjectId = 'posthog_project_id';
  static const keyApiKey = 'posthog_personal_api_key';
  static const keyVisibleColumns = 'hoglet_visible_columns';

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearAll() async {
    await _storage.delete(key: keyHost);
    await _storage.delete(key: keyHostMode);
    await _storage.delete(key: keyCustomHost);
    await _storage.delete(key: keyProjectId);
    await _storage.delete(key: keyApiKey);
    await _storage.delete(key: keyVisibleColumns);
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/storage_service.dart
git commit -m "feat: add StorageService wrapper for secure storage"
```

---

### Task 4: Create typed API errors

**Files:**
- Create: `lib/services/posthog_api_error.dart`
- Modify: `lib/services/posthog_client.dart`

- [ ] **Step 1: Create lib/services/posthog_api_error.dart**

```dart
class PosthogApiError implements Exception {
  PosthogApiError(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'PosthogApiError($statusCode): $message';
}

class AuthenticationError extends PosthogApiError {
  AuthenticationError(super.statusCode, super.message);
}

class RateLimitError extends PosthogApiError {
  RateLimitError(super.statusCode, super.message, {this.retryAfterSeconds});
  final int? retryAfterSeconds;
}

class NetworkError implements Exception {
  NetworkError(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'NetworkError: $message';
}
```

- [ ] **Step 2: Update PosthogClient to throw typed errors**

In `lib/services/posthog_client.dart`, add import:

```dart
import 'posthog_api_error.dart';
```

Replace the error handling in `fetchEvents` (the `if (response.statusCode != 200)` block) with:

```dart
_checkResponse(response);
```

Similarly update `_fetchPagedResults` to use `_checkResponse(response);` instead of the inline error handling.

Add this private method to the class:

```dart
void _checkResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) return;

  final reason = response.reasonPhrase ?? 'Request failed';

  if (response.statusCode == 401 || response.statusCode == 403) {
    throw AuthenticationError(response.statusCode, reason);
  }

  if (response.statusCode == 429) {
    final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
    throw RateLimitError(response.statusCode, reason, retryAfterSeconds: retryAfter);
  }

  throw PosthogApiError(response.statusCode, reason);
}
```

Wrap the HTTP calls in `fetchEvents` with a try-catch for `SocketException` / `TimeoutException` to throw `NetworkError`:

```dart
import 'dart:io';
import 'dart:async';
```

In `fetchEvents`, wrap the `http.post` call:

```dart
final http.Response response;
try {
  response = await http.post(
    uri,
    headers: { ... },
    body: jsonEncode(body),
  ).timeout(const Duration(seconds: 30));
} on SocketException catch (e) {
  throw NetworkError('No internet connection', cause: e);
} on TimeoutException {
  throw NetworkError('Request timed out');
}
```

Apply the same pattern to `_fetchPagedResults` with a 15-second timeout.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/services/posthog_api_error.dart lib/services/posthog_client.dart
git commit -m "feat: add typed API error hierarchy and error handling"
```

---

### Task 5: Add API endpoints to PosthogClient

**Files:**
- Modify: `lib/services/posthog_client.dart`

- [ ] **Step 1: Add fetchProjects method**

> **Important:** Verify endpoint paths against https://posthog.com/docs/api before using. The spec notes that some endpoints use `/api/projects/` and some use `/api/environments/`. Use the PostHog source at `../posthog` as reference when docs are unclear.

```dart
Future<List<Map<String, dynamic>>> fetchProjects({
  required String host,
  required String apiKey,
}) async {
  final uri = Uri.parse('$host/api/projects/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body);
  if (decoded is Map && decoded['results'] is List) {
    return (decoded['results'] as List).cast<Map<String, dynamic>>();
  }
  if (decoded is List) {
    return decoded.cast<Map<String, dynamic>>();
  }
  return [];
}
```

- [ ] **Step 2: Add fetchOrganizations method**

```dart
Future<List<Map<String, dynamic>>> fetchOrganizations({
  required String host,
  required String apiKey,
}) async {
  final uri = Uri.parse('$host/api/organizations/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body);
  if (decoded is Map && decoded['results'] is List) {
    return (decoded['results'] as List).cast<Map<String, dynamic>>();
  }
  if (decoded is List) {
    return decoded.cast<Map<String, dynamic>>();
  }
  return [];
}
```

- [ ] **Step 3: Extract a shared _get helper**

Refactor the repeated HTTP GET + error handling into a helper:

```dart
Future<http.Response> _get(Uri uri, String apiKey, {Duration timeout = const Duration(seconds: 15)}) async {
  try {
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $apiKey'},
    ).timeout(timeout);
    _checkResponse(response);
    return response;
  } on SocketException catch (e) {
    throw NetworkError('No internet connection', cause: e);
  } on TimeoutException {
    throw NetworkError('Request timed out');
  }
}

Future<http.Response> _post(Uri uri, String apiKey, Map<String, dynamic> body, {Duration timeout = const Duration(seconds: 30)}) async {
  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    ).timeout(timeout);
    _checkResponse(response);
    return response;
  } on SocketException catch (e) {
    throw NetworkError('No internet connection', cause: e);
  } on TimeoutException {
    throw NetworkError('Request timed out');
  }
}
```

Update `fetchEvents` and `_fetchPagedResults` to use these helpers.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/posthog_client.dart
git commit -m "feat: add project/org discovery endpoints and HTTP helpers"
```

---

### Task 6: Create stub screens, route names, and app router

> **Important:** Create stub screens FIRST so the router can import them without errors.

**Files:**
- Create: `lib/screens/home/dashboard_list_screen.dart` (stub)
- Create: `lib/screens/onboarding/welcome_screen.dart` (stub)
- Create: `lib/screens/settings/settings_screen.dart` (stub — replaced in Task 9)
- Create: `lib/routing/route_names.dart`
- Create: `lib/routing/app_router.dart`

- [ ] **Step 0: Create stub screens so the router imports resolve**

Create `lib/screens/home/dashboard_list_screen.dart`:
```dart
import 'package:flutter/material.dart';

class DashboardListScreen extends StatelessWidget {
  const DashboardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dashboards coming in Phase 1'));
  }
}
```

Create `lib/screens/onboarding/welcome_screen.dart`:
```dart
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Welcome — stub')));
  }
}
```

Create `lib/screens/settings/settings_screen.dart` (minimal stub):
```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings — stub'));
  }
}
```

- [ ] **Step 1: Create lib/routing/route_names.dart**

```dart
class RouteNames {
  static const welcome = '/welcome';

  // Bottom tab roots
  static const home = '/home';
  static const activity = '/activity';
  static const flags = '/flags';
  static const settings = '/settings';

  // Home sub-routes
  static const dashboardDetail = 'dashboard/:dashboardId';
  static const insightDetail = 'insight/:insightId';

  // Flags sub-routes
  static const flagDetail = 'flag/:flagId';

  // Drawer routes (push outside shell)
  static const insights = '/insights';
  static const persons = '/persons';
  static const personDetail = '/persons/:personId';
  static const experiments = '/experiments';
  static const recordings = '/recordings';
  static const cohorts = '/cohorts';
  static const surveys = '/surveys';
  static const errorTracking = '/error-tracking';
  static const alerts = '/alerts';
  static const webAnalytics = '/web-analytics';
}
```

- [ ] **Step 2: Create lib/routing/app_router.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/shell/app_shell.dart';
import '../screens/home/dashboard_list_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/flags/flags_list_screen.dart';
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
                  // Sub-routes added in Phase 1
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
                builder: (context, state) => const Placeholder(), // Phase 2
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
```

Note: `DashboardListScreen` and `SettingsScreen` will be created in subsequent tasks. Use `Placeholder()` or a simple stub widget for screens not yet built.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: may have warnings about missing files — these are resolved in next tasks.

- [ ] **Step 4: Commit**

```bash
git add lib/routing/
git commit -m "feat: add GoRouter config with StatefulShellRoute for tab navigation"
```

---

### Task 7: Create reusable widgets (error_view, loading_states)

**Files:**
- Create: `lib/widgets/error_view.dart`
- Create: `lib/widgets/loading_states.dart`

- [ ] **Step 1: Create lib/widgets/error_view.dart**

```dart
import 'package:flutter/material.dart';
import '../services/posthog_api_error.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = _errorContent();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF6F6A63)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B19),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6F6A63)),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _errorContent() {
    if (error is NetworkError) {
      return (Icons.wifi_off, 'No connection', (error as NetworkError).message);
    }
    if (error is AuthenticationError) {
      return (Icons.lock_outline, 'Authentication failed', 'Check your API key and try again.');
    }
    if (error is RateLimitError) {
      final e = error as RateLimitError;
      final msg = e.retryAfterSeconds != null
          ? 'Too many requests. Try again in ${e.retryAfterSeconds}s.'
          : 'Too many requests. Try again later.';
      return (Icons.speed, 'Rate limited', msg);
    }
    if (error is PosthogApiError) {
      return (Icons.error_outline, 'Error', (error as PosthogApiError).message);
    }
    return (Icons.error_outline, 'Something went wrong', error.toString());
  }
}
```

- [ ] **Step 2: Create lib/widgets/loading_states.dart**

```dart
import 'package:flutter/material.dart';

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE3DED6).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF6F6A63)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B19),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(color: Color(0xFF6F6A63)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/
git commit -m "feat: add ErrorView and ShimmerList reusable widgets"
```

---

### Task 8: Create App Shell (bottom tabs + drawer)

**Files:**
- Create: `lib/screens/shell/app_shell.dart`
- Create: `lib/screens/shell/app_drawer.dart`

- [ ] **Step 1: Create lib/screens/shell/app_drawer.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F4EF),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Product Analytics'),
            _drawerItem(context, Icons.dashboard_outlined, 'Dashboards', RouteNames.home),
            _drawerItem(context, Icons.insights_outlined, 'Insights', RouteNames.insights),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Data'),
            _drawerItem(context, Icons.bolt_outlined, 'Events', RouteNames.activity),
            _drawerItem(context, Icons.person_outline, 'Persons', RouteNames.persons),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Features'),
            _drawerItem(context, Icons.flag_outlined, 'Feature Flags', RouteNames.flags),
            _drawerItem(context, Icons.science_outlined, 'Experiments', RouteNames.experiments),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Monitoring'),
            _drawerItem(context, Icons.videocam_outlined, 'Session Replay', RouteNames.recordings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF15A24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🦔', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoglet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1B19),
                  ),
                ),
                Text(
                  'PostHog Mobile',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6F6A63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Color(0xFFF15A24),
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1C1B19)),
      title: Text(label),
      dense: true,
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        context.go(route);
      },
    );
  }
}
```

- [ ] **Step 2: Create lib/screens/shell/app_shell.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F4EF),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_titleForIndex(navigationShell.currentIndex)),
      ),
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFEFE7),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFF15A24)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt, color: Color(0xFFF15A24)),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: Color(0xFFF15A24)),
            label: 'Flags',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFF15A24)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboards';
      case 1:
        return 'Activity';
      case 2:
        return 'Feature Flags';
      case 3:
        return 'Settings';
      default:
        return 'Hoglet';
    }
  }
}
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors (may warn about unused imports for routes not yet connected — acceptable).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/shell/
git commit -m "feat: add AppShell with bottom navigation bar and drawer"
```

---

### Task 9: Create Settings screen

**Files:**
- Create: `lib/screens/settings/settings_screen.dart`

- [ ] **Step 1: Create lib/screens/settings/settings_screen.dart**

Extract the settings modal content from `activity_screen.dart` into a full-screen settings page. Use the existing field layout but as a proper screen instead of a bottom sheet.

```dart
import 'package:flutter/material.dart';

import '../../models/host_mode.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();

  final _customHostController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _apiKeyController = TextEditingController();

  HostMode _hostMode = HostMode.us;
  bool _showApiKey = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customHostController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final hostMode = await _storage.read(StorageService.keyHostMode) ?? 'us';
    final customHost = await _storage.read(StorageService.keyCustomHost) ?? '';
    final projectId = await _storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await _storage.read(StorageService.keyApiKey) ?? '';

    if (!mounted) return;
    setState(() {
      _hostMode = HostModeX.fromStorage(hostMode);
      _customHostController.text = customHost;
      _projectIdController.text = projectId;
      _apiKeyController.text = apiKey;
      _loaded = true;
    });
  }

  Future<void> _saveSettings() async {
    final host = _effectiveHost;
    final projectId = _projectIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
      _showSnackBar('Please fill host, project ID, and API key.');
      return;
    }

    await _storage.write(StorageService.keyHost, host);
    await _storage.write(StorageService.keyHostMode, _hostMode.storageValue);
    await _storage.write(StorageService.keyCustomHost, _customHostController.text.trim());
    await _storage.write(StorageService.keyProjectId, projectId);
    await _storage.write(StorageService.keyApiKey, apiKey);

    if (!mounted) return;
    _showSnackBar('Settings saved.');
  }

  String get _effectiveHost {
    if (_hostMode == HostMode.custom) {
      var host = _customHostController.text.trim();
      if (host.isNotEmpty && !host.startsWith('http://') && !host.startsWith('https://')) {
        host = 'https://$host';
      }
      return host.replaceAll(RegExp(r'/+$'), '');
    }
    return _hostMode.hostUrl;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Connection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<HostMode>(
          value: _hostMode,
          decoration: const InputDecoration(labelText: 'Host Region'),
          items: const [
            DropdownMenuItem(value: HostMode.us, child: Text('US Cloud (us.posthog.com)')),
            DropdownMenuItem(value: HostMode.eu, child: Text('EU Cloud (eu.posthog.com)')),
            DropdownMenuItem(value: HostMode.custom, child: Text('Custom Domain')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _hostMode = value);
          },
        ),
        if (_hostMode == HostMode.custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customHostController,
            decoration: const InputDecoration(
              labelText: 'Custom Host',
              hintText: 'https://your.posthog.domain',
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _projectIdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Project ID'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKeyController,
          obscureText: !_showApiKey,
          decoration: InputDecoration(
            labelText: 'Personal API Key',
            suffixIcon: IconButton(
              icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showApiKey = !_showApiKey),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save Settings'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your personal API key is stored securely on this device.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        const Text(
          'About',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hoglet — PostHog Mobile Client\nVersion 1.0.0',
          style: TextStyle(color: Color(0xFF6F6A63)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat: add full-screen Settings screen"
```

---

### Task 10: Replace WelcomeScreen stub and wire up app.dart + main.dart

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/screens/onboarding/welcome_screen.dart` (replace stub)
- Modify: `lib/main.dart`

- [ ] **Step 1: Replace WelcomeScreen stub with real implementation**

```dart
// lib/screens/onboarding/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4EF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF15A24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('🦔', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Hoglet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'PostHog mobile client',
                style: TextStyle(color: Color(0xFF6F6A63)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF15A24),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create lib/app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routing/app_router.dart';

class HogletApp extends StatefulWidget {
  const HogletApp({super.key});

  @override
  State<HogletApp> createState() => _HogletAppState();
}

class _HogletAppState extends State<HogletApp> {
  late final _router = createRouter(isAuthenticated: true);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme();

    return MaterialApp.router(
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
    );
  }
}
```

> **Note:** This initial app.dart does NOT include Disco DI yet. DI is added in Task 20 (Phase 1) when state classes exist. This keeps Phase 0 focused on navigation structure.

- [ ] **Step 3: Update lib/main.dart**

```dart
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  runApp(const HogletApp());
}
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 5: Run the app**

Run: `flutter run` (or verify it compiles)
Expected: app launches with bottom tab bar (Home, Activity, Flags, Settings). Home tab shows "Dashboards coming in Phase 1". Activity tab shows the existing Events screen. Settings tab shows the settings stub. Drawer opens from hamburger menu.

- [ ] **Step 6: Commit**

```bash
git add lib/app.dart lib/main.dart lib/screens/onboarding/welcome_screen.dart
git commit -m "feat: wire up GoRouter, AppShell, and WelcomeScreen"
```

---

### Task 11: Remove settings modal from ActivityScreen

**Files:**
- Modify: `lib/screens/activity_screen.dart`

- [ ] **Step 1: Remove _openSettingsSheet and settings button**

In `activity_screen.dart`:
- Remove the `_openSettingsSheet()` method entirely (lines 210-330)
- Remove the settings IconButton from the AppBar actions (lines 348-353)
- The settings icon is no longer needed because settings is now a dedicated tab

Note: The ActivityScreen still needs its own state for loading events (host, projectId, apiKey from storage). That will be refactored in Phase 3. For now, keep the `_loadSettings` / `_saveSettings` / `_persistSettings` methods since they power the event fetching.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/activity_screen.dart
git commit -m "refactor: remove settings modal from ActivityScreen (now a dedicated tab)"
```

---

## Phase 1: Dashboards (Home Tab)

### Task 12: Dashboard model

**Files:**
- Create: `lib/models/dashboard.dart`

- [ ] **Step 1: Create lib/models/dashboard.dart**

> Check the PostHog API response format by looking at `../posthog/posthog/api/dashboards/` or the API docs. The model should match the JSON response from `GET /api/environments/{id}/dashboards/`.

```dart
class Dashboard {
  Dashboard({
    required this.id,
    required this.name,
    this.description,
    this.pinned = false,
    this.createdAt,
    this.updatedAt,
    this.tiles = const [],
    this.tags = const [],
  });

  final int id;
  final String name;
  final String? description;
  final bool pinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DashboardTile> tiles;
  final List<String> tags;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final tilesJson = json['tiles'] as List? ?? [];
    return Dashboard(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['last_modified_at'] != null ? DateTime.tryParse(json['last_modified_at'].toString()) : null,
      tiles: tilesJson.map((t) => DashboardTile.fromJson(t as Map<String, dynamic>)).toList(),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}

class DashboardTile {
  DashboardTile({
    required this.id,
    this.insightId,
    this.insightName,
    this.insightType,
    this.lastRefresh,
    this.color,
    this.layoutData,
  });

  final int id;
  final int? insightId;
  final String? insightName;
  final String? insightType;
  final DateTime? lastRefresh;
  final String? color;
  final Map<String, dynamic>? layoutData;

  factory DashboardTile.fromJson(Map<String, dynamic> json) {
    final insight = json['insight'] as Map<String, dynamic>?;
    return DashboardTile(
      id: json['id'] as int,
      insightId: insight?['id'] as int?,
      insightName: insight?['name'] as String?,
      insightType: insight?['query']?['kind'] as String? ?? insight?['filters']?['insight'] as String?,
      lastRefresh: json['last_refresh'] != null ? DateTime.tryParse(json['last_refresh'].toString()) : null,
      color: json['color'] as String?,
      layoutData: json['layouts'] as Map<String, dynamic>?,
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/models/dashboard.dart
git commit -m "feat: add Dashboard and DashboardTile models"
```

---

### Task 13: Insight model

**Files:**
- Create: `lib/models/insight.dart`

- [ ] **Step 1: Create lib/models/insight.dart**

> Check `../posthog/posthog/api/insight.py` or API docs for the response shape.

```dart
class Insight {
  Insight({
    required this.id,
    required this.name,
    this.description,
    this.insightType,
    this.queryKind,
    this.result,
    this.filters,
    this.query,
    this.lastRefresh,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final String? insightType;
  final String? queryKind;
  final dynamic result;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? query;
  final DateTime? lastRefresh;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Determines the display type for chart rendering.
  /// Returns one of: 'TRENDS', 'FUNNELS', 'NUMBER', or the raw type.
  String get displayType {
    // New-style query-based insights
    if (queryKind != null) {
      if (queryKind == 'TrendsQuery') return 'TRENDS';
      if (queryKind == 'FunnelsQuery') return 'FUNNELS';
      if (queryKind == 'LifecycleQuery') return 'LIFECYCLE';
      if (queryKind == 'RetentionQuery') return 'RETENTION';
      if (queryKind == 'PathsQuery') return 'PATHS';
      if (queryKind == 'StickinessQuery') return 'STICKINESS';
    }
    // Legacy filter-based insights
    return insightType?.toUpperCase() ?? 'UNKNOWN';
  }

  bool get isSupportedChart {
    final type = displayType;
    return type == 'TRENDS' || type == 'FUNNELS' || type == 'NUMBER';
  }

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      insightType: json['filters']?['insight'] as String?,
      queryKind: json['query']?['kind'] as String?,
      result: json['result'],
      filters: json['filters'] as Map<String, dynamic>?,
      query: json['query'] as Map<String, dynamic>?,
      lastRefresh: json['last_refresh'] != null ? DateTime.tryParse(json['last_refresh'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['last_modified_at'] != null ? DateTime.tryParse(json['last_modified_at'].toString()) : null,
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/models/insight.dart
git commit -m "feat: add Insight model with display type detection"
```

---

### Task 14: Add dashboard and insight endpoints to PosthogClient

**Files:**
- Modify: `lib/services/posthog_client.dart`

- [ ] **Step 1: Add fetchDashboards method**

```dart
import '../models/dashboard.dart';
import '../models/insight.dart';

Future<List<Dashboard>> fetchDashboards({
  required String host,
  required String projectId,
  required String apiKey,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/dashboards/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body);
  final results = decoded is Map && decoded['results'] is List
      ? decoded['results'] as List
      : decoded is List ? decoded : [];
  return results.map((d) => Dashboard.fromJson(d as Map<String, dynamic>)).toList();
}
```

- [ ] **Step 2: Add fetchDashboard (single) method**

```dart
Future<Dashboard> fetchDashboard({
  required String host,
  required String projectId,
  required String apiKey,
  required int dashboardId,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/dashboards/$dashboardId/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return Dashboard.fromJson(decoded);
}
```

- [ ] **Step 3: Add fetchInsight method**

```dart
Future<Insight> fetchInsight({
  required String host,
  required String projectId,
  required String apiKey,
  required int insightId,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/insights/$insightId/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return Insight.fromJson(decoded);
}
```

- [ ] **Step 4: Add fetchInsights (list) method**

```dart
Future<List<Insight>> fetchInsights({
  required String host,
  required String projectId,
  required String apiKey,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/insights/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body);
  final results = decoded is Map && decoded['results'] is List
      ? decoded['results'] as List
      : decoded is List ? decoded : [];
  return results.map((d) => Insight.fromJson(d as Map<String, dynamic>)).toList();
}
```

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/services/posthog_client.dart
git commit -m "feat: add dashboard and insight API endpoints"
```

---

### Task 15: Dashboard state with solidart

**Files:**
- Create: `lib/state/dashboard_state.dart`
- Create: `lib/state/insights_state.dart`

- [ ] **Step 1: Create lib/state/dashboard_state.dart**

```dart
import 'package:solidart/solidart.dart';

import '../models/dashboard.dart';
import '../services/posthog_client.dart';

class DashboardState {
  DashboardState({required this.client});

  final PosthogClient client;

  final dashboards = Signal<List<Dashboard>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  final selectedDashboard = Signal<Dashboard?>(null);
  final isLoadingDetail = Signal(false);
  final detailError = Signal<Object?>(null);

  Future<void> fetchDashboards({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await client.fetchDashboards(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
      dashboards.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDashboard({
    required String host,
    required String projectId,
    required String apiKey,
    required int dashboardId,
  }) async {
    isLoadingDetail.value = true;
    detailError.value = null;

    try {
      final result = await client.fetchDashboard(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        dashboardId: dashboardId,
      );
      selectedDashboard.value = result;
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void dispose() {
    dashboards.dispose();
    isLoading.dispose();
    error.dispose();
    selectedDashboard.dispose();
    isLoadingDetail.dispose();
    detailError.dispose();
  }
}
```

- [ ] **Step 2: Create lib/state/insights_state.dart**

```dart
import 'package:solidart/solidart.dart';

import '../models/insight.dart';
import '../services/posthog_client.dart';

class InsightsState {
  InsightsState({required this.client});

  final PosthogClient client;

  final selectedInsight = Signal<Insight?>(null);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchInsight({
    required String host,
    required String projectId,
    required String apiKey,
    required int insightId,
  }) async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await client.fetchInsight(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        insightId: insightId,
      );
      selectedInsight.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    selectedInsight.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/state/
git commit -m "feat: add DashboardState and InsightsState with solidart signals"
```

---

### Task 16: Chart renderer widget

**Files:**
- Create: `lib/widgets/chart_renderer.dart`

- [ ] **Step 1: Create lib/widgets/chart_renderer.dart**

MVP charts: line/bar for trends, horizontal bar for funnels, styled card for numbers. The `result` field from the Insight API contains the chart data.

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/insight.dart';

class ChartRenderer extends StatelessWidget {
  const ChartRenderer({super.key, required this.insight, this.compact = false});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!insight.isSupportedChart) {
      return _UnsupportedChart(type: insight.displayType);
    }

    switch (insight.displayType) {
      case 'TRENDS':
        return _TrendsChart(insight: insight, compact: compact);
      case 'FUNNELS':
        return _FunnelsChart(insight: insight, compact: compact);
      case 'NUMBER':
        return _NumberChart(insight: insight);
      default:
        return _UnsupportedChart(type: insight.displayType);
    }
  }
}

class _TrendsChart extends StatelessWidget {
  const _TrendsChart({required this.insight, required this.compact});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final series = _parseTrendsSeries(insight.result);
    if (series.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: !compact),
        titlesData: FlTitlesData(show: !compact),
        borderData: FlBorderData(show: false),
        lineBarsData: series.asMap().entries.map((entry) {
          final color = _seriesColors[entry.key % _seriesColors.length];
          return LineChartBarData(
            spots: entry.value,
            isCurved: true,
            color: color,
            barWidth: compact ? 2 : 3,
            dotData: FlDotData(show: !compact),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FunnelsChart extends StatelessWidget {
  const _FunnelsChart({required this.insight, required this.compact});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = _parseFunnelSteps(insight.result);
    if (steps.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: !compact,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < steps.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      steps[index].label,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: steps.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.conversionRate,
                color: const Color(0xFFF15A24),
                width: compact ? 16 : 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NumberChart extends StatelessWidget {
  const _NumberChart({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final value = _parseNumberValue(insight.result);

    return Center(
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF15A24),
        ),
      ),
    );
  }
}

class _UnsupportedChart extends StatelessWidget {
  const _UnsupportedChart({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart, size: 32, color: Color(0xFF6F6A63)),
          const SizedBox(height: 8),
          Text(
            '$type chart',
            style: const TextStyle(color: Color(0xFF6F6A63)),
          ),
          const SizedBox(height: 4),
          const Text(
            'View on web for full experience',
            style: TextStyle(fontSize: 12, color: Color(0xFF6F6A63)),
          ),
        ],
      ),
    );
  }
}

// --- Parsing helpers ---

const _seriesColors = [
  Color(0xFFF15A24),
  Color(0xFF1D4AFF),
  Color(0xFF621DA6),
  Color(0xFF42827E),
  Color(0xFFCE0E29),
];

List<List<FlSpot>> _parseTrendsSeries(dynamic result) {
  if (result is! List) return [];

  final series = <List<FlSpot>>[];
  for (final item in result) {
    if (item is! Map) continue;
    final data = item['data'] as List?;
    final days = item['days'] as List? ?? item['labels'] as List?;
    if (data == null) continue;

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final y = (data[i] is num) ? (data[i] as num).toDouble() : 0.0;
      spots.add(FlSpot(i.toDouble(), y));
    }
    series.add(spots);
  }
  return series;
}

class _FunnelStep {
  _FunnelStep({required this.label, required this.conversionRate});
  final String label;
  final double conversionRate;
}

List<_FunnelStep> _parseFunnelSteps(dynamic result) {
  if (result is! List) return [];

  return result.map((step) {
    if (step is! Map) return _FunnelStep(label: '?', conversionRate: 0);
    final label = step['name']?.toString() ?? step['action_id']?.toString() ?? '?';
    final rate = step['conversion_rate'];
    final rateValue = rate is num ? rate.toDouble() : 0.0;
    return _FunnelStep(label: label, conversionRate: rateValue);
  }).toList();
}

String _parseNumberValue(dynamic result) {
  if (result is List && result.isNotEmpty) {
    final first = result[0];
    if (first is Map) {
      final aggregated = first['aggregated_value'] ?? first['count'];
      if (aggregated is num) {
        if (aggregated == aggregated.toInt()) {
          return aggregated.toInt().toString();
        }
        return aggregated.toStringAsFixed(1);
      }
    }
  }
  return '—';
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/chart_renderer.dart
git commit -m "feat: add ChartRenderer with trends, funnels, and number support"
```

---

### Task 17: Insight card widget (compact chart for dashboard tiles)

**Files:**
- Create: `lib/widgets/insight_card.dart`

- [ ] **Step 1: Create lib/widgets/insight_card.dart**

```dart
import 'package:flutter/material.dart';

import '../models/insight.dart';
import 'chart_renderer.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    this.tileName,
    this.onTap,
  });

  final Insight insight;
  final String? tileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3DED6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tileName ?? insight.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B19),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ChartRenderer(insight: insight, compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/insight_card.dart
git commit -m "feat: add InsightCard widget for dashboard tiles"
```

---

### Task 18: Dashboard List screen (real implementation)

**Files:**
- Modify: `lib/screens/home/dashboard_list_screen.dart`

- [ ] **Step 1: Replace stub with real DashboardListScreen**

```dart
import 'package:flutter/material.dart';
import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../models/dashboard.dart';
import '../../services/storage_service.dart';
import '../../state/dashboard_state.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/error_view.dart';

class DashboardListScreen extends StatefulWidget {
  const DashboardListScreen({super.key});

  @override
  State<DashboardListScreen> createState() => _DashboardListScreenState();
}

class _DashboardListScreenState extends State<DashboardListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDashboards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboards() async {
    final dashboardState = context.get<DashboardState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) return;

    await dashboardState.fetchDashboards(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.get<DashboardState>();

    return RefreshIndicator(
      onRefresh: _loadDashboards,
      child: SignalBuilder(
        builder: (context, child) {
          final isLoading = dashboardState.isLoading.value;
          final error = dashboardState.error.value;
          final dashboards = dashboardState.dashboards.value;

          if (isLoading && dashboards.isEmpty) {
            return const ShimmerList();
          }

          if (error != null && dashboards.isEmpty) {
            return ErrorView(error: error, onRetry: _loadDashboards);
          }

          if (dashboards.isEmpty) {
            return const EmptyState(
              icon: Icons.dashboard_outlined,
              title: 'No dashboards yet',
              subtitle: 'Create dashboards in PostHog web to see them here.',
            );
          }

          final filtered = _searchQuery.isEmpty
              ? dashboards
              : dashboards.where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          // Sort: pinned first, then by updatedAt
          final sorted = List<Dashboard>.from(filtered)
            ..sort((a, b) {
              if (a.pinned && !b.pinned) return -1;
              if (!a.pinned && b.pinned) return 1;
              return (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000));
            });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search dashboards...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final dashboard = sorted[index];
                    return _DashboardCard(
                      dashboard: dashboard,
                      onTap: () => context.go('/home/dashboard/${dashboard.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.dashboard, this.onTap});

  final Dashboard dashboard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3DED6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          dashboard.pinned ? Icons.push_pin : Icons.dashboard_outlined,
          color: dashboard.pinned ? const Color(0xFFF15A24) : const Color(0xFF6F6A63),
        ),
        title: Text(
          dashboard.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: dashboard.description != null && dashboard.description!.isNotEmpty
            ? Text(
                dashboard.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6F6A63)),
              )
            : Text(
                '${dashboard.tiles.length} tiles',
                style: const TextStyle(color: Color(0xFF6F6A63), fontSize: 12),
              ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF6F6A63)),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/dashboard_list_screen.dart
git commit -m "feat: implement DashboardListScreen with search and pull-to-refresh"
```

---

### Task 19: Dashboard Detail screen

**Files:**
- Create: `lib/screens/home/dashboard_detail_screen.dart`

- [ ] **Step 1: Create lib/screens/home/dashboard_detail_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../models/insight.dart';
import '../../services/posthog_client.dart';
import '../../services/storage_service.dart';
import '../../state/dashboard_state.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/error_view.dart';

class DashboardDetailScreen extends StatefulWidget {
  const DashboardDetailScreen({super.key, required this.dashboardId});

  final int dashboardId;

  @override
  State<DashboardDetailScreen> createState() => _DashboardDetailScreenState();
}

class _DashboardDetailScreenState extends State<DashboardDetailScreen> {
  final Map<int, Insight> _insightCache = {};
  bool _loadingInsights = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final dashboardState = context.get<DashboardState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) return;

    await dashboardState.fetchDashboard(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
      dashboardId: widget.dashboardId,
    );

    // Load insight data for each tile
    final dashboard = dashboardState.selectedDashboard.value;
    if (dashboard != null) {
      await _loadInsightsForTiles(host, projectId, apiKey, dashboard.tiles);
    }
  }

  Future<void> _loadInsightsForTiles(
    String host,
    String projectId,
    String apiKey,
    List tiles,
  ) async {
    setState(() => _loadingInsights = true);
    final client = context.get<PosthogClient>();

    for (final tile in tiles) {
      final insightId = tile.insightId;
      if (insightId == null || _insightCache.containsKey(insightId)) continue;

      try {
        final insight = await client.fetchInsight(
          host: host,
          projectId: projectId,
          apiKey: apiKey,
          insightId: insightId,
        );
        if (mounted) {
          setState(() => _insightCache[insightId] = insight);
        }
      } catch (_) {
        // Skip failed insight loads; show placeholder
      }
    }

    if (mounted) setState(() => _loadingInsights = false);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.get<DashboardState>();

    return SignalBuilder(
      builder: (context, child) {
        final isLoading = dashboardState.isLoadingDetail.value;
        final error = dashboardState.detailError.value;
        final dashboard = dashboardState.selectedDashboard.value;

        if (isLoading && dashboard == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: const ShimmerList(),
          );
        }

        if (error != null && dashboard == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: ErrorView(error: error, onRetry: _loadDashboard),
          );
        }

        if (dashboard == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: const EmptyState(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard not found',
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F4EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F4EF),
            title: Text(dashboard.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDashboard,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadDashboard,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dashboard.tiles.length,
              itemBuilder: (context, index) {
                final tile = dashboard.tiles[index];
                final insight = tile.insightId != null ? _insightCache[tile.insightId] : null;

                if (insight == null) {
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE3DED6)),
                    ),
                    child: SizedBox(
                      height: 160,
                      child: Center(
                        child: _loadingInsights
                            ? const CircularProgressIndicator()
                            : Text(
                                tile.insightName ?? 'Insight',
                                style: const TextStyle(color: Color(0xFF6F6A63)),
                              ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InsightCard(
                    insight: insight,
                    tileName: tile.insightName,
                    onTap: () => context.go('/home/dashboard/${widget.dashboardId}/insight/${insight.id}'),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Add dashboard detail and insight detail routes to app_router.dart**

Update the Home branch routes in `lib/routing/app_router.dart`:

```dart
GoRoute(
  path: RouteNames.home,
  builder: (context, state) => const DashboardListScreen(),
  routes: [
    GoRoute(
      path: 'dashboard/:dashboardId',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['dashboardId']!);
        return DashboardDetailScreen(dashboardId: id);
      },
      routes: [
        GoRoute(
          path: 'insight/:insightId',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['insightId']!);
            return InsightDetailScreen(insightId: id);
          },
        ),
      ],
    ),
  ],
),
```

Add the necessary imports for `DashboardDetailScreen` and `InsightDetailScreen`.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors (InsightDetailScreen will be created next).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home/dashboard_detail_screen.dart lib/routing/app_router.dart
git commit -m "feat: implement DashboardDetailScreen with insight tile rendering"
```

---

### Task 20: Insight Detail screen

**Files:**
- Create: `lib/screens/insights/insight_detail_screen.dart`

- [ ] **Step 1: Create lib/screens/insights/insight_detail_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../models/insight.dart';
import '../../services/storage_service.dart';
import '../../state/insights_state.dart';
import '../../widgets/chart_renderer.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/error_view.dart';

class InsightDetailScreen extends StatefulWidget {
  const InsightDetailScreen({super.key, required this.insightId});

  final int insightId;

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    final insightsState = context.get<InsightsState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) return;

    await insightsState.fetchInsight(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
      insightId: widget.insightId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final insightsState = context.get<InsightsState>();

    return SignalBuilder(
      builder: (context, child) {
        final isLoading = insightsState.isLoading.value;
        final error = insightsState.error.value;
        final insight = insightsState.selectedInsight.value;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F4EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F4EF),
            title: Text(insight?.name ?? 'Insight'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadInsight,
              ),
            ],
          ),
          body: isLoading && insight == null
              ? const ShimmerList(itemCount: 1)
              : error != null && insight == null
                  ? ErrorView(error: error, onRetry: _loadInsight)
                  : insight == null
                      ? const EmptyState(icon: Icons.insights, title: 'Insight not found')
                      : RefreshIndicator(
                          onRefresh: _loadInsight,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (insight.description != null && insight.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    insight.description!,
                                    style: const TextStyle(color: Color(0xFF6F6A63)),
                                  ),
                                ),
                              Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE3DED6)),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: ChartRenderer(insight: insight),
                              ),
                              const SizedBox(height: 16),
                              _buildMetadata(insight),
                            ],
                          ),
                        ),
        );
      },
    );
  }

  Widget _buildMetadata(Insight insight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3DED6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _metaRow('Type', insight.displayType),
          if (insight.lastRefresh != null)
            _metaRow('Last refreshed', _formatDate(insight.lastRefresh!)),
          if (insight.createdAt != null)
            _metaRow('Created', _formatDate(insight.createdAt!)),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6F6A63), fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: Wire up Disco DI in app.dart**

Update `lib/app.dart` to provide `PosthogClient`, `StorageService`, `DashboardState`, and `InsightsState` via the `Disco` widget:

```dart
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routing/app_router.dart';
import 'services/posthog_client.dart';
import 'services/storage_service.dart';
import 'state/dashboard_state.dart';
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

  @override
  void dispose() {
    _dashboardState.dispose();
    _insightsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme();

    return Disco(
      providers: [
        DiscoProvider<PosthogClient>(create: () => _client),
        DiscoProvider<StorageService>(create: () => _storage),
        DiscoProvider<DashboardState>(create: () => _dashboardState),
        DiscoProvider<InsightsState>(create: () => _insightsState),
      ],
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
```

> **Note:** `Disco` and `DiscoProvider` come from the `disco` package, NOT flutter_solidart. `context.get<T>()` is provided by disco. All screens access state/services via `context.get<T>()`.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/insights/insight_detail_screen.dart lib/app.dart
git commit -m "feat: implement InsightDetailScreen and wire up Solid DI"
```

---

## Phase 2: Feature Flags (Flags Tab)

### Task 21: FeatureFlag model

**Files:**
- Create: `lib/models/feature_flag.dart`

- [ ] **Step 1: Create lib/models/feature_flag.dart**

```dart
class FeatureFlag {
  FeatureFlag({
    required this.id,
    required this.key,
    required this.name,
    required this.active,
    this.rolloutPercentage,
    this.filters,
    this.createdAt,
    this.isSimpleFlag = false,
    this.rollbackConditions = const [],
    this.ensureExperienceContinuity = false,
  });

  final int id;
  final String key;
  final String name;
  final bool active;
  final int? rolloutPercentage;
  final Map<String, dynamic>? filters;
  final DateTime? createdAt;
  final bool isSimpleFlag;
  final List<dynamic> rollbackConditions;
  final bool ensureExperienceContinuity;

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] as int,
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      rolloutPercentage: json['rollout_percentage'] as int?,
      filters: json['filters'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      isSimpleFlag: json['is_simple_flag'] as bool? ?? false,
      rollbackConditions: json['rollback_conditions'] as List? ?? [],
      ensureExperienceContinuity: json['ensure_experience_continuity'] as bool? ?? false,
    );
  }

  /// Extract release condition groups from filters for display.
  List<Map<String, dynamic>> get releaseConditions {
    final groups = filters?['groups'] as List?;
    if (groups == null) return [];
    return groups.cast<Map<String, dynamic>>();
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/models/feature_flag.dart
git commit -m "feat: add FeatureFlag model"
```

---

### Task 22: Feature flag API endpoints

**Files:**
- Modify: `lib/services/posthog_client.dart`

- [ ] **Step 1: Add fetchFeatureFlags, fetchFeatureFlag, toggleFeatureFlag**

```dart
import '../models/feature_flag.dart';

Future<List<FeatureFlag>> fetchFeatureFlags({
  required String host,
  required String projectId,
  required String apiKey,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/feature_flags/');
  final response = await _get(uri, apiKey);
  final decoded = jsonDecode(response.body);
  final results = decoded is Map && decoded['results'] is List
      ? decoded['results'] as List
      : decoded is List ? decoded : [];
  return results.map((f) => FeatureFlag.fromJson(f as Map<String, dynamic>)).toList();
}

Future<FeatureFlag> fetchFeatureFlag({
  required String host,
  required String projectId,
  required String apiKey,
  required int flagId,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/feature_flags/$flagId/');
  final response = await _get(uri, apiKey);
  return FeatureFlag.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

Future<FeatureFlag> toggleFeatureFlag({
  required String host,
  required String projectId,
  required String apiKey,
  required int flagId,
  required bool active,
}) async {
  final uri = Uri.parse('$host/api/environments/$projectId/feature_flags/$flagId/');
  final response = await _patch(uri, apiKey, {'active': active});
  return FeatureFlag.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}
```

Also add the `_patch` helper:

```dart
Future<http.Response> _patch(Uri uri, String apiKey, Map<String, dynamic> body, {Duration timeout = const Duration(seconds: 15)}) async {
  try {
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    ).timeout(timeout);
    _checkResponse(response);
    return response;
  } on SocketException catch (e) {
    throw NetworkError('No internet connection', cause: e);
  } on TimeoutException {
    throw NetworkError('Request timed out');
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/posthog_client.dart
git commit -m "feat: add feature flag API endpoints with toggle support"
```

---

### Task 23: Flags state

**Files:**
- Create: `lib/state/flags_state.dart`

- [ ] **Step 1: Create lib/state/flags_state.dart**

```dart
import 'package:solidart/solidart.dart';

import '../models/feature_flag.dart';
import '../services/posthog_client.dart';

class FlagsState {
  FlagsState({required this.client});

  final PosthogClient client;

  final flags = Signal<List<FeatureFlag>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  final selectedFlag = Signal<FeatureFlag?>(null);
  final isLoadingDetail = Signal(false);
  final detailError = Signal<Object?>(null);

  Future<void> fetchFlags({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await client.fetchFeatureFlags(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
      flags.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFlag({
    required String host,
    required String projectId,
    required String apiKey,
    required int flagId,
  }) async {
    isLoadingDetail.value = true;
    detailError.value = null;

    try {
      final result = await client.fetchFeatureFlag(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        flagId: flagId,
      );
      selectedFlag.value = result;
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> toggleFlag({
    required String host,
    required String projectId,
    required String apiKey,
    required int flagId,
    required bool active,
  }) async {
    try {
      final updated = await client.toggleFeatureFlag(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        flagId: flagId,
        active: active,
      );

      // Update in list
      final current = List<FeatureFlag>.from(flags.value);
      final index = current.indexWhere((f) => f.id == flagId);
      if (index >= 0) {
        current[index] = updated;
        flags.value = current;
      }

      // Update detail if viewing this flag
      if (selectedFlag.value?.id == flagId) {
        selectedFlag.value = updated;
      }
    } catch (e) {
      error.value = e;
      rethrow;
    }
  }

  void dispose() {
    flags.dispose();
    isLoading.dispose();
    error.dispose();
    selectedFlag.dispose();
    isLoadingDetail.dispose();
    detailError.dispose();
  }
}
```

- [ ] **Step 2: Register FlagsState in app.dart**

Add to `lib/app.dart`:

```dart
import 'state/flags_state.dart';
```

Add `late final _flagsState = FlagsState(client: _client);` and dispose it. Add `DiscoProvider<FlagsState>(create: () => _flagsState)` to the `Disco` providers list.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/state/flags_state.dart lib/app.dart
git commit -m "feat: add FlagsState with toggle support"
```

---

### Task 24: Status badge widget

**Files:**
- Create: `lib/widgets/status_badge.dart`

- [ ] **Step 1: Create lib/widgets/status_badge.dart**

```dart
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: active ? const Color(0xFF166534) : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/status_badge.dart
git commit -m "feat: add StatusBadge widget"
```

---

### Task 25: Flags List screen

**Files:**
- Create: `lib/screens/flags/flags_list_screen.dart`

- [ ] **Step 1: Create lib/screens/flags/flags_list_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../services/storage_service.dart';
import '../../state/flags_state.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_badge.dart';

class FlagsListScreen extends StatefulWidget {
  const FlagsListScreen({super.key});

  @override
  State<FlagsListScreen> createState() => _FlagsListScreenState();
}

class _FlagsListScreenState extends State<FlagsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFlags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlags() async {
    final flagsState = context.get<FlagsState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) return;

    await flagsState.fetchFlags(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
    );
  }

  Future<void> _toggleFlag(int flagId, bool newValue) async {
    HapticFeedback.mediumImpact();

    final flagsState = context.get<FlagsState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    try {
      await flagsState.toggleFlag(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        flagId: flagId,
        active: newValue,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagsState = context.get<FlagsState>();

    return RefreshIndicator(
      onRefresh: _loadFlags,
      child: SignalBuilder(
        builder: (context, child) {
          final isLoading = flagsState.isLoading.value;
          final error = flagsState.error.value;
          final flags = flagsState.flags.value;

          if (isLoading && flags.isEmpty) {
            return const ShimmerList();
          }

          if (error != null && flags.isEmpty) {
            return ErrorView(error: error, onRetry: _loadFlags);
          }

          if (flags.isEmpty) {
            return const EmptyState(
              icon: Icons.flag_outlined,
              title: 'No feature flags yet',
              subtitle: 'Create feature flags in PostHog web.',
            );
          }

          final filtered = _searchQuery.isEmpty
              ? flags
              : flags.where((f) =>
                  f.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  f.name.toLowerCase().contains(_searchQuery.toLowerCase()),
                ).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search flags...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final flag = filtered[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE3DED6)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(flag.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Row(
                          children: [
                            StatusBadge(label: flag.active ? 'Active' : 'Inactive', active: flag.active),
                            if (flag.rolloutPercentage != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${flag.rolloutPercentage}%',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6F6A63)),
                              ),
                            ],
                          ],
                        ),
                        trailing: Switch(
                          value: flag.active,
                          activeColor: const Color(0xFFF15A24),
                          onChanged: (value) => _toggleFlag(flag.id, value),
                        ),
                        onTap: () => context.go('/flags/flag/${flag.id}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Update app_router.dart flags branch**

Replace the `Placeholder()` in the flags branch:

```dart
StatefulShellBranch(
  navigatorKey: _flagsNavigatorKey,
  routes: [
    GoRoute(
      path: RouteNames.flags,
      builder: (context, state) => const FlagsListScreen(),
      routes: [
        GoRoute(
          path: 'flag/:flagId',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['flagId']!);
            return FlagDetailScreen(flagId: id);
          },
        ),
      ],
    ),
  ],
),
```

Add imports for `FlagsListScreen` and `FlagDetailScreen`.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors (FlagDetailScreen created next).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/flags/flags_list_screen.dart lib/routing/app_router.dart
git commit -m "feat: implement FlagsListScreen with search and quick toggle"
```

---

### Task 26: Flag Detail screen

**Files:**
- Create: `lib/screens/flags/flag_detail_screen.dart`

- [ ] **Step 1: Create lib/screens/flags/flag_detail_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../services/storage_service.dart';
import '../../state/flags_state.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_badge.dart';

class FlagDetailScreen extends StatefulWidget {
  const FlagDetailScreen({super.key, required this.flagId});

  final int flagId;

  @override
  State<FlagDetailScreen> createState() => _FlagDetailScreenState();
}

class _FlagDetailScreenState extends State<FlagDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    final flagsState = context.get<FlagsState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) return;

    await flagsState.fetchFlag(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
      flagId: widget.flagId,
    );
  }

  Future<void> _toggleFlag(bool newValue) async {
    HapticFeedback.mediumImpact();

    final flagsState = context.get<FlagsState>();
    final storage = context.get<StorageService>();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    try {
      await flagsState.toggleFlag(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        flagId: widget.flagId,
        active: newValue,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagsState = context.get<FlagsState>();

    return SignalBuilder(
      builder: (context, child) {
        final isLoading = flagsState.isLoadingDetail.value;
        final error = flagsState.detailError.value;
        final flag = flagsState.selectedFlag.value;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F4EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F4EF),
            title: Text(flag?.key ?? 'Feature Flag'),
          ),
          body: isLoading && flag == null
              ? const ShimmerList(itemCount: 3)
              : error != null && flag == null
                  ? ErrorView(error: error, onRetry: _loadFlag)
                  : flag == null
                      ? const EmptyState(icon: Icons.flag_outlined, title: 'Flag not found')
                      : RefreshIndicator(
                          onRefresh: _loadFlag,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Toggle card
                              Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE3DED6)),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Enabled', style: TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: StatusBadge(
                                    label: flag.active ? 'Active' : 'Inactive',
                                    active: flag.active,
                                  ),
                                  value: flag.active,
                                  activeColor: const Color(0xFFF15A24),
                                  onChanged: _toggleFlag,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Info card
                              _infoCard([
                                _infoRow('Key', flag.key),
                                if (flag.name.isNotEmpty) _infoRow('Name', flag.name),
                                if (flag.rolloutPercentage != null) _infoRow('Rollout', '${flag.rolloutPercentage}%'),
                                if (flag.createdAt != null) _infoRow('Created', _formatDate(flag.createdAt!)),
                              ]),
                              const SizedBox(height: 12),
                              // Release conditions
                              if (flag.releaseConditions.isNotEmpty) ...[
                                const Text('Release Conditions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 8),
                                ...flag.releaseConditions.asMap().entries.map((entry) {
                                  final group = entry.value;
                                  final properties = group['properties'] as List? ?? [];
                                  final rollout = group['rollout_percentage'];

                                  return Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE3DED6)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Group ${entry.key + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          if (rollout != null) Text('Rollout: $rollout%', style: const TextStyle(fontSize: 12, color: Color(0xFF6F6A63))),
                                          if (properties.isNotEmpty)
                                            ...properties.map((p) {
                                              final prop = p as Map;
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '${prop['key']} ${prop['operator']} ${prop['value']}',
                                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
        );
      },
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3DED6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6F6A63), fontSize: 13)),
          const Spacer(),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/flags/flag_detail_screen.dart
git commit -m "feat: implement FlagDetailScreen with toggle and release conditions"
```

---

## Phase 3: Activity Tab Refactor

### Task 27: Create events state

**Files:**
- Create: `lib/state/events_state.dart`

- [ ] **Step 1: Create lib/state/events_state.dart**

Extract the event loading logic from `activity_screen.dart` into a solidart-based state:

```dart
import 'dart:convert';

import 'package:solidart/solidart.dart';

import '../models/column_spec.dart';
import '../models/event_item.dart';
import '../services/posthog_client.dart';
import '../services/storage_service.dart';

class EventsState {
  EventsState({required this.client, required this.storage});

  final PosthogClient client;
  final StorageService storage;

  final events = Signal<List<EventItem>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  final visibleColumnKeys = Signal<List<String>>([]);
  final columnRegistry = Signal<Map<String, ColumnSpec>>({});
  final availableColumns = Signal<List<ColumnOption>>([]);
  final isLoadingColumns = Signal(false);

  void registerBuiltinColumns() {
    final defaults = [
      ColumnSpec.builtin(id: BuiltinColumnId.event, label: 'Event', flex: 2),
      ColumnSpec.builtin(id: BuiltinColumnId.person, label: 'Person', flex: 2),
      ColumnSpec.builtin(id: BuiltinColumnId.url, label: 'URL / Screen', flex: 3),
      ColumnSpec.builtin(id: BuiltinColumnId.library, label: 'Library', flex: 1),
      ColumnSpec.builtin(id: BuiltinColumnId.time, label: 'Time', flex: 1),
    ];

    final registry = Map<String, ColumnSpec>.from(columnRegistry.value);
    for (final spec in defaults) {
      registry[spec.key] = spec;
    }
    columnRegistry.value = registry;

    if (visibleColumnKeys.value.isEmpty) {
      visibleColumnKeys.value = defaults.map((s) => s.key).toList();
    }
  }

  Future<void> loadVisibleColumns() async {
    final raw = await storage.read(StorageService.keyVisibleColumns);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        visibleColumnKeys.value = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  Future<void> saveVisibleColumns() async {
    await storage.write(
      StorageService.keyVisibleColumns,
      jsonEncode(visibleColumnKeys.value),
    );
  }

  Future<void> fetchEvents({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await client.fetchEvents(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
      events.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAvailableColumns({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    if (isLoadingColumns.value) return;
    isLoadingColumns.value = true;

    try {
      final eventProps = await client.fetchPropertyDefinitions(host: host, projectId: projectId, apiKey: apiKey, type: 'event');
      final personProps = await client.fetchPropertyDefinitions(host: host, projectId: projectId, apiKey: apiKey, type: 'person');
      final sessionProps = await client.fetchPropertyDefinitions(host: host, projectId: projectId, apiKey: apiKey, type: 'session');

      final options = <ColumnOption>[
        ...eventProps.map((name) => ColumnOption.property(category: ColumnCategory.event, propertyKey: name)),
        ...personProps.map((name) => ColumnOption.property(category: ColumnCategory.person, propertyKey: name)),
        ...sessionProps.map((name) => ColumnOption.property(category: ColumnCategory.session, propertyKey: name)),
      ];

      availableColumns.value = options;

      // Update registry
      final registry = Map<String, ColumnSpec>.from(columnRegistry.value);
      for (final option in options) {
        final spec = ColumnSpec.property(propertyKey: option.propertyKey, label: option.label, category: option.category);
        registry[spec.key] = spec;
      }
      columnRegistry.value = registry;
    } catch (_) {
      // Ignore — available columns just won't show
    } finally {
      isLoadingColumns.value = false;
    }
  }

  ColumnSpec columnForKey(String key) {
    return columnRegistry.value[key] ?? ColumnSpec.fallback(key);
  }

  void dispose() {
    events.dispose();
    isLoading.dispose();
    error.dispose();
    visibleColumnKeys.dispose();
    columnRegistry.dispose();
    availableColumns.dispose();
    isLoadingColumns.dispose();
  }
}
```

- [ ] **Step 2: Register EventsState in app.dart**

Add `late final _eventsState = EventsState(client: _client, storage: _storage);` and provide it via `DiscoProvider<EventsState>(create: () => _eventsState)`. Dispose in `dispose()`.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/state/events_state.dart lib/app.dart
git commit -m "feat: add EventsState with solidart signals for events and columns"
```

---

### Task 28: Refactor ActivityScreen to use EventsState

**Files:**
- Modify: `lib/screens/activity_screen.dart`

- [ ] **Step 1: Refactor ActivityScreen**

This is a significant refactor. The key changes:

1. Remove `_storage`, `_client`, `_events`, `_isLoading`, `_visibleColumnKeys`, `_columnRegistry`, `_availableColumns`, `_isLoadingColumns` fields — these are now in `EventsState`.
2. Remove `_loadSettings`, `_saveSettings`, `_persistSettings` — settings are managed by `SettingsScreen`.
3. Remove `_hostMode`, `_customHostController`, `_projectIdController`, `_apiKeyController`, `_showApiKey` — no longer needed here.
4. Remove `WidgetsBindingObserver` mixin — no longer managing settings persistence.
5. Use `context.get<EventsState>()` to access state.
6. Use `context.get<StorageService>()` to read connection credentials when fetching.
7. Wrap the events table and column-dependent UI in `SignalBuilder`.
8. Keep all the UI building methods (`_buildEventsTab`, `_buildEventsTable`, `_buildEventRow`, etc.) but make them read from `EventsState` instead of local fields.

The refactored screen should be significantly shorter since state management, settings, and model definitions have been extracted.

> **Important:** This is a large refactor. Work incrementally — first get it compiling with EventsState, then verify the events table still renders correctly.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Test the Activity tab**

Verify the Events tab still works: loads events, shows the table, column config dialog works, event detail bottom sheet opens.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/activity_screen.dart
git commit -m "refactor: migrate ActivityScreen to use EventsState (solidart)"
```

---

### Task 29: Final integration verification

- [ ] **Step 1: Run flutter analyze on entire project**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 2: Verify all tabs work**

Launch the app and test:
- **Home tab**: Dashboard list loads (or shows empty state if no dashboards)
- **Activity tab**: Events load and display in the table
- **Flags tab**: Feature flags load (or shows empty state)
- **Settings tab**: Settings form works, saves credentials
- **Drawer**: Opens from hamburger, all items navigate correctly
- **Deep navigation**: Dashboard → tile → Insight detail works
- **Flag toggle**: Toggle switch sends PATCH request with haptic feedback

- [ ] **Step 3: Commit any final fixes**

```bash
git add -A
git commit -m "fix: final integration fixes for MVP"
```

---

## Summary

| Phase | Tasks | Key deliverables |
|-------|-------|-----------------|
| Phase 0: Foundation | Tasks 1-11 | Dependencies, extracted models, storage/auth services, error types, GoRouter, AppShell, drawer, settings screen, stubs |
| Phase 1: Dashboards | Tasks 12-20 | Dashboard/Insight models, API endpoints, state, chart renderer, dashboard list/detail, insight detail |
| Phase 2: Feature Flags | Tasks 21-26 | FeatureFlag model, API endpoints (incl. PATCH toggle), state, flags list with search + toggle, flag detail |
| Phase 3: Activity Refactor | Tasks 27-29 | EventsState extraction, ActivityScreen refactor to solidart, integration verification |

**Total: 29 tasks across 4 phases.**
