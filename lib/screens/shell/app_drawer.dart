import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DrawerHeader(theme: theme),
          _SectionHeader('PRODUCT ANALYTICS'),
          _DrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboards',
            onTap: () => _navigateToTab(context, 0),
          ),
          _DrawerItem(
            icon: Icons.insights,
            label: 'Insights',
            onTap: () => _navigateToRoute(context, '/insights'),
          ),
          _DrawerItem(
            icon: Icons.language,
            label: 'Web Analytics',
            onTap: () => _showComingSoon(context, 'Web Analytics'),
          ),
          _SectionHeader('DATA'),
          _DrawerItem(
            icon: Icons.bolt,
            label: 'Events',
            onTap: () => _navigateToTab(context, 1),
          ),
          _DrawerItem(
            icon: Icons.person,
            label: 'Persons',
            onTap: () => _navigateToRoute(context, '/persons'),
          ),
          _DrawerItem(
            icon: Icons.people,
            label: 'Cohorts',
            onTap: () => _navigateToRoute(context, '/cohorts'),
          ),
          _SectionHeader('FEATURE MANAGEMENT'),
          _DrawerItem(
            icon: Icons.flag,
            label: 'Feature Flags',
            onTap: () => _navigateToTab(context, 2),
          ),
          _DrawerItem(
            icon: Icons.science,
            label: 'Experiments',
            onTap: () => _showComingSoon(context, 'Experiments'),
          ),
          _DrawerItem(
            icon: Icons.assignment,
            label: 'Surveys',
            onTap: () => _showComingSoon(context, 'Surveys'),
          ),
          _SectionHeader('MONITORING'),
          _DrawerItem(
            icon: Icons.videocam,
            label: 'Session Replay',
            onTap: () => _showComingSoon(context, 'Session Replay'),
          ),
          _DrawerItem(
            icon: Icons.bug_report,
            label: 'Error Tracking',
            onTap: () => _showComingSoon(context, 'Error Tracking'),
          ),
          _DrawerItem(
            icon: Icons.notifications,
            label: 'Alerts',
            onTap: () => _showComingSoon(context, 'Alerts'),
          ),
          _DrawerItem(
            icon: Icons.local_fire_department,
            label: 'Heatmaps',
            isLinkOut: true,
            onTap: () => _showComingSoon(context, 'Heatmaps'),
          ),
          _SectionHeader('DATA & TOOLS'),
          _DrawerItem(
            icon: Icons.code,
            label: 'SQL Editor',
            onTap: () => _showComingSoon(context, 'SQL Editor'),
          ),
          _DrawerItem(
            icon: Icons.edit_note,
            label: 'Annotations',
            onTap: () => _showComingSoon(context, 'Annotations'),
          ),
          _DrawerItem(
            icon: Icons.sync_alt,
            label: 'Data Pipelines',
            isLinkOut: true,
            onTap: () => _showComingSoon(context, 'Data Pipelines'),
          ),
          _DrawerItem(
            icon: Icons.book,
            label: 'Notebooks',
            isLinkOut: true,
            onTap: () => _showComingSoon(context, 'Notebooks'),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '↗ opens in PostHog web',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pop(); // close drawer
    final shell = StatefulNavigationShell.maybeOf(context);
    shell?.goBranch(tabIndex, initialLocation: true);
  }

  void _navigateToRoute(BuildContext context, String path) {
    Navigator.of(context).pop(); // close drawer
    GoRouter.of(context).push(path);
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.of(context).pop(); // close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final ThemeData theme;

  const _DrawerHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🦔 Hoglet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PostHog Mobile',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Switch Project ▾',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLinkOut;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.isLinkOut = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Row(
        children: [
          Text(label),
          if (isLinkOut) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ],
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
