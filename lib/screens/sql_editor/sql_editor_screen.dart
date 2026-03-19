import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../models/sql_result.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';

class SqlEditorScreen extends StatefulWidget {
  const SqlEditorScreen({super.key});
  @override
  State<SqlEditorScreen> createState() => _SqlEditorScreenState();
}

class _SqlEditorScreenState extends State<SqlEditorScreen> {
  final _queryController = TextEditingController(
    text: 'SELECT event, count() as cnt\nFROM events\nGROUP BY event\nORDER BY cnt DESC\nLIMIT 20',
  );
  bool _showHistory = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.sqlEditorState.executeQuery(p.client, c.host, c.projectId, c.apiKey, query);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).sqlEditorState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SQL Editor'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.code : Icons.history),
            onPressed: () => setState(() => _showHistory = !_showHistory),
            tooltip: _showHistory ? 'Editor' : 'History',
          ),
        ],
      ),
      body: _showHistory
          ? _buildHistory(state, theme)
          : _buildEditor(state, theme),
    );
  }

  Widget _buildEditor(dynamic state, ThemeData theme) {
    return Column(
      children: [
        // Query input
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1B19),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _queryController,
                maxLines: 6,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFE3DED6),
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'SELECT * FROM events LIMIT 10',
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF6F6A63),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'HogQL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF6F6A63),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    SignalBuilder(builder: (context, _) {
                      final isRunning = state.isRunning.value as bool;
                      return SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: isRunning ? null : _runQuery,
                          icon: isRunning
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.play_arrow, size: 18),
                          label: Text(isRunning ? 'Running...' : 'Run'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Results
        Expanded(
          child: SignalBuilder(builder: (context, _) {
            final isRunning = state.isRunning.value as bool;
            final error = state.error.value;
            final result = state.result.value as SqlResult?;

            if (isRunning) {
              return const Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Executing query...'),
                ],
              ));
            }
            if (error != null) {
              return ErrorView(error: error, onRetry: _runQuery);
            }
            if (result == null) {
              return const EmptyState(
                icon: Icons.terminal,
                title: 'Run a query to see results',
                message: 'Write HogQL and press Run',
              );
            }
            if (result.isEmpty) {
              return const EmptyState(
                icon: Icons.table_rows_outlined,
                title: 'No results',
                message: 'Query returned zero rows',
              );
            }
            return _ResultsTable(result: result, theme: theme);
          }),
        ),
      ],
    );
  }

  Widget _buildHistory(dynamic state, ThemeData theme) {
    return SignalBuilder(builder: (context, _) {
      final history = state.queryHistory.value as List<String>;
      if (history.isEmpty) {
        return const EmptyState(icon: Icons.history, title: 'No query history');
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, i) {
          final query = history[i];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _queryController.text = query;
                setState(() => _showHistory = false);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  query,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _ResultsTable extends StatelessWidget {
  final SqlResult result;
  final ThemeData theme;

  const _ResultsTable({required this.result, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${result.rowCount} row${result.rowCount == 1 ? '' : 's'} returned',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.onSurface.withValues(alpha: 0.04),
                ),
                columnSpacing: 24,
                horizontalMargin: 16,
                headingTextStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
                dataTextStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                columns: result.columns
                    .map((col) => DataColumn(label: Text(col)))
                    .toList(),
                rows: result.results.map((row) {
                  return DataRow(
                    cells: List.generate(
                      result.columnCount,
                      (ci) {
                        final val = ci < row.length ? row[ci] : '';
                        return DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(
                              _formatValue(val),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map || value is List) return value.toString();
    return value.toString();
  }
}
