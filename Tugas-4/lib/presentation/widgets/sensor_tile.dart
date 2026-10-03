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

  /// Memutar ikon dengan halus (dipakai untuk jarum kompas).
  final double? iconAngleDegrees;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconWidget = iconAngleDegrees == null
        ? Icon(icon, size: 22, color: scheme.primary)
        : _RotatingIcon(icon: icon, color: scheme.primary, degrees: iconAngleDegrees!);
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

/// Ikon yang berputar mengikuti sudut lewat jalur terpendek (359° -> 1° tidak berputar balik).
class _RotatingIcon extends StatefulWidget {
  const _RotatingIcon({required this.icon, required this.color, required this.degrees});
  final IconData icon;
  final Color color;
  final double degrees;

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon> {
  late double _turns = widget.degrees / 360;

  @override
  void didUpdateWidget(covariant _RotatingIcon old) {
    super.didUpdateWidget(old);
    final delta = ((widget.degrees - old.degrees + 540) % 360) - 180;
    _turns += delta / 360;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _turns,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Icon(widget.icon, size: 22, color: widget.color),
    );
  }
}
