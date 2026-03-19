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
