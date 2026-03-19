import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class PersonsListScreen extends StatefulWidget {
  const PersonsListScreen({super.key});

  @override
  State<PersonsListScreen> createState() => _PersonsListScreenState();
}

class _PersonsListScreenState extends State<PersonsListScreen> {
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPersons();
  }

  Future<void> _loadPersons({String? search}) async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    providers.personsState.fetchPersons(providers.client, credentials.host, credentials.projectId, credentials.apiKey, search: search);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).personsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Persons'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email, name, or distinct ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadPersons();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) => _loadPersons(search: value.isNotEmpty ? value : null),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context, _) {
                if (state.isLoading.value && state.persons.value.isEmpty) return const ShimmerList();
                if (state.error.value != null && state.persons.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _loadPersons);
                if (state.persons.value.isEmpty) return const EmptyState(icon: Icons.person_outlined, title: 'No persons found');

                final showLoadMore = state.hasMore.value;
                final itemCount = state.persons.value.length + (showLoadMore ? 1 : 0);

                return RefreshIndicator(
                  onRefresh: _loadPersons,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= state.persons.value.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SignalBuilder(builder: (context, _) {
                              if (state.isLoadingMore.value) {
                                return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                              }
                              return TextButton(
                                onPressed: () async {
                                  final p = AppProviders.of(context);
                                  final c = await p.storage.readCredentials();
                                  if (c != null) p.personsState.loadMore(p.client, c.host, c.projectId, c.apiKey);
                                },
                                child: const Text('Load more persons'),
                              );
                            }),
                          ),
                        );
                      }
                      final person = state.persons.value[index];
                      final os = person.properties['\$os']?.toString();
                      final browser = person.properties['\$browser']?.toString();
                      final city = person.properties['\$geoip_city_name']?.toString();
                      final country = person.properties['\$geoip_country_code']?.toString();
                      final location = [city, country].where((s) => s != null && s.isNotEmpty).join(', ');

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.pushNamed(RouteNames.personDetail, pathParameters: {'personId': person.id.toString()}),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  child: Text(person.initial, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.displayName,
                                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (person.email != null && person.email != person.displayName)
                                        Text(
                                          person.email!,
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (location.isNotEmpty) ...[
                                            Icon(Icons.location_on, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                                            const SizedBox(width: 2),
                                            Text(location, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                            const SizedBox(width: 8),
                                          ],
                                          if (os != null) ...[
                                            Text(os, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                            if (browser != null) Text(' / $browser', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
