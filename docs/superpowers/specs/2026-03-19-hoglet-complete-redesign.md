# Hoglet — Complete Redesign Spec

## Overview

Hoglet is an open-source Flutter mobile client for PostHog. PostHog's mobile web experience is inconvenient and lacks accessibility support — Hoglet provides a native, accessible alternative for checking analytics, monitoring events, and managing feature flags on the go.

**Target audience:** PostHog community — engineers and product teams who use PostHog and want mobile access.

**Philosophy:** Read-heavy, minimal writes. View dashboards, insights with full breakdown support, events, persons, session replays (list only). Only two write operations: toggle feature flags, dismiss alerts.

**This is a complete rewrite** — starting fresh with the same tech stack but a comprehensive plan covering all PostHog features from Phase 0 through Phase 10.

## Information Architecture

### Navigation: Bottom Tabs + Drawer

**Bottom Tab Bar** — 4 tabs for daily essentials, always visible:

| Tab | Screen | Purpose |
|-----|--------|---------|
| Home | Dashboard List → Detail → Insight Detail | KPI dashboards with breakdown charts |
| Activity | Events Stream | Live event feed, column config, event detail |
| Flags | Feature Flags List → Detail | View all flags, quick toggle on/off |
| Settings | Settings Screen | Connection, project switcher, theme, about |

**Navigation Drawer** — Full feature access via hamburger icon:

| Section | Items | Treatment |
|---------|-------|-----------|
| Product Analytics | Dashboards, Insights, Web Analytics | Native |
| Data | Events, Persons, Cohorts | Native |
| Feature Management | Feature Flags, Experiments, Surveys | Native |
| Monitoring | Session Replay, Error Tracking, Alerts, Heatmaps | Native (Heatmaps: link-out) |
| Data & Tools | SQL Editor, Annotations, Data Pipelines, Notebooks | Native (Pipelines, Notebooks: link-out) |

### Navigation Behavior

- Bottom tabs use `StatefulShellBranch` (GoRouter) — each tab preserves its own navigation stack
- Drawer items that map to tabs (Dashboards, Events, Flags) navigate to that tab
- Drawer-only items push full-screen routes outside the shell (no bottom bar visible)
- Link-out items launch system browser with external-link icon indicator
- Hamburger icon accessible in both tab screens and full-screen drawer routes
- Back button pops within current stack; long-press goes to tab root

### Project Switching

- Switching projects clears all cached state (all Signals reset, re-fetch)
- Selected project ID persisted in secure storage across app restarts
- During switch: loading indicator on current screen while data re-fetches

## Feature Treatment Matrix

### Native Screens (full implementation)

| Feature | Screens | Write Ops | Phase |
|---------|---------|-----------|-------|
| Dashboards | List, Detail | None | 1 |
| Insights (all types) | Detail, List | None | 1, 5 |
| Feature Flags | List, Detail | Toggle on/off | 2 |
| Events Stream | Activity screen | None | 3 |
| Persons | List, Detail | None | 4 |
| Cohorts | List, Detail | None | 4 |
| Experiments | List, Detail | None | 6 |
| Surveys | List, Detail | None | 6 |
| Error Tracking | List, Detail | None | 7 |
| Alerts | List, Detail | Dismiss | 7 |
| Web Analytics | Dashboard screen | None | 8 |
| Session Replay | List only | None | 8 |
| SQL Editor | Query + results | None | 9 |
| Annotations | List | None | 9 |
| LLM Analytics | Metrics (gated) | None | 9 |
| Revenue Analytics | Metrics (gated) | None | 9 |

### Link-Out Features (open in PostHog web)

| Feature | Rationale |
|---------|-----------|
| Heatmaps | Visual overlay requires full browser |
| Notebooks | Rich editor impractical on mobile |
| Data Pipelines | Admin config better on desktop |
| Early Access Features | Rarely accessed on mobile |
| Session Replay playback | rrweb DOM replay impractical on mobile |
| Paths insight type | Sankey diagrams not feasible in fl_chart |

## Architecture

### Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter (Dart 3.8+) | Cross-platform iOS + Android |
| State Management | flutter_solidart | Signals-based reactivity (Signal, Computed) |
| Routing | go_router | StatefulShellRoute for bottom tabs |
| Charts | fl_chart | Native Flutter: LineChart, BarChart. Custom widgets for Retention table. |
| HTTP | http | Simple, sufficient |
| Storage | flutter_secure_storage | Encrypted credential persistence |
| DI | InheritedWidget | AppProviders pattern, no external dependency |
| Font | google_fonts | Space Grotesk |

