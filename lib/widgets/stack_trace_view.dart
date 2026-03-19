import 'package:flutter/material.dart';

class StackTraceView extends StatelessWidget {
  final String stackTrace;

  const StackTraceView({super.key, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          stackTrace,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFD4D4D4), height: 1.5),
        ),
      ),
    );
  }
}
