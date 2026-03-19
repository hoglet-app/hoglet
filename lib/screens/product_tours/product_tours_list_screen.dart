import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ProductToursListScreen extends StatefulWidget {
  const ProductToursListScreen({super.key});
  @override
  State<ProductToursListScreen> createState() => _ProductToursListScreenState();
}

class _ProductToursListScreenState extends State<ProductToursListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.productToursState.fetchTours(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).productToursState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Tours'),
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showArchived = !_showArchived),
            child: Text(_showArchived ? 'Active' : 'Archived'),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'Search tours...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(child: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.tours.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.tours.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);

        var filtered = state.tours.value.where((t) => t.archived == _showArchived).toList();
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered.where((t) => t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)).toList();
        }
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.tour_outlined,
            title: _searchQuery.isNotEmpty ? 'No matching tours' : (_showArchived ? 'No archived tours' : 'No product tours'),
            message: _searchQuery.isEmpty && !_showArchived ? 'Create tours in PostHog web' : null,
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final tour = filtered[i];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            tour.type == 'announcement' ? Icons.campaign : Icons.tour,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tour.name,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: tour.status),
                        ],
                      ),
                      if (tour.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tour.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.layers, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            '${tour.stepCount} step${tour.stepCount == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          if (tour.autoLaunch) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.play_circle_outline, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Auto-launch',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          if (tour.hasDraft) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.edit, size: 14, color: Colors.orange.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Has draft',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      })),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Running':
        color = Colors.green;
      case 'Draft':
        color = Colors.orange;
      case 'Stopped':
        color = Colors.red;
      case 'Archived':
        color = Colors.grey;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