### Data Flow

```
PostHog API → PosthogClient (services/) → *State (Signals) → SignalBuilder (screens/)
```

- **Services** are pure async. Take parameters, call HTTP, return model objects. No signals, no state.
- **State** layer holds `Signal<T>` instances. Async methods call services, update signals.
- **Screens** use `SignalBuilder` for reactive UI. `didChangeDependencies` for initialization.
- **Models** are plain Dart classes with `fromJson` factory constructors.
- **DI** via `AppProviders.of(context)` InheritedWidget at app root.

### Project Structure

```
lib/
├── app.dart                    // MaterialApp, theme, DI setup
├── main.dart                   // Entry point
├── routing/
│   ├── app_router.dart         // GoRouter: ShellRoute + 4 branches
│   └── route_names.dart        // Named route constants
├── models/                     // Plain Dart data classes
│   ├── dashboard.dart          // + DashboardTile
│   ├── insight.dart            // + InsightResult, InsightSeries (multi-series)
│   ├── feature_flag.dart
│   ├── event_item.dart
│   ├── column_spec.dart
│   ├── person.dart
│   ├── cohort.dart
│   ├── experiment.dart
│   ├── survey.dart
│   ├── error_group.dart
│   ├── alert.dart
│   └── annotation.dart
├── services/
│   ├── posthog_client.dart     // All HTTP endpoints
│   ├── storage_service.dart    // Secure storage wrapper
│   └── posthog_api_error.dart  // Typed error hierarchy
├── state/                      // One *_state.dart per domain
│   ├── dashboard_state.dart
│   ├── insights_state.dart
│   ├── flags_state.dart
│   ├── events_state.dart
│   ├── persons_state.dart
│   ├── cohorts_state.dart
│   ├── experiments_state.dart
│   ├── surveys_state.dart
│   ├── error_tracking_state.dart
│   ├── alerts_state.dart
│   ├── web_analytics_state.dart
│   ├── recordings_state.dart
│   ├── sql_state.dart
│   └── annotations_state.dart
├── screens/                    // Organized by feature
│   ├── shell/ (app_shell, app_drawer)
│   ├── onboarding/ (welcome_screen)
│   ├── home/ (dashboard_list, dashboard_detail)
│   ├── activity/ (activity_screen)
│   ├── flags/ (flags_list, flag_detail)
│   ├── insights/ (insight_detail, insights_list)
│   ├── persons/ (persons_list, person_detail)
│   ├── cohorts/ (cohorts_list, cohort_detail)
│   ├── experiments/ (experiments_list, experiment_detail)
│   ├── surveys/ (surveys_list, survey_detail)
│   ├── error_tracking/ (error_list, error_detail)
│   ├── alerts/ (alerts_list, alert_detail)
│   ├── web_analytics/ (web_analytics_screen)
│   ├── recordings/ (recordings_list)
│   ├── sql/ (sql_editor_screen)
│   ├── annotations/ (annotations_list)
│   └── settings/ (settings_screen)
├── widgets/                    // Reusable components
│   ├── chart_renderer.dart     // Multi-series line, bar, funnel, number
│   ├── breakdown_legend.dart   // Color-coded property value legend
│   ├── filter_summary.dart     // Read-only breakdown/filter display
│   ├── insight_card.dart       // Compact chart card for dashboard tiles
│   ├── property_table.dart     // Key-value display (persons, events, errors)
│   ├── search_bar.dart
│   ├── status_badge.dart
│   ├── shimmer_list.dart       // Skeleton loading
│   ├── error_view.dart         // Error + retry button
│   ├── empty_state.dart
│   ├── link_out_screen.dart    // "Open in PostHog" template
│   ├── stack_trace_view.dart   // Monospace code display
│   ├── retention_table.dart    // Custom table for retention cohorts
│   ├── lifecycle_chart.dart    // Stacked bar for lifecycle
│   └── stickiness_chart.dart   // Bar chart for stickiness
└── di/
    └── providers.dart          // AppProviders InheritedWidget
```

### State Pattern

Every domain follows the same pattern:

