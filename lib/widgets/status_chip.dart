import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final bool positive;

  const StatusChip({
    super.key,
    required this.label,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.shade800,
        ),
      ),
    );
  }
}
