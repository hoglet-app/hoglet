# Hoglet — PostHog Mobile Client Design Spec

## Overview

Hoglet is an open-source Flutter mobile client for PostHog. PostHog's mobile web experience is inconvenient — Hoglet provides a native, polished alternative for checking analytics, monitoring events, and managing feature flags on the go.

**Target audience:** PostHog community — engineers and product teams who use PostHog and want mobile access.

**Philosophy:** Read-heavy, minimal writes. View dashboards, insights, events, persons, session replays. Only simple write operations (toggle feature flags, dismiss alerts).

## Information Architecture

### Navigation: Hybrid (Bottom Tabs + Drawer)

**Bottom Tab Bar** — 4 tabs for daily essentials, always visible:

| Tab | Screen | Purpose |
|-----|--------|---------|
| Home | Dashboard List → Dashboard Detail | Default landing. KPI dashboards at a glance. |
| Activity | Events Stream (existing) | Live event feed, column config, event detail. |
| Flags | Feature Flags List | View all flags, quick toggle on/off. |
| Settings | Settings Screen | Connection config, project switcher, theme. |

**Navigation Drawer** — Full feature access via hamburger (☰) icon in app bar:

| Section | Items |
|---------|-------|
| Product Analytics | Dashboards, Insights, Web Analytics |
| Data | Events, Persons, Cohorts |
| Features | Feature Flags, Experiments, Surveys |
| Monitoring | Session Replay, Error Tracking, Alerts |

Drawer includes a **project switcher** at the top (logo, project name, org, region).

### Navigation Behavior

- Bottom tabs use `StatefulShellBranch` (GoRouter) — each tab preserves its own navigation stack.
- Drawer items push full-screen routes outside the shell (replacing the tab bar). The hamburger ☰ icon remains accessible in the app bar of drawer-pushed routes so users can navigate to other sections without going back.
- Tapping a dashboard tile navigates to Insight Detail within the Home tab stack.
- Back button pops within the current tab/stack; long-press goes to tab root.

### Project Switching

- Switching projects clears all cached state (all Resources are invalidated and re-fetched).
- The selected project ID is persisted in secure storage across app restarts.
- During switch: show loading indicator on current screen while data re-fetches.

## Screen Inventory

### Tier 1 — Core MVP

**9 screens** (including App Shell scaffold) that make Hoglet useful from day one.

#### 1. Welcome / Connect (Onboarding)
- Region picker: US Cloud, EU Cloud, Self-hosted (custom URL)
- Personal API key input with visibility toggle
- Project selector (fetched via `GET /api/projects/` after successful connection test)
- "Test Connection" button with success/error feedback
- Persists credentials in secure storage
- Shows on first launch or when no credentials exist

#### 2. App Shell (structural scaffold)
- Scaffold with bottom NavigationBar (4 tabs) and Drawer
- GoRouter ShellRoute wrapping all tab content
- Drawer with sectioned navigation + project switcher
- Hamburger icon in app bar opens drawer

#### 3. Dashboard List (Home tab root)
- Fetches all dashboards via dashboards endpoint
- Search/filter bar at top
- Pinned/favorite dashboards shown first
- Each card shows: name, description snippet, tile count, last modified
- Pull-to-refresh
- Tap → Dashboard Detail

#### 4. Dashboard Detail
- Fetches single dashboard with its insight tiles
- Vertical scrolling layout of insight tiles
- Each tile renders a compact chart (trend line, number, funnel bar, table)
- Date range filter (Last 7d, 30d, 90d, custom)
- Refresh button
- Tap tile → Insight Detail

#### 5. Insight Detail
- Fetches insight data
- MVP chart types: Trends (line/bar), Funnels (horizontal bar), Number (styled card)
- Deferred chart types: Retention (table), Lifecycle, Paths, Stickiness — show "View on web" placeholder
- Date range picker
- Filter/breakdown summary (read-only)
- Supports landscape mode for wider chart viewing
- Shared screen — reachable from Dashboard Detail, Saved Insights List, or deep links

#### 6. Events Stream (Activity tab — exists, needs refactor)
- Already built: events table, column config, event detail bottom sheet
- Refactor into new navigation structure (move from being the main screen to Activity tab)
- Keep existing functionality: HogQL query, column drag-to-reorder, property discovery

#### 7. Feature Flags List (Flags tab root)
- Fetches flags via feature_flags endpoint
- Search/filter bar
- Each row: flag key, name, active/inactive badge, rollout % indicator
- Quick toggle switch per flag (PATCH active field)
- Tap → Feature Flag Detail

#### 8. Feature Flag Detail
- Flag key, name, description
- Enable/disable toggle (the one write operation)
- Release conditions display (read-only): match groups, properties, percentages
- Rollout percentage visualization
- Linked experiments list
- Activity log (recent changes)