```dart
class DashboardState {
  final dashboards = Signal<List<Dashboard>>([]);
  final dashboard = Signal<Dashboard?>(null);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchDashboards(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true;
    error.value = null;
    try {
      dashboards.value = await client.fetchDashboards(host, projectId, apiKey);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    dashboards.dispose();
    dashboard.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
```

### Screen Pattern

```dart
class DashboardListScreen extends StatefulWidget { ... }

class _State extends State<DashboardListScreen> {
  late DashboardState _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final providers = AppProviders.of(context);
    _state = providers.dashboardState;
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = AppProviders.of(context).storage;
    final host = await storage.read('host');
    final projectId = await storage.read('projectId');
    final apiKey = await storage.read('apiKey');
    if (host != null && projectId != null && apiKey != null) {
      _state.fetchDashboards(AppProviders.of(context).client, host, projectId, apiKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, _) {
        if (_state.isLoading.value) return const ShimmerList();
        if (_state.error.value != null) return ErrorView(error: _state.error.value!, onRetry: _loadData);
        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(/* ... */),
        );
      },
    );
  }
}
```

### Chart Rendering (with Breakdown Support)

Phase 1 builds multi-series chart rendering:

**Trends:** `LineChart` with multiple `LineChartBarData` — one line per breakdown value. Legend below with color dots. Also supports `BarChart` with grouped bars when display type is bar.

**Funnels:** `BarChart` with horizontal bars per step. Each bar shows conversion rate percentage. When broken down, shows side-by-side bars per breakdown value. Drop-off percentage between steps.

**Number:** Styled text card with main value + delta vs previous period.

**Unsupported types:** Show icon + type name + "View on PostHog" button that opens the insight in the system browser.

The `InsightResult` model includes:
- `series: List<InsightSeries>` — each series has label, values, color
- `breakdownValue: String?` — the property value this series represents
- `steps: List<FunnelStep>?` — for funnel insights, each step with name, count, conversion rate

### Error Handling

| Error Type | Status Code | Response |
|------------|-------------|----------|
| `AuthenticationError` | 401/403 | Clear credentials → redirect to Welcome |
| `RateLimitError` | 429 | Parse Retry-After → countdown toast |
| `NetworkError` | — | "No connection" state with retry |
| `PosthogApiError` | Other 4xx/5xx | Error message with retry button |

Timeouts: 15s for list endpoints, 30s for query/heavy endpoints.

### Caching

MVP: in-memory only. `Signal` instances hold last successful value. On re-fetch failure, stale data shown with "Update failed" banner. Project switch resets all signals. Persistent cache deferred to Phase 10.

### Pagination

MVP: fetch full results (PostHog defaults to reasonable limits). Phase 10 adds `PaginatedSignal<T>` with infinite scroll and cursor-based pagination using PostHog's `next` URL response pattern.

## API Endpoints

> All endpoints use Personal API Key via Bearer token. Paths use `/api/environments/{teamId}/` (preferred) or `/api/projects/{projectId}/` depending on PostHog endpoint.

### Phase 0 (Foundation)
```
GET  /api/projects/                                    # project discovery
GET  /api/organizations/                               # org info
```

### Phase 1 (Dashboards)
```
GET  /api/environments/{id}/dashboards/                # list
GET  /api/environments/{id}/dashboards/{id}/           # detail with tiles
GET  /api/environments/{id}/insights/                  # list
GET  /api/environments/{id}/insights/{id}/             # detail with result data
```

### Phase 2 (Feature Flags)
```
GET   /api/environments/{id}/feature_flags/            # list
GET   /api/environments/{id}/feature_flags/{id}/       # detail
PATCH /api/environments/{id}/feature_flags/{id}/       # toggle active
```

### Phase 3 (Events)
```
POST /api/projects/{id}/query/                         # HogQL query
GET  /api/projects/{id}/property_definitions/          # property discovery
```

### Phase 4 (Persons & Cohorts)
```
GET  /api/environments/{id}/persons/                   # list
GET  /api/environments/{id}/persons/{id}/              # detail
GET  /api/projects/{id}/cohorts/                       # list
GET  /api/projects/{id}/cohorts/{id}/                  # detail
GET  /api/projects/{id}/cohorts/{id}/persons/          # members
```

### Phase 6 (Experiments & Surveys)
```
GET  /api/environments/{id}/experiments/               # list
GET  /api/environments/{id}/experiments/{id}/          # detail
GET  /api/environments/{id}/surveys/                   # list
GET  /api/environments/{id}/surveys/{id}/              # detail
```

