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

    return SectionCard(
      step: 2,
      title: 'Lokasi & sensor',
      trailing: IconButton(
        tooltip: 'Segarkan lokasi',
        onPressed: p.locating ? null : p.refreshLocation,
        icon: p.locating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.my_location_rounded),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (p.locationError != null ? scheme.errorContainer : scheme.primaryContainer).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  p.locationError != null ? Icons.location_off_rounded : Icons.place_rounded,
                  color: p.locationError != null ? scheme.error : scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: p.locationError != null
                      ? Text(p.locationError!, style: TextStyle(color: scheme.onErrorContainer))
                      : pos == null
                          ? const Text('Mencari lokasi…')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.coordinates(pos.latitude, pos.longitude),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Akurasi ${Formatters.meters(pos.accuracy)}',
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                ),
                              ],
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