#### 9. Settings (exists as modal — promote to full screen)
- Connection settings: region, API key, custom host
- Project switcher (if multiple projects)
- Theme toggle (light/dark)
- About: version, links to GitHub repo, PostHog docs
- Sign out / disconnect

### Tier 2 — Essential Expansion

**6 screens** that round out the experience.

#### 10. Persons List
- Search by email, name, distinct_id
- Person cards: avatar/initial, email, last seen time
- Filter by cohort (optional)
- Tap → Person Detail

#### 11. Person Detail
- Properties table (all person properties)
- Event timeline (recent events for this person)
- Session history
- Cohort memberships
- Feature flag overrides for this person

#### 12. Saved Insights List
- All insights with search/filter
- Type badge per insight (Trends, Funnels, Retention, Lifecycle, Paths, Stickiness)
- Last modified date
- Tap → Insight Detail (shared with Tier 1)

#### 13. Session Replay List
- Recent recordings sorted by date
- Each row: user info, duration, page count, start URL
- Date/user filter
- Tap → Replay Player

#### 14. Session Replay Player
- **Requires technical spike before implementation** to evaluate rrweb replay feasibility on mobile
- Preferred approach: rrweb snapshot playback via WebView
- Fallback if infeasible: screenshot timeline + event list (no DOM replay)
- Event timeline scrubber at bottom
- Console logs panel (collapsible)
- Supports landscape mode

#### 15. Experiments List + Detail
- Active/completed experiments list
- Detail: variant names, participant counts, conversion rates
- Statistical significance indicator
- Linked feature flag reference
- Results chart (bar chart comparing variants)

### Tier 3 — Full Coverage

**6 screens** to complete the PostHog experience.

#### 16. Cohorts List + Detail
- List with name, person count, type (static/dynamic)
- Detail: filter criteria summary, person count, matching persons preview

#### 17. Surveys List + Results
- List with name, type, response count, status
- Results: response summary, completion rate, individual responses

#### 18. Error Tracking
- Error groups list: fingerprint, count, first/last seen
- Detail: stack trace, occurrence timeline, affected users count

#### 19. Alerts List + Detail
- Alert list: name, status (firing/ok), linked insight
- Detail: threshold config, history of triggers

#### 20. Web Analytics
- Traffic overview: unique visitors, pageviews, sessions
- Top pages table
- Top referrers
- Device/browser breakdown

#### 21. Annotations
- Timeline markers visible on insight charts
- List view of all annotations with date and content

## Architecture

### Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter (Dart) | Already in use. Cross-platform iOS + Android. |
| State Management | solidart / flutter_solidart | Signals-based reactivity. Signal, Computed, Resource for async. |
| Routing | go_router | ShellRoute for bottom tabs, StatefulShellBranch per tab. |
| Charts | fl_chart | Native Flutter charts: line, bar, pie. Funnels as custom stacked bars. |
| HTTP | http (existing) | Keep existing package. Simple and sufficient. |
| Storage | flutter_secure_storage (existing) | Secure credential persistence. |
| DI | Solid widget (flutter_solidart) | Provides services at app root. |

### Project Structure

```
lib/
├── app.dart                    // MaterialApp, theme, Solid providers
├── main.dart                   // Entry point
│
├── routing/
│   ├── app_router.dart         // GoRouter: ShellRoute + branches
│   └── route_names.dart        // Named route constants
│
├── models/                     // Plain Dart data classes
│   ├── dashboard.dart
│   ├── insight.dart            // + InsightResult for chart data
│   ├── event_item.dart         // ✅ exists
│   ├── feature_flag.dart
│   ├── person.dart
│   ├── column_spec.dart        // Extracted from activity_screen.dart
│   ├── host_mode.dart          // Extracted — shared with onboarding/settings
│   ├── experiment.dart         // Tier 2+
│   ├── session_recording.dart  // Tier 2+
│   ├── cohort.dart             // Tier 3
│   ├── survey.dart             // Tier 3
│   └── error_group.dart        // Tier 3
│
├── services/                   // Pure async — no signals
│   ├── posthog_client.dart     // ✅ exists — extend with all endpoints
│   ├── auth_service.dart       // API key storage, connection test
│   └── storage_service.dart    // Secure storage wrapper
│
├── state/                      // Signals, Computed, Resources
│   ├── auth_state.dart         // Connection/auth signals
│   ├── dashboard_state.dart    // Resource<List<Dashboard>>
│   ├── insights_state.dart
│   ├── events_state.dart
│   ├── flags_state.dart
│   └── persons_state.dart
│   // Each new domain follows the same pattern: {domain}_state.dart
│   // Tier 2/3 state files added in later phases
│
├── screens/
│   ├── shell/
│   │   ├── app_shell.dart      // Scaffold + bottom tabs + drawer
│   │   └── app_drawer.dart     // Navigation drawer content
│   ├── onboarding/
│   │   └── welcome_screen.dart
│   ├── home/
│   │   ├── dashboard_list_screen.dart
│   │   └── dashboard_detail_screen.dart
│   ├── activity/
│   │   └── activity_screen.dart    // ✅ exists — refactor
│   ├── flags/
│   │   ├── flags_list_screen.dart
│   │   └── flag_detail_screen.dart
│   ├── insights/
│   │   ├── insights_list_screen.dart
│   │   └── insight_detail_screen.dart
│   ├── persons/
│   │   ├── persons_list_screen.dart
│   │   └── person_detail_screen.dart
│   ├── recordings/
│   │   ├── recordings_list_screen.dart
│   │   └── replay_player_screen.dart
│   ├── experiments/
│   │   └── experiments_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
└── widgets/                    // Reusable components
    ├── insight_card.dart       // Compact chart card for dashboard tiles
    ├── chart_renderer.dart     // Line, bar, funnel, number renderers
    ├── search_bar.dart
    ├── status_badge.dart
    ├── loading_states.dart     // Shimmer/skeleton screens
    └── error_view.dart
```

