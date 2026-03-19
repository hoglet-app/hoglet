import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ActionsListScreen extends StatefulWidget {
  const ActionsListScreen({super.key});
  @override
  State<ActionsListScreen> createState() => _ActionsListScreenState();
}

class _ActionsListScreenState extends State<ActionsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    p.actionsState.fetchActions(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).actionsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Actions'), leading: const BackButton()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'Search actions...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(child: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.actions.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.actions.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        var actions = state.actions.value;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          actions = actions.where((a) => a.name.toLowerCase().contains(q) || (a.description?.toLowerCase().contains(q) ?? false) || a.tags.any((t) => t.toLowerCase().contains(q))).toList();
        }
        if (actions.isEmpty) return EmptyState(icon: Icons.touch_app_outlined, title: _searchQuery.isNotEmpty ? 'No matching actions' : 'No actions defined');
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            itemBuilder: (context, i) {
              final action = state.actions.value[i];
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
                          Icon(Icons.touch_app, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action.name,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (action.verified == true)
                            Icon(Icons.verified, size: 16, color: Colors.green.shade600),
                          if (action.count != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${action.count}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (action.description != null && action.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          action.description!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (action.steps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...action.steps.take(3).map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            step.summary,
                            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      if (action.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: action.tags.take(5).map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 10)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                      ],
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
