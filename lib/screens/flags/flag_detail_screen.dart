import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/status_badge.dart';

class FlagDetailScreen extends StatefulWidget {
  final String flagId;

  const FlagDetailScreen({super.key, required this.flagId});

  @override
  State<FlagDetailScreen> createState() => _FlagDetailScreenState();
}

class _FlagDetailScreenState extends State<FlagDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    final flagId = int.tryParse(widget.flagId);
    if (flagId == null) return;

    providers.flagsState.fetchFlag(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
      flagId,
    );
  }

  Future<void> _toggleFlag() async {
    HapticFeedback.mediumImpact();
    final providers = AppProviders.of(context);
    final flag = providers.flagsState.flag.value;
    if (flag == null) return;

    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    try {
      await providers.flagsState.toggleFlag(
        providers.client,
        credentials.host,
        credentials.projectId,
        credentials.apiKey,
        flag.id,
        !flag.active,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).flagsState;
    final theme = Theme.of(context);

    return SignalBuilder(
      builder: (context, _) {
        final flag = state.flag.value;
        final isLoading = state.isLoadingDetail.value;
        final error = state.detailError.value;

        return Scaffold(
          appBar: AppBar(title: Text(flag?.key ?? 'Flag')),
          body: () {
            if (isLoading && flag == null) return const ShimmerList(itemCount: 4);
            if (error != null && flag == null) {
              return ErrorView(error: error, onRetry: _loadFlag);
            }
            if (flag == null) return const Center(child: Text('Flag not found'));

            return RefreshIndicator(
              onRefresh: _loadFlag,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Key + toggle
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flag.key,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(active: flag.active),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: flag.active,
                            onChanged: (_) => _toggleFlag(),
                            activeColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Name + description
                  if (flag.name != null && flag.name!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Name', style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    )),
                    const SizedBox(height: 4),
                    Text(flag.name!, style: theme.textTheme.bodyLarge),
                  ],

                  // Rollout percentage
                  if (flag.rolloutPercentage != null) ...[
                    const SizedBox(height: 16),
                    Text('Rollout', style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    )),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: flag.rolloutPercentage! / 100,
                        minHeight: 12,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${flag.rolloutPercentage}% of users',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],

                  // Release conditions
                  if (flag.releaseConditions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Release Conditions', style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    )),
                    const SizedBox(height: 8),
                    ...flag.releaseConditions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final condition = entry.value;
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Condition ${idx + 1}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                condition.summary,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          }(),
        );
      },
    );
  }
}
