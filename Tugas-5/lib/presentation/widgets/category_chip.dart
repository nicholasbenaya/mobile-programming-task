import 'package:flutter/material.dart';

import '../../data/models/record_category.dart';
import 'category_style.dart';

/// Label kategori kecil berwarna (hanya tampilan).
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});
  final RecordCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
