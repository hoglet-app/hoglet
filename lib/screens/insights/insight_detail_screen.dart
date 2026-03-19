import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../models/insight.dart';
import '../../services/storage_service.dart';
import '../../state/insights_state.dart';
import '../../widgets/chart_renderer.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_states.dart';

class InsightDetailScreen extends StatefulWidget {
  const InsightDetailScreen({super.key, required this.insightId});

  final int insightId;

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  InsightsState? _insightsState;
  StorageService? _storage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _insightsState = insightsStateProvider.of(context);
      _storage = storageServiceProvider.of(context);
      _load();
    }
  }

  Future<void> _load() async {
    final host = await _storage!.read(StorageService.keyHost) ?? '';
    final projectId = await _storage!.read(StorageService.keyProjectId) ?? '';
    final apiKey = await _storage!.read(StorageService.keyApiKey) ?? '';

    await _insightsState!.fetchInsight(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
      insightId: widget.insightId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final insightsState = _insightsState;
    if (insightsState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: SignalBuilder(
          builder: (context, _) {
            final insight = insightsState.selectedInsight.value;
            return Text(insight?.name ?? 'Insight');
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
          final isLoading = insightsState.isLoading.value;
          final error = insightsState.error.value;
          final insight = insightsState.selectedInsight.value;

          if (isLoading) {
            return const ShimmerList(itemCount: 3);
          }
          if (error != null) {
            return ErrorView(
              error: error,
              onRetry: _load,
            );
          }
          if (insight == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _InsightDetailBody(insight: insight);
        },
      ),
    );
  }
}

class _InsightDetailBody extends StatelessWidget {
  const _InsightDetailBody({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart card
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
                  Text(
                    insight.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1B19),
                    ),
                  ),
                  if (insight.description != null &&
                      insight.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      insight.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6F6A63),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ChartRenderer(
                      insight: insight,
                      compact: false,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Metadata card
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1B19),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetadataRow(
                    label: 'Type',
                    value: insight.displayType,
                  ),
                  if (insight.lastRefresh != null)
                    _MetadataRow(
                      label: 'Last refreshed',
                      value: _formatDate(insight.lastRefresh!),
                    ),
                  if (insight.createdAt != null)
                    _MetadataRow(
                      label: 'Created',
                      value: _formatDate(insight.createdAt!),
                    ),
                  if (insight.updatedAt != null)
                    _MetadataRow(
                      label: 'Updated',
                      value: _formatDate(insight.updatedAt!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$month $day, $year $hour:$min';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6F6A63),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1C1B19),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