### Data Flow

```
PostHog API → PosthogClient (services/) → Resource/Signal (state/) → ResourceBuilder/SignalBuilder (screens/)
```

- **Services** are pure async. They take parameters, call HTTP, return model objects. No signals.
- **State** layer creates `Resource` instances that wrap service calls. `Resource` auto-manages loading/error/ready states. `source` parameter triggers re-fetch when dependencies change (e.g., project ID switch).
- **Screens** use `ResourceBuilder` for async data and `SignalBuilder` for reactive UI. `Show` widget for conditional rendering (e.g., logged in vs not).
- **Solid widget** at app root provides `PosthogClient` and `AuthService` via DI. Screens access via `context.get<T>()`.

### Pagination

PostHog API uses cursor-based pagination (`next` URL in response body). Strategy per list screen:

- **Infinite scroll** for all list screens (dashboards, insights, flags, persons, events, etc.)
- Custom `PaginatedSignal<T>` pattern wrapping: `ListSignal<T>` (accumulated items) + `Signal<String?>` (next cursor) + `Signal<bool>` (isLoadingMore)
- `Resource` is used for the initial fetch; subsequent pages are appended via `loadMore()` method on the paginated signal
- The existing `_fetchPagedResults` pattern in `PosthogClient` is extended to all list endpoints
- Pull-to-refresh resets cursor and re-fetches from the beginning

### Chart Rendering Strategy

**MVP supported types:**
| PostHog Type | Rendering | fl_chart widget |
|---|---|---|
| Trends | Line chart or bar chart | LineChart / BarChart |
| Funnels | Horizontal stacked bars | BarChart (horizontal) |
| Number | Styled text card with delta | Custom widget (no chart) |

**Deferred types (show placeholder card with "View on web" link):**
- Retention (grid table — needs custom widget, not a chart)
- Lifecycle (stacked bar — doable but lower priority)
- Paths (Sankey/network diagram — fl_chart does not support)
- Stickiness (bar chart variant — doable but lower priority)

**InsightResult model:** Parsed from the insight API response's `result` field. Contains series data (labels, values, timestamps) that maps to fl_chart's `FlSpot` / `BarChartGroupData`.

### Error Handling

**Typed error hierarchy:**
- `PosthogApiError` — base class with status code and message
- `AuthenticationError` (401/403) — triggers redirect to onboarding, clears credentials
- `RateLimitError` (429) — shows "Too many requests, try again in X seconds" with retry-after
- `NetworkError` — connection timeout, no internet. Distinct from API errors.

**Policies:**
- HTTP timeout: 15 seconds for list endpoints, 30 seconds for query/heavy endpoints
- 401 handling: clear stored credentials, redirect to Welcome screen
- 429 handling: parse `Retry-After` header, show countdown toast
- All `ResourceBuilder` screens show error state with retry button
- Network errors show distinct "No connection" state

### Caching

MVP approach — in-memory only, no persistent cache:
- `Resource` instances hold their last successful value in memory
- On re-fetch failure, stale data is shown with an "Update failed" banner
- Project switch invalidates all Resources (triggers fresh fetches)
- No SQLite/Hive persistent cache for MVP — add in Phase 6 if needed

### API Endpoints

