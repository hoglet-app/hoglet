import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ErrorListScreen extends StatefulWidget {
  const ErrorListScreen({super.key});
  @override State<ErrorListScreen> createState() => _ErrorListScreenState();
}

class _ErrorListScreenState extends State<ErrorListScreen> {
  @override void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    p.errorTrackingState.fetchErrors(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).errorTrackingState;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Error Tracking'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.errors.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.errors.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.errors.value.isEmpty) return const EmptyState(icon: Icons.bug_report_outlined, title: 'No errors tracked');
        return RefreshIndicator(onRefresh: _load, child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: state.errors.value.length,
          itemBuilder: (context, i) {
            final err = state.errors.value[i];
            return Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
              child: ListTile(
                leading: Icon(Icons.bug_report, color: theme.colorScheme.error, size: 22),
                title: Text(err.title ?? err.fingerprint, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${err.occurrences} occurrences${err.lastSeen != null ? ' · last ${_timeAgo(err.lastSeen!)}' : ''}', style: theme.textTheme.bodySmall),
                onTap: () => context.pushNamed(RouteNames.errorDetail, pathParameters: {'errorId': err.id}),
              ),
            );
          },
        ));
      }),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
