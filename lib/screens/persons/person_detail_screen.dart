import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../models/event_item.dart';
import '../../widgets/error_view.dart';
import '../../widgets/open_in_posthog.dart';
import '../../widgets/property_table.dart';
import '../../widgets/shimmer_list.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  List<EventItem> _recentEvents = [];
  bool _loadingEvents = false;

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
    await providers.personsState.fetchPerson(providers.client, credentials.host, credentials.projectId, credentials.apiKey, id);
    _loadPersonEvents();
  }

  Future<void> _loadPersonEvents() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    final person = providers.personsState.person.value;
    if (credentials == null || person == null || person.distinctIds.isEmpty) return;

    setState(() => _loadingEvents = true);
    try {
      final events = await providers.client.fetchPersonEvents(
        credentials.host, credentials.projectId, credentials.apiKey,
        person.distinctIds.first,
      );
      if (mounted) setState(() => _recentEvents = events);
    } catch (_) {
      // Non-critical — just show empty
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
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
        appBar: AppBar(
          title: Text(person?.displayName ?? 'Person'),
          actions: [
            OpenInPostHogButton(path: '/person/${widget.personId}'),
          ],
        ),
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
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PropertyTable(properties: person.properties),
                  ),
                ),

                // Recent Events Timeline
                const SizedBox(height: 24),
                Text('RECENT EVENTS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 8),
                if (_loadingEvents)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_recentEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No recent events', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  )
                else
                  ...List.generate(
                    _recentEvents.length > 20 ? 20 : _recentEvents.length,
                    (i) {
                      final event = _recentEvents[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              event.event.startsWith('\$') ? Icons.analytics : Icons.bolt,
                              size: 16,
                              color: event.event.startsWith('\$') ? Colors.blue : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.event,
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              event.timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
