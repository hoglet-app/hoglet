import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/feature_flag.dart';
import '../../services/storage_service.dart';
import '../../state/flags_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/status_badge.dart';

class FlagsListScreen extends StatefulWidget {
  const FlagsListScreen({super.key});

  @override
  State<FlagsListScreen> createState() => _FlagsListScreenState();
}

class _FlagsListScreenState extends State<FlagsListScreen> {
  FlagsState? _flagsState;
  StorageService? _storage;
  bool _initialized = false;

  String _host = '';
  String _projectId = '';
  String _apiKey = '';

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _flagsState = AppProviders.of(context).flagsState;
      _storage = AppProviders.of(context).storage;
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _missingCredentials = false;

  Future<void> _load() async {
    _host = await _storage!.read(StorageService.keyHost) ?? '';
    _projectId = await _storage!.read(StorageService.keyProjectId) ?? '';
    _apiKey = await _storage!.read(StorageService.keyApiKey) ?? '';

    if (_host.isEmpty || _projectId.isEmpty || _apiKey.isEmpty) {
      if (mounted) {
        setState(() => _missingCredentials = true);
      }
      return;
    }

    if (mounted) {
      setState(() => _missingCredentials = false);
    }

    await _flagsState!.fetchFlags(
      host: _host,
      projectId: _projectId,
      apiKey: _apiKey,
    );
  }

  List<FeatureFlag> _filtered(List<FeatureFlag> flags) {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return flags;
    return flags
        .where((f) =>
            f.key.toLowerCase().contains(q) ||
            f.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _toggle(FeatureFlag flag) async {
    HapticFeedback.mediumImpact();
    await _flagsState!.toggleFlag(
      host: _host,
      projectId: _projectId,
      apiKey: _apiKey,
      flagId: flag.id,
      active: !flag.active,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flagsState = _flagsState;
    if (flagsState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_missingCredentials) {
      return const EmptyState(
        icon: Icons.settings_outlined,
        title: 'No connection configured',
        subtitle: 'Configure your connection in Settings to get started.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search flags…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3DED6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3DED6)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: SignalBuilder(
            builder: (context, _) {
              final isLoading = flagsState.isLoading.value;
              final error = flagsState.error.value;

              if (isLoading) {
                return const ShimmerList();
              }
              if (error != null) {
                return ErrorView(
                  error: error,
                  onRetry: _load,
                );
              }

              final flags = flagsState.flags.value;
              final filtered = _filtered(flags);

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.flag_outlined,
                  title: _searchQuery.isEmpty
                      ? 'No feature flags yet'
                      : 'No results for "$_searchQuery"',
                  subtitle: _searchQuery.isEmpty
                      ? 'Create a feature flag in PostHog to see it here.'
                      : null,
                );
              }

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final flag = filtered[index];
                    return _FlagRow(
                      flag: flag,
                      onTap: () => context.go('/flags/flag/${flag.id}'),
                      onToggle: () => _toggle(flag),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.flag,
    required this.onTap,
    required this.onToggle,
  });

  final FeatureFlag flag;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE3DED6)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1B19),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StatusBadge(
                            label: flag.active ? 'Active' : 'Inactive',
                            active: flag.active,
                          ),
                          if (flag.rolloutPercentage != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${flag.rolloutPercentage}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6F6A63),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: flag.active,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
