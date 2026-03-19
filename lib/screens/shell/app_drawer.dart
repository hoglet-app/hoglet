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
            _comingSoonItem(context, Icons.insights_outlined, 'Insights'),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Data'),
            _drawerItem(context, Icons.bolt_outlined, 'Events', RouteNames.activity),
            _comingSoonItem(context, Icons.person_outline, 'Persons'),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Features'),
            _drawerItem(context, Icons.flag_outlined, 'Feature Flags', RouteNames.flags),
            _comingSoonItem(context, Icons.science_outlined, 'Experiments'),
            const Divider(color: Color(0xFFE3DED6)),
            _sectionLabel('Monitoring'),
            _comingSoonItem(context, Icons.videocam_outlined, 'Session Replay'),
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

  Widget _drawerItem(BuildContext context, IconData icon, String label, String route) {
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

  Widget _comingSoonItem(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9E9890)),
      title: Text(
        label,
        style: const TextStyle(color: Color(0xFF9E9890)),
      ),
      dense: true,
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label is coming soon.')),
        );
      },
    );
  }
}
