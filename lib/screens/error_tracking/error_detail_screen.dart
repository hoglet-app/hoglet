import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/stack_trace_view.dart';

class ErrorDetailScreen extends StatefulWidget {
  final String errorId;
  const ErrorDetailScreen({super.key, required this.errorId});
  @override State<ErrorDetailScreen> createState() => _ErrorDetailScreenState();
}

class _ErrorDetailScreenState extends State<ErrorDetailScreen> {
  @override void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    p.errorTrackingState.fetchError(p.client, c.host, c.projectId, c.apiKey, widget.errorId);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).errorTrackingState;
    final theme = Theme.of(context);
    return SignalBuilder(builder: (context, _) {
      final err = state.errorDetail.value; final isLoading = state.isLoadingDetail.value; final error = state.detailError.value;
      return Scaffold(
        appBar: AppBar(title: Text(err?.title ?? 'Error')),
        body: () {
          if (isLoading && err == null) return const ShimmerList(itemCount: 4);
          if (error != null && err == null) return ErrorView(error: error, onRetry: _load);
          if (err == null) return const Center(child: Text('Error not found'));
          final stackTrace = err.raw['stack_trace']?.toString() ?? err.raw['exception']?.toString();
          return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(err.title ?? err.fingerprint, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.repeat, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4), Text('${err.occurrences} occurrences', style: theme.textTheme.bodySmall),
                if (err.affectedUsers != null) ...[const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4), Text('${err.affectedUsers} users', style: theme.textTheme.bodySmall)],
              ]),
            ]))),
            if (stackTrace != null && stackTrace.isNotEmpty) ...[const SizedBox(height: 16),
              Text('STACK TRACE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 8), StackTraceView(stackTrace: stackTrace)],
          ]));
        }(),
      );
    });
  }
}
