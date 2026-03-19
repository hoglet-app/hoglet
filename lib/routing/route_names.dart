abstract class RouteNames {
  // Bottom tabs
  static const home = 'home';
  static const activity = 'activity';
  static const flags = 'flags';
  static const settings = 'settings';

  // Onboarding
  static const welcome = 'welcome';

  // Home tab stack
  static const dashboardDetail = 'dashboardDetail';
  static const insightDetail = 'insightDetail';

  // Flags tab stack
  static const flagDetail = 'flagDetail';

  // Drawer routes (full-screen, outside shell)
  static const insights = 'insights';
  static const persons = 'persons';
  static const personDetail = 'personDetail';
  static const cohorts = 'cohorts';
  static const cohortDetail = 'cohortDetail';
  static const experiments = 'experiments';
  static const experimentDetail = 'experimentDetail';
  static const surveys = 'surveys';
  static const surveyDetail = 'surveyDetail';
  static const recordings = 'recordings';
  static const errorTracking = 'errorTracking';
  static const errorDetail = 'errorDetail';
  static const alerts = 'alerts';
  static const alertDetail = 'alertDetail';
  static const webAnalytics = 'webAnalytics';
  static const sqlEditor = 'sqlEditor';
  static const annotations = 'annotations';
}

abstract class RoutePaths {
  // Bottom tabs
  static const home = '/home';
  static const activity = '/activity';
  static const flags = '/flags';
  static const settings = '/settings';

  // Onboarding
  static const welcome = '/welcome';

  // Home tab nested
  static const dashboardDetail = 'dashboard/:dashboardId';
  static const insightDetail = 'insight/:insightId';

  // Flags tab nested
  static const flagDetail = 'flag/:flagId';

  // Drawer routes
  static const insights = '/insights';
  static const persons = '/persons';
  static const personDetail = ':personId';
  static const cohorts = '/cohorts';
  static const cohortDetail = ':cohortId';
  static const experiments = '/experiments';
  static const experimentDetail = ':experimentId';
  static const surveys = '/surveys';
  static const surveyDetail = ':surveyId';
  static const recordings = '/recordings';
  static const errorTracking = '/error-tracking';
  static const errorDetail = ':errorId';
  static const alerts = '/alerts';
  static const alertDetail = ':alertId';
  static const webAnalytics = '/web-analytics';
  static const sqlEditor = '/sql';
  static const annotations = '/annotations';
}
