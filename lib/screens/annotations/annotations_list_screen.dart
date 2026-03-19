import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../models/annotation.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class AnnotationsListScreen extends StatefulWidget {
  const AnnotationsListScreen({super.key});
  @override
  State<AnnotationsListScreen> createState() => _AnnotationsListScreenState();
}

class _AnnotationsListScreenState extends State<AnnotationsListScreen> {
  String _scopeFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.annotationsState.fetchAnnotations(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).annotationsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotations'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scope filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _scopeFilter == 'all', onTap: () => setState(() => _scopeFilter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Project', selected: _scopeFilter == 'project', onTap: () => setState(() => _scopeFilter = 'project')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Dashboard', selected: _scopeFilter == 'dashboard', onTap: () => setState(() => _scopeFilter = 'dashboard')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Insight', selected: _scopeFilter == 'dashboard_item', onTap: () => setState(() => _scopeFilter = 'dashboard_item')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Organization', selected: _scopeFilter == 'organization', onTap: () => setState(() => _scopeFilter = 'organization')),
              ],
            ),
          ),
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoading.value && state.annotations.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.annotations.value.isEmpty) {
                return ErrorView(error: state.error.value!, onRetry: _load);
              }
              final filtered = _scopeFilter == 'all'
                  ? state.annotations.value
                  : state.annotations.value.where((a) => a.scope == _scopeFilter).toList();
              if (filtered.isEmpty) {
                return const EmptyState(icon: Icons.edit_note_outlined, title: 'No annotations');
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _AnnotationCard(
                    annotation: filtered[i],
                    theme: theme,
                    onTap: () => _showEditDialog(context, filtered[i]),
                    onDelete: () => _deleteAnnotation(filtered[i]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AnnotationFormSheet(
        onSave: (content, dateMarker, scope) async {
          final p = AppProviders.of(context);
          final c = await p.storage.readCredentials();
          if (c == null) return;
          await p.annotationsState.createAnnotation(
            p.client, c.host, c.projectId, c.apiKey,
            content: content,
            dateMarker: dateMarker,
            scope: scope,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Annotation annotation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AnnotationFormSheet(
        existing: annotation,
        onSave: (content, dateMarker, scope) async {
          final p = AppProviders.of(context);
          final c = await p.storage.readCredentials();
          if (c == null) return;
          await p.annotationsState.updateAnnotation(
            p.client, c.host, c.projectId, c.apiKey, annotation.id,
            content: content,
            dateMarker: dateMarker,
            scope: scope,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _deleteAnnotation(Annotation annotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete annotation?'),
        content: Text('This will permanently delete the annotation "${annotation.content}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    try {
      await p.annotationsState.deleteAnnotation(p.client, c.host, c.projectId, c.apiKey, annotation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annotation deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AnnotationCard extends StatelessWidget {
  final Annotation annotation;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AnnotationCard({required this.annotation, required this.theme, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = annotation.dateMarker != null
        ? '${annotation.dateMarker!.year}-${annotation.dateMarker!.month.toString().padLeft(2, '0')}-${annotation.dateMarker!.day.toString().padLeft(2, '0')}'
        : 'No date';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _scopeColor(annotation.scope).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      annotation.scopeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _scopeColor(annotation.scope),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (annotation.scopeTarget.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        annotation.scopeTarget,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                annotation.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  const Spacer(),
                  Text(
                    annotation.creatorName,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scopeColor(String scope) {
    switch (scope) {
      case 'organization':
        return Colors.purple;
      case 'project':
        return Colors.blue;
      case 'dashboard':
        return Colors.teal;
      case 'dashboard_item':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _AnnotationFormSheet extends StatefulWidget {
  final Annotation? existing;
  final Future<void> Function(String content, String dateMarker, String scope) onSave;

  const _AnnotationFormSheet({this.existing, required this.onSave});

  @override
  State<_AnnotationFormSheet> createState() => _AnnotationFormSheetState();
}

class _AnnotationFormSheetState extends State<_AnnotationFormSheet> {
  late final TextEditingController _contentController;
  late DateTime _selectedDate;
  late String _selectedScope;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.existing?.content ?? '');
    _selectedDate = widget.existing?.dateMarker ?? DateTime.now();
    _selectedScope = widget.existing?.scope ?? 'project';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing != null ? 'Edit Annotation' : 'New Annotation',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          // Date picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Scope dropdown
          DropdownButtonFormField<String>(
            value: _selectedScope,
            decoration: const InputDecoration(labelText: 'Scope', prefixIcon: Icon(Icons.visibility)),
            items: const [
              DropdownMenuItem(value: 'project', child: Text('Project')),
              DropdownMenuItem(value: 'organization', child: Text('Organization')),
            ],
            onChanged: (v) { if (v != null) setState(() => _selectedScope = v); },
          ),
          const SizedBox(height: 16),
          // Content
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'What happened?',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 400,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_contentController.text.trim().isEmpty) return;
                    setState(() => _isSaving = true);
                    try {
                      await widget.onSave(
                        _contentController.text.trim(),
                        _selectedDate.toIso8601String(),
                        _selectedScope,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.existing != null ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