### Phase 7 (Error Tracking & Alerts)
```
GET   /api/environments/{id}/error_tracking/groups/    # list
GET   /api/environments/{id}/error_tracking/groups/{id}/ # detail
GET   /api/environments/{id}/alerts/                   # list
GET   /api/environments/{id}/alerts/{id}/              # detail
PATCH /api/environments/{id}/alerts/{id}/              # dismiss
```

### Phase 8 (Web Analytics & Recordings)
```
POST /api/projects/{id}/query/                         # web analytics HogQL
GET  /api/environments/{id}/session_recordings/        # list only
```

### Phase 9 (SQL & Annotations)
```
POST /api/projects/{id}/query/                         # HogQL (reuses existing)
GET  /api/environments/{id}/annotations/               # list
```

## UX Patterns

- **Pull-to-refresh** on all list screens
- **Shimmer/skeleton loading** — show content shape while loading, never blank screens
- **Bottom sheets** for detail views where appropriate (event detail, column config)
- **Error states** with retry button on all data screens
- **Empty states** with helpful messaging ("No dashboards yet — create one in PostHog web")
- **Haptic feedback** on feature flag toggle
- **Landscape mode** for chart screens (Phase 10)
- **Swipe-to-go-back** on detail screens

## Accessibility (Pragmatic A11y)

- `Semantics` widget wrapping all interactive elements
- `semanticLabel` on every icon
- 48dp minimum touch targets on all tappable surfaces
- Chart widgets include text descriptions for screen readers (e.g., "Trends chart showing 3 series: US 42%, UK 28%, DE 15%")
- Color is never the only differentiator — use shape/text alongside color
- ExcludeSemantics for purely decorative elements
- TalkBack (Android) + VoiceOver (iOS) testing in Phase 10

## Theme

- Primary: `#F15A24` (orange)
- Background: `#F5F4EF` (light beige)
- Text primary: `#1C1B19`
- Text secondary: `#6F6A63`
- Borders: `#E3DED6`
- Font: Space Grotesk (Google Fonts)
- Material 3 design language
- Dark mode: Phase 10

## Implementation Order

Stacking PR workflow: each phase is a branch stacked on the previous.

### Phase 0: Foundation
- Flutter project setup with all dependencies
- PosthogClient with auth, error handling, project/org endpoints
- StorageService (flutter_secure_storage wrapper)
- Error hierarchy (AuthenticationError, RateLimitError, NetworkError)
- AppProviders InheritedWidget DI
- GoRouter with StatefulShellRoute (4 bottom tab branches)
- AppShell with bottom NavigationBar + drawer skeleton (all sections, "coming soon" placeholders)
- Welcome/Connect screen (region picker, API key, project selector, "Test Connection")
- Settings screen (connection settings, project switcher, about)
- Theme setup (Space Grotesk, colors, Material 3)

### Phase 1: Dashboards + Deep Analytics
- Dashboard model + DashboardTile model
- Insight model with InsightResult and InsightSeries (multi-series support)
- DashboardState + InsightsState
- PosthogClient: dashboards list/detail, insights list/detail
- Dashboard List screen (search, sort by pinned/updated, pull-to-refresh)
- Dashboard Detail screen (insight tiles, date range filter)
- Insight Detail screen with chart rendering
- ChartRenderer with multi-series support:
  - Trends: multi-line LineChart / grouped BarChart with breakdown legend
  - Funnels: horizontal bars with per-step conversion rates, drop-off %, breakdown comparison
  - Number: styled card with delta
  - Unsupported types: "View on PostHog" placeholder
- BreakdownLegend widget (color-coded property values)
- FilterSummary widget (read-only breakdown/filter display)
- InsightCard widget (compact chart for dashboard tiles)
- ShimmerList, ErrorView, EmptyState widgets

### Phase 2: Feature Flags
- FeatureFlag model with release conditions
- FlagsState
- PosthogClient: feature_flags list/detail/toggle
- Flags List screen (search, toggle switch per flag)
- Flag Detail screen (conditions, rollout %, linked experiments)
- StatusBadge widget

### Phase 3: Events Stream
- EventItem model, ColumnSpec model
- EventsState with column management
- PosthogClient: HogQL query, property definitions
- Activity Screen with event cards
- Column config bottom sheet (drag-to-reorder, builtin + custom properties)
- Event detail bottom sheet
- Persist column config in secure storage

