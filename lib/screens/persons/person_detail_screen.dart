import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/property_table.dart';
import '../../widgets/shimmer_list.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    final id = int.tryParse(widget.personId);
    if (id == null) return;
    providers.personsState.fetchPerson(providers.client, credentials.host, credentials.projectId, credentials.apiKey, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).personsState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final person = state.person.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(title: Text(person?.displayName ?? 'Person')),
        body: () {
          if (isLoading && person == null) return const ShimmerList(itemCount: 4);
          if (error != null && person == null) return ErrorView(error: error, onRetry: _load);
          if (person == null) return const Center(child: Text('Person not found'));

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + name
                Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(person.initial, style: TextStyle(fontSize: 24, color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(person.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                if (person.distinctIds.isNotEmpty)
                  Center(child: Text(person.distinctIds.first, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                const SizedBox(height: 24),

                // Properties
                Text('PROPERTIES', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 8),
                Card(
                  elevation: 0, color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PropertyTable(properties: person.properties),
                  ),
                ),

                // Distinct IDs
                if (person.distinctIds.length > 1) ...[
                  const SizedBox(height: 24),
                  Text('DISTINCT IDS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  ...person.distinctIds.map((id) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(id, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                  )),
                ],
              ],
            ),
          );
        }(),
      );
    });
  }
}