> **Note:** Endpoint paths must be verified against PostHog API docs during implementation. The existing query endpoint uses `/api/projects/{id}/query/` (not environments). Other endpoints may use `projects` or `environments` — verify each one.

#### Tier 1 (MVP)
```
GET   /api/projects/                                 # project discovery for onboarding
GET   /api/organizations/                            # org info for project switcher
GET   /api/environments/{id}/dashboards/
GET   /api/environments/{id}/dashboards/{id}/
GET   /api/environments/{id}/insights/
GET   /api/environments/{id}/insights/{id}/
POST  /api/projects/{id}/query/                      # ✅ exists (HogQL)
GET   /api/environments/{id}/feature_flags/
GET   /api/environments/{id}/feature_flags/{id}/
PATCH /api/environments/{id}/feature_flags/{id}/     # toggle active
```

#### Tier 2
```
GET   /api/environments/{id}/persons/
GET   /api/environments/{id}/persons/{id}/
GET   /api/environments/{id}/session_recordings/
GET   /api/environments/{id}/session_recordings/{id}/
GET   /api/environments/{id}/session_recordings/{id}/snapshots/
GET   /api/environments/{id}/experiments/
```

#### Tier 3
```
GET   /api/environments/{id}/cohorts/
GET   /api/environments/{id}/surveys/
GET   /api/environments/{id}/error_tracking/groups/
GET   /api/environments/{id}/alerts/
```

### UX Patterns

- **Pull-to-refresh** on all list screens
- **Skeleton/shimmer loading** — no blank screens, show content shape while loading
- **Bottom sheets** for detail views where appropriate (event detail, quick actions)
- **Landscape mode** for chart screens (insight detail, replay player)
- **Haptic feedback** on feature flag toggle
- **Swipe-to-go-back** on detail screens
- **Error states** with retry button on all Resource-backed screens
- **Empty states** with helpful messaging ("No dashboards yet — create one in PostHog web")

### Theme

Preserve existing Hoglet brand:
- Primary: `#F15A24` (orange)
- Background: `#F5F4EF` (light beige) / dark mode TBD
- Font: Space Grotesk (Google Fonts)
- Material 3 design language

### Testing Strategy

- **Models:** fromJson/toJson round-trip tests for all data classes
- **Services:** Mock HTTP tests for each PosthogClient method
- **Widgets:** Widget tests for critical flows (onboarding, flag toggle, dashboard navigation)
- **Integration:** Golden tests deferred to Phase 6

### Deep Linking

Deferred to Phase 6. Routes should be designed with path-based patterns (e.g., `/dashboard/:id`, `/flag/:id`) to make deep link support straightforward when added.

## Implementation Order

Stacking PR workflow: each phase is a branch stacked on the previous.

### Phase 0: Foundation
- Add dependencies: `flutter_solidart`, `go_router`, `fl_chart`
- Extract shared models from activity_screen.dart: `ColumnSpec`, `ColumnOption`, `ColumnCategory`, `BuiltinColumnId`, `ColumnKind` → `models/column_spec.dart`; `HostMode` → `models/host_mode.dart`
- Extract settings/storage logic into `auth_service.dart` and `storage_service.dart`
- Set up project structure (routing/, state/, screens/shell/)
- Implement AppShell with bottom tabs + drawer skeleton
- Migrate existing Settings from modal to Settings tab
- Wire up Solid DI at app root
- Add `GET /api/projects/` and `GET /api/organizations/` to PosthogClient for onboarding

### Phase 1: Dashboard (Home tab)
- Dashboard model + PosthogClient endpoints
- dashboard_state.dart with Resource
- Dashboard List screen with pagination
- Dashboard Detail screen with compact insight tiles
- Insight Detail screen with chart_renderer widget (Trends, Funnels, Number)
- "View on web" placeholder for unsupported insight types

### Phase 2: Feature Flags (Flags tab)
- FeatureFlag model + PosthogClient endpoints
- flags_state.dart with Resource
- Flags List screen with search + quick toggle
- Flag Detail screen

### Phase 3: Activity tab refactor
- Migrate existing Events screen into Activity tab
- Refactor to use solidart state management
- Ensure it works within the new navigation structure

### Phase 4: Tier 2 screens
- Persons List + Detail
- Saved Insights List (reuse Insight Detail)
- Technical spike: Session Replay Player feasibility (rrweb via WebView vs screenshot fallback)
- Session Replay List + Player (based on spike results)
- Experiments List + Detail

### Phase 5: Tier 3 screens
- Cohorts, Surveys, Error Tracking, Alerts, Web Analytics, Annotations

### Phase 6: Polish
- Onboarding flow improvements
- Dark mode
- Landscape chart support
- Deep linking support
- Persistent cache (if needed)
- Performance optimization
- App store preparation
