import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class EarlyAccessListScreen extends StatefulWidget {
  const EarlyAccessListScreen({super.key});
  @override
  State<EarlyAccessListScreen> createState() => _EarlyAccessListScreenState();
}

class _EarlyAccessListScreenState extends State<EarlyAccessListScreen> {
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
    p.earlyAccessState.fetchFeatures(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).earlyAccessState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Early Access Features'), leading: const BackButton()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'Search features...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(child: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.features.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.features.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        var features = state.features.value;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          features = features.where((f) => f.name.toLowerCase().contains(q) || f.description.toLowerCase().contains(q)).toList();
        }
        if (features.isEmpty) return EmptyState(icon: Icons.new_releases_outlined, title: _searchQuery.isNotEmpty ? 'No matching features' : 'No early access features');
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: features.length,
            itemBuilder: (context, i) {
              final feature = state.features.value[i];
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
                          Expanded(
                            child: Text(
                              feature.name,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StageBadge(stage: feature.stage, label: feature.stageLabel),
                        ],
                      ),
                      if (feature.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          feature.description,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (feature.featureFlagKey != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.flag, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              feature.featureFlagKey!,
                              style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
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

class _StageBadge extends StatelessWidget {
  final String stage;
  final String label;
  const _StageBadge({required this.stage, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (stage) {
      case 'beta':
        color = Colors.orange;
      case 'general-availability':
        color = Colors.green;
      case 'archived':
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
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
