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
              decoration: const InputDecoration(hintText: 'Search by email, name, or distinct ID...', prefixIcon: Icon(Icons.search, size: 20), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
              onSubmitted: (value) => _loadPersons(search: value.isNotEmpty ? value : null),
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context, _) {
                if (state.isLoading.value && state.persons.value.isEmpty) return const ShimmerList();
                if (state.error.value != null && state.persons.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _loadPersons);
                if (state.persons.value.isEmpty) return const EmptyState(icon: Icons.person_outlined, title: 'No persons found');

                return RefreshIndicator(
                  onRefresh: _loadPersons,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.persons.value.length,
                    itemBuilder: (context, index) {
                      final person = state.persons.value[index];
                      return Card(
                        elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12), child: Text(person.initial, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
                          title: Text(person.displayName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: person.email != null && person.email != person.displayName ? Text(person.email!, style: theme.textTheme.bodySmall) : null,
                          onTap: () => context.pushNamed(RouteNames.personDetail, pathParameters: {'personId': person.id.toString()}),
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
