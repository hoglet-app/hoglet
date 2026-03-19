import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool active;
  final String? label;

  const StatusBadge({super.key, required this.active, this.label});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    final text = label ?? (active ? 'Active' : 'Inactive');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
