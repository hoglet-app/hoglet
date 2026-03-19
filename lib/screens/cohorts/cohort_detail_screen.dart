import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/open_in_posthog.dart';
import '../../widgets/shimmer_list.dart';

class CohortDetailScreen extends StatefulWidget {
  final String cohortId;
  const CohortDetailScreen({super.key, required this.cohortId});

  @override
  State<CohortDetailScreen> createState() => _CohortDetailScreenState();
}

class _CohortDetailScreenState extends State<CohortDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    final id = int.tryParse(widget.cohortId);
    if (id == null) return;
    providers.cohortsState.fetchCohort(providers.client, credentials.host, credentials.projectId, credentials.apiKey, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).cohortsState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final cohort = state.cohort.value;
      final persons = state.cohortPersons.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(cohort?.name ?? 'Cohort'),
          actions: [
            OpenInPostHogButton(path: '/cohorts/${widget.cohortId}'),
          ],
        ),
        body: () {
          if (isLoading && cohort == null) return const ShimmerList(itemCount: 4);
          if (error != null && cohort == null) return ErrorView(error: error, onRetry: _load);
          if (cohort == null) return const Center(child: Text('Cohort not found'));

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cohort.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (cohort.isStatic ? Colors.grey : Colors.blue).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                cohort.typeLabel,
                                style: TextStyle(
                                  color: cohort.isStatic ? Colors.grey : Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.people, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text('${cohort.count} persons', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (cohort.description != null && cohort.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(cohort.description!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ],
                    ),
                  ),
                ),

                // Filter criteria
                if (cohort.filters != null) ...[
                  const SizedBox(height: 16),
                  Text('MATCHING CRITERIA', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  _CriteriaCard(filters: cohort.filters!, theme: theme),
                ],

                // Details
                const SizedBox(height: 16),
                Text('DETAILS', style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Type', value: cohort.isStatic ? 'Static (manually curated)' : 'Dynamic (auto-updating)', theme: theme),
                        if (cohort.createdAt != null)
                          _DetailRow(
                            label: 'Created',
                            value: '${cohort.createdAt!.year}-${cohort.createdAt!.month.toString().padLeft(2, '0')}-${cohort.createdAt!.day.toString().padLeft(2, '0')}',
                            theme: theme,
                          ),
                        _DetailRow(label: 'ID', value: cohort.id.toString(), theme: theme),
                      ],
                    ),
                  ),
                ),

                // Members
                if (persons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('MEMBERS (${persons.length}${persons.length >= 20 ? '+' : ''})', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  ...persons.take(20).map((p) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Text(p.initial, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                      ),
                      title: Text(p.displayName, style: theme.textTheme.bodyMedium),
                      subtitle: p.distinctIds.isNotEmpty
                          ? Text(p.distinctIds.first, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontFamily: 'monospace', color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))
                          : null,
                    ),
                  )),
                  if (persons.length > 20)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('+ ${persons.length - 20} more', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                    ),
                ],
              ],
            ),
          );
        }(),
      );
    });
  }
}

class _CriteriaCard extends StatelessWidget {
  final Map<String, dynamic> filters;
  final ThemeData theme;
  const _CriteriaCard({required this.filters, required this.theme});

  @override
  Widget build(BuildContext context) {
    final groups = filters['properties'] as Map<String, dynamic>? ?? {};
    final groupType = groups['type']?.toString();
    final values = groups['values'] as List? ?? [];

    if (values.isEmpty) {
      // Try flat filter format
      final flatProps = filters['properties'] as List?;
      if (flatProps != null && flatProps.isNotEmpty) {
        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: flatProps.whereType<Map<String, dynamic>>().map((prop) {
                return _PropertyRow(prop: prop, theme: theme);
              }).toList(),
            ),
          ),
        );
      }
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('All users', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return Column(
      children: values.asMap().entries.map((entry) {
        final group = entry.value;
        if (group is! Map<String, dynamic>) return const SizedBox.shrink();

        final innerType = group['type']?.toString() ?? 'AND';
        final innerValues = group['values'] as List? ?? [];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.key > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(groupType?.toUpperCase() ?? 'OR', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue)),
                    ),
                  ),
                ...innerValues.whereType<Map<String, dynamic>>().map((prop) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _PropertyRow(prop: prop, theme: theme),
                  );
                }),
                if (innerValues.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Joined by ${innerType.toUpperCase()}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final Map<String, dynamic> prop;
  final ThemeData theme;
  const _PropertyRow({required this.prop, required this.theme});

  @override
  Widget build(BuildContext context) {
    final key = prop['key']?.toString() ?? '';
    final operator = prop['operator']?.toString() ?? 'exact';
    final value = prop['value'];
    final valueStr = value is List ? value.join(', ') : value?.toString() ?? '';
    final type = prop['type']?.toString() ?? 'person';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _typeColor(type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _typeColor(type))),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: key, style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12, color: theme.colorScheme.onSurface)),
              TextSpan(text: ' $operator ', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
              TextSpan(text: valueStr, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: theme.colorScheme.primary)),
            ]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'person': return Colors.purple;
      case 'event': return Colors.blue;
      case 'cohort': return Colors.teal;
      case 'group': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _DetailRow({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
