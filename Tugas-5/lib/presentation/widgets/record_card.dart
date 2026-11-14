import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/record_model.dart';
import 'category_chip.dart';
import 'motion/press_scale.dart';
import 'network_photo.dart';

/// Kartu ringkas satu catatan di daftar. Foto memakai Hero ke halaman detail.
class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, required this.onTap});

  final RecordModel record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return PressScale(
      haptic: false,
      scale: 0.97,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: NetworkPhoto(url: record.photoUrl, width: 88, height: 88, heroTag: 'photo-${record.id}'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      CategoryChip(category: record.category),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.schedule_rounded, size: 14, color: scheme.outline),
                        const SizedBox(width: 4),
                        Text(Formatters.dateTime(record.createdAt), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.place_rounded, size: 14, color: scheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            Formatters.coordinates(record.latitude, record.longitude),
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
