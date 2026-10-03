import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../providers/capture_provider.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/sensor_tile.dart';

/// Lokasi GPS + pembacaan sensor langsung (kompas, kemiringan, baterai).
class SensorSection extends StatelessWidget {
  const SensorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CaptureProvider>();
    final scheme = Theme.of(context).colorScheme;
    final pos = p.position;
    final hasError = p.locationError != null;

    // Satu kunci per keadaan agar AnimatedSwitcher melakukan cross-fade saat berganti.
    final Widget status;
    if (hasError) {
      status = Text(p.locationError!, key: const ValueKey('error'), style: TextStyle(color: scheme.onErrorContainer));
    } else if (pos == null) {
      status = const Text('Mencari lokasi…', key: ValueKey('searching'));
    } else {
      status = Column(
        key: ValueKey('${pos.latitude},${pos.longitude}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Formatters.coordinates(pos.latitude, pos.longitude), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Akurasi ${Formatters.meters(pos.accuracy)}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      );
    }

    return SectionCard(
      step: 2,
      title: 'Lokasi & sensor',
      trailing: IconButton(
        tooltip: 'Segarkan lokasi',
        onPressed: p.locating ? null : p.refreshLocation,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: p.locating
              ? const SizedBox(key: ValueKey('spin'), width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.my_location_rounded, key: ValueKey('icon')),
        ),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (hasError ? scheme.errorContainer : scheme.primaryContainer).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                  child: Icon(
                    hasError ? Icons.location_off_rounded : Icons.place_rounded,
                    key: ValueKey(hasError),
                    color: hasError ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, if (current != null) current],
                      ),
                      child: status,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SensorTile(
                  icon: Icons.navigation_rounded,
                  label: 'Kompas',
                  value: p.compass == null ? '—' : '${Formatters.degrees(p.compass)} ${Formatters.compassLabel(p.compass!)}',
                  iconAngleDegrees: p.compass,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: SensorTile(icon: Icons.screen_rotation_alt_rounded, label: 'Miring', value: Formatters.degrees(p.tilt))),
              const SizedBox(width: 8),
              Expanded(child: SensorTile(icon: Icons.battery_5_bar_rounded, label: 'Baterai', value: Formatters.percent(p.battery))),
            ],
          ),
        ],
      ),
    );
  }
}
