import 'package:flutter/material.dart';

class DetailAmount extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;
  final Color? valueColor;

  const DetailAmount({
    super.key,
    required this.label,
    required this.value,
    this.fontSize = 22,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
