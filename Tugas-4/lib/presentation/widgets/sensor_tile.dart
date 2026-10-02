import 'package:flutter/material.dart';

/// Kotak kecil untuk satu nilai sensor (kompas, kemiringan, baterai, akurasi).
class SensorTile extends StatelessWidget {
  const SensorTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconAngleDegrees,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Memutar ikon (dipakai untuk jarum kompas).
  final double? iconAngleDegrees;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget iconWidget = Icon(icon, size: 22, color: scheme.primary);
    if (iconAngleDegrees != null) {
      iconWidget = Transform.rotate(angle: iconAngleDegrees! * 3.1415926535 / 180, child: iconWidget);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
