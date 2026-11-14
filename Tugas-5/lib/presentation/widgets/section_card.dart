import 'package:flutter/material.dart';

/// Kartu berjudul dengan nomor langkah, dipakai di form catatan.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.step, required this.title, required this.child, this.trailing});

  final int step;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: scheme.primary,
                  child: Text('$step', style: TextStyle(color: scheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
