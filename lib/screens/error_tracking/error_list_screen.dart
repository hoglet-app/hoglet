import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
import '../../models/error_group.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ErrorListScreen extends StatefulWidget {
  const ErrorListScreen({super.key});
  @override
  State<ErrorListScreen> createState() => _ErrorListScreenState();
}

class _ErrorListScreenState extends State<ErrorListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.errorTrackingState.fetchErrors(p.client, c.host, c.projectId, c.apiKey);
  }

  List<ErrorGroup> _filtered(List<ErrorGroup> errors) {
    var result = errors;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) => (e.title?.toLowerCase().contains(q) ?? false) || e.fingerprint.toLowerCase().contains(q)).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((e) => e.status == _statusFilter).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).errorTrackingState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Error Tracking'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search errors...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final entry in {'all': 'All', 'active': 'Active', 'resolved': 'Resolved'}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = entry.key),
                      child: Chip(
                        label: Text(entry.value, style: TextStyle(fontSize: 12, color: _statusFilter == entry.key ? Colors.white : null, fontWeight: _statusFilter == entry.key ? FontWeight.w600 : FontWeight.normal)),
                        backgroundColor: _statusFilter == entry.key ? theme.colorScheme.primary : null,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoading.value && state.errors.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.errors.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
              final errors = _filtered(state.errors.value);
              if (errors.isEmpty) return EmptyState(icon: Icons.bug_report_outlined, title: _searchQuery.isNotEmpty ? 'No matching errors' : 'No errors tracked');

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: errors.length,
                  itemBuilder: (context, i) {
                    final err = errors[i];
                    final statusColor = err.status == 'active' ? Colors.red : err.status == 'resolved' ? Colors.green : Colors.orange;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pushNamed(RouteNames.errorDetail, pathParameters: {'errorId': err.id}),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6, right: 8),
                                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                  ),
                                  Expanded(
                                    child: Text(
                                      err.title ?? err.fingerprint,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.repeat, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Text('${err.occurrences}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                  if (err.affectedUsers != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.people, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                    const SizedBox(width: 4),
                                    Text('${err.affectedUsers}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                  ],
                                  if (err.lastSeen != null) ...[
                                    const Spacer(),
                                    Text(_timeAgo(err.lastSeen!), style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