### Phase 4: Persons & Cohorts
- Person model, Cohort model
- PersonsState, CohortsState
- PosthogClient: persons list/detail, cohorts list/detail/persons
- Persons List screen (search by email/name/distinct_id)
- Person Detail screen (properties table, event timeline, cohort memberships)
- Cohorts List screen (name, count, static/dynamic badge)
- Cohort Detail screen (filter criteria, member preview)
- PropertyTable widget (reusable key-value display)
- Activate drawer items: Persons, Cohorts

### Phase 5: Remaining Insight Types + Insights List
- RetentionTable widget (custom table with colored cells, cohort grid)
- LifecycleChart widget (stacked BarChart: new/returning/resurrecting/dormant)
- StickinessChart widget (simple BarChart)
- Paths: "Open in PostHog" link-out placeholder
- Update ChartRenderer to handle all types
- Update Insight model: isSupportedChart includes Retention, Lifecycle, Stickiness
- Standalone Insights List screen (search, type filter chips)
- Activate drawer item: Insights

### Phase 6: Experiments & Surveys
- Experiment model (variants, feature_flag_id, results, significance)
- Survey model (questions, type, response count, status)
- ExperimentsState, SurveysState
- PosthogClient: experiments list/detail, surveys list/detail
- Experiments List screen (active/completed filter, status badges)
- Experiment Detail screen (variant comparison grouped BarChart, significance badge, linked flag)
- Surveys List screen (name, type, response count, status)
- Survey Detail screen (response summary, completion rate, individual responses)
- Activate drawer items: Experiments, Surveys

### Phase 7: Error Tracking & Alerts
- ErrorGroup model (fingerprint, count, first_seen, last_seen, status)
- Alert model (name, status, threshold, linked insight)
- ErrorTrackingState, AlertsState
- PosthogClient: error groups list/detail, alerts list/detail/dismiss
- Error Groups List screen (fingerprint, count, time badges)
- Error Detail screen (stack trace, occurrence timeline, affected users)
- Alerts List screen (name, status badge, linked insight)
- Alert Detail screen (threshold config read-only, trigger history, dismiss button)
- StackTraceView widget (monospace scrollable text)
- Activate drawer items: Error Tracking, Alerts

### Phase 8: Web Analytics + Link-outs + Session Replay List
- WebAnalyticsState, RecordingsState
- PosthogClient: web analytics HogQL queries, session recordings list
- Web Analytics screen (unique visitors, pageviews, sessions, top pages, referrers, device breakdown)
- Session Replay List screen (user info, duration, timestamp — tap opens PostHog web)
- LinkOutScreen widget (icon, description, "Open in PostHog" button)
- Link-out drawer items: Heatmaps, Notebooks, Data Pipelines, Early Access
- Activate all remaining drawer items
- Finalize drawer: all sections populated, link-outs marked with ↗ icon

### Phase 9: SQL Editor + Annotations + Alpha Features
- Annotation model
- SqlState, AnnotationsState
- PosthogClient: annotations list (HogQL endpoint already exists for SQL)
- SQL Editor screen (text input, execute button, tabular result display)
- QueryResultsTable widget (horizontal scrolling table for arbitrary HogQL)
- Annotations List screen (timeline with dates and content)
- LLM Analytics screen (gated behind Settings toggle — token usage, model comparison)
- Revenue Analytics screen (gated behind Settings toggle — metrics overview)
- Settings: "Show experimental features" toggle
- Graceful 404 handling for alpha feature endpoints

### Phase 10: Accessibility, Polish & Ship
- **Accessibility audit:** Semantics on all interactive elements, semanticLabel on icons, 48dp touch targets, chart text descriptions, ExcludeSemantics on decorative elements
- **TalkBack + VoiceOver testing** across all screens
- **Dark mode:** ThemeMode signal in settings, dual ColorScheme
- **Landscape mode** for chart screens (insight detail, experiment detail)
- **Deep linking** (path-based routes already designed for this)
- **Pagination:** PaginatedSignal<T> + infinite scroll on all list screens
- **Performance:** const constructors, DevTools profiling, lazy loading
- **Testing:** Model fromJson round-trip tests, service mock tests, critical widget tests
- **App store:** metadata, screenshots, icons, privacy policy
