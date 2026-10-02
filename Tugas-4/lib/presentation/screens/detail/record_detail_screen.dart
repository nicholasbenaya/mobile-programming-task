import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/record_model.dart';
import '../../../providers/records_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/sensor_tile.dart';

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});
  final RecordModel record;

  Future<void> _confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<RecordsProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan dan fotonya akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await provider.delete(record);
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showFullPhoto(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(child: InteractiveViewer(child: Image.network(record.photoUrl, fit: BoxFit.contain))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filled(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final point = LatLng(record.latitude, record.longitude);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            actions: [
              IconButton.filledTonal(
                tooltip: 'Hapus',
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _showFullPhoto(context),
                child: Image.network(
                  record.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: scheme.surfaceContainerHighest, child: const Icon(Icons.broken_image_rounded, size: 48)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList.list(
              children: [
                Text(record.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CategoryChip(category: record.category),
                    const SizedBox(width: 10),
                    Icon(Icons.schedule_rounded, size: 15, color: scheme.outline),
                    const SizedBox(width: 4),
                    Expanded(child: Text(Formatters.dateTime(record.createdAt), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Data sensor', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SensorTile(
                        icon: Icons.navigation_rounded,
                        label: 'Kompas',
                        value: record.compass == null ? '—' : '${Formatters.degrees(record.compass)} ${Formatters.compassLabel(record.compass!)}',
                        iconAngleDegrees: record.compass,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: SensorTile(icon: Icons.screen_rotation_alt_rounded, label: 'Miring', value: Formatters.degrees(record.tilt))),
                    const SizedBox(width: 8),
                    Expanded(child: SensorTile(icon: Icons.battery_5_bar_rounded, label: 'Baterai', value: Formatters.percent(record.battery))),
                    const SizedBox(width: 8),
                    Expanded(child: SensorTile(icon: Icons.gps_fixed_rounded, label: 'Akurasi', value: Formatters.meters(record.accuracy))),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Lokasi', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: point,
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            buildTileLayer(),
                            MarkerLayer(markers: [
                              Marker(point: point, width: 40, height: 40, child: Icon(Icons.location_on_rounded, size: 40, color: scheme.error)),
                            ]),
                          ],
                        ),
                      ),
                      ListTile(
                        title: Text(Formatters.coordinates(record.latitude, record.longitude), style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: IconButton(
                          tooltip: 'Salin koordinat',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: Formatters.coordinates(record.latitude, record.longitude)));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koordinat disalin')));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Berkas foto di server', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_rounded),
                    title: Text(record.photoPath, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Bucket: record-photos'),
                  ),
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Catatan', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: Text(record.note, style: text.bodyLarge)))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
