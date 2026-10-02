import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/record_category.dart';
import '../../../data/models/record_model.dart';
import '../../../providers/records_provider.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/category_style.dart';
import '../../widgets/map_tile_layer.dart';

/// Semua catatan ditampilkan sebagai pin berwarna di peta OpenStreetMap.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  RecordCategory? _filter;

  List<RecordModel> _visible(List<RecordModel> all) =>
      all.where((r) => _filter == null || r.category == _filter).toList();

  void _fit(List<RecordModel> records) {
    if (records.isEmpty) return;
    if (records.length == 1) {
      _controller.move(LatLng(records.first.latitude, records.first.longitude), 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: [for (final r in records) LatLng(r.latitude, r.longitude)],
        padding: const EdgeInsets.fromLTRB(60, 140, 60, 120),
      ),
    );
  }

  void _preview(RecordModel record) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(record.photoUrl, width: 90, height: 90, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 90, height: 90, child: Icon(Icons.broken_image_rounded))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(record.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  CategoryChip(category: record.category),
                  const SizedBox(height: 6),
                  Text(Formatters.dateTime(record.createdAt), style: Theme.of(sheetContext).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      AppRoutes.openDetail(context, record);
                    },
                    child: const Text('Lihat detail'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<RecordsProvider>().records;
    final records = _visible(all);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: AppConstants.defaultMapCenter,
            initialZoom: 4,
            onMapReady: () => _fit(records),
          ),
          children: [
            buildTileLayer(),
            MarkerLayer(
              markers: [
                for (final r in records)
                  Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _preview(r),
                      child: Container(
                        decoration: BoxDecoration(
                          color: r.category.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: Icon(r.category.icon, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.map_rounded, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text('${records.length} lokasi tercatat', style: const TextStyle(fontWeight: FontWeight.w800))),
                        IconButton(
                          tooltip: 'Pusatkan peta',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _fit(records),
                          icon: const Icon(Icons.center_focus_strong_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in RecordCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(c.icon, size: 16, color: c.color),
                            label: Text(c.label),
                            selected: _filter == c,
                            showCheckmark: false,
                            backgroundColor: scheme.surface,
                            onSelected: (_) => setState(() => _filter = _filter == c ? null : c),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
