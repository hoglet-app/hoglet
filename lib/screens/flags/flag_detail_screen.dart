import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../models/feature_flag.dart';
import '../../services/storage_service.dart';
import '../../state/flags_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/status_badge.dart';

class FlagDetailScreen extends StatefulWidget {
  const FlagDetailScreen({super.key, required this.flagId});

  final int flagId;

  @override
  State<FlagDetailScreen> createState() => _FlagDetailScreenState();
}

class _FlagDetailScreenState extends State<FlagDetailScreen> {
  FlagsState? _flagsState;
  StorageService? _storage;
  bool _initialized = false;

  String _host = '';
  String _projectId = '';
  String _apiKey = '';

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

  Future<void> _load() async {
    _host = await _storage!.read(StorageService.keyHost) ?? '';
    _projectId = await _storage!.read(StorageService.keyProjectId) ?? '';
    _apiKey = await _storage!.read(StorageService.keyApiKey) ?? '';
    await _flagsState!.fetchFlag(
      host: _host,
      projectId: _projectId,
      apiKey: _apiKey,
      flagId: widget.flagId,
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: SignalBuilder(
          builder: (context, _) {
            final flag = flagsState.selectedFlag.value;
            return Text(flag?.key ?? 'Feature Flag');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context, _) {
          final isLoading = flagsState.isLoadingDetail.value;
          final error = flagsState.detailError.value;
          final flag = flagsState.selectedFlag.value;

          if (isLoading) {
            return const ShimmerList();
          }
          if (error != null) {
            return ErrorView(
              error: error,
              onRetry: _load,
            );
          }
          if (flag == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Toggle card
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE3DED6)),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Enabled',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1B19),
                      ),
                    ),
                    subtitle: Text(
                      flag.active ? 'This flag is active' : 'This flag is inactive',
                      style: const TextStyle(color: Color(0xFF6F6A63)),
                    ),
                    value: flag.active,
                    onChanged: (_) => _toggle(flag),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Info card
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE3DED6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1B19),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Key', value: flag.key),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Name', value: flag.name.isNotEmpty ? flag.name : '—'),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Status',
                          valueWidget: StatusBadge(
                            label: flag.active ? 'Active' : 'Inactive',
                            active: flag.active,
                          ),
                        ),
                        if (flag.rolloutPercentage != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Rollout',
                            value: '${flag.rolloutPercentage}%',
                          ),
                        ],
                        if (flag.createdAt != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Created',
                            value: _formatDate(flag.createdAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Release conditions
                _ReleaseConditionsSection(flag: flag),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6F6A63),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: valueWidget ??
              Text(
                value ?? '—',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B19),
                ),
              ),
        ),
      ],
    );
  }
}

class _ReleaseConditionsSection extends StatelessWidget {
  const _ReleaseConditionsSection({required this.flag});

  final FeatureFlag flag;

  @override
  Widget build(BuildContext context) {
    final conditions = flag.releaseConditions;

    if (conditions.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE3DED6)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Release Conditions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1B19),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'No release conditions defined.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6F6A63),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3DED6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Release Conditions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1B19),
              ),
            ),
            const SizedBox(height: 12),
            ...conditions.asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value;
              return _ConditionGroup(
                groupNumber: index + 1,
                group: group,
                isLast: index == conditions.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ConditionGroup extends StatelessWidget {
  const _ConditionGroup({
    required this.groupNumber,
    required this.group,
    required this.isLast,
  });

  final int groupNumber;
  final Map<String, dynamic> group;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final rollout = group['rollout_percentage'];
    final properties = group['properties'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Group $groupNumber',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B19),
              ),
            ),
            if (rollout != null) ...[
              const SizedBox(width: 8),
              Text(
                '$rollout% rollout',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6F6A63),
                ),
              ),
            ],
          ],
        ),
        if (properties.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...properties.map((prop) {
            final p = prop is Map<String, dynamic> ? prop : <String, dynamic>{};
            final key = p['key']?.toString() ?? '';
            final operator = p['operator']?.toString() ?? '';
            final value = p['value']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                '$key $operator $value'.trim(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6F6A63),
                ),
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'All users',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6F6A63),
              ),
            ),
          ),
        ],
        if (!isLast) ...[
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE3DED6)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
