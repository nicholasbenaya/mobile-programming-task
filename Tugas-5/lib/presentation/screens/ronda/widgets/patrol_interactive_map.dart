import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/ronda/models/ronda_models.dart';
import '../../../../domain/ronda/services/haversine_calculator.dart';
import '../../../../providers/ronda_provider.dart';
import '../../../widgets/map_tile_layer.dart';

/// Peta Interaktif Patroli Wilayah Siskamling RT (OpenStreetMap + FlutterMap)
/// Menampilkan titik-titik pos ronda, geofence radius, lokasi GPS pengguna,
/// serta panggilan SOS aktif secara real-time.
class PatrolInteractiveMap extends StatefulWidget {
  const PatrolInteractiveMap({
    super.key,
    this.height = 280,
    this.isFullScreen = false,
    this.onCheckpointTap,
  });

  final double height;
  final bool isFullScreen;
  final void Function(Checkpoint checkpoint)? onCheckpointTap;

  @override
  State<PatrolInteractiveMap> createState() => _PatrolInteractiveMapState();
}

class _PatrolInteractiveMapState extends State<PatrolInteractiveMap> {
  final MapController _mapController = MapController();
  Checkpoint? _selectedCheckpoint;

  // Koordinat default RW/RT (Surabaya Timur)
  static const LatLng _centerRt = LatLng(-7.2825, 112.7955);

  void _centerOn(LatLng point, [double zoom = 17.5]) {
    _mapController.move(point, zoom);
  }

  void _showCheckpointSheet(BuildContext context, Checkpoint cp, RondaProvider ronda) {
    setState(() => _selectedCheckpoint = cp);

    final userLat = ronda.currentGpsPosition?.latitude ?? cp.latitude;
    final userLon = ronda.currentGpsPosition?.longitude ?? cp.longitude;
    final dist = HaversineCalculator.distanceMeters(
      userLat,
      userLon,
      cp.latitude,
      cp.longitude,
    );

    final status = ronda.getOfficerCheckpointStatus(cp);
    final user = ronda.currentUser;
    final isOfficer = user?.role == UserRole.petugasRonda;
    final isAdmin = user?.role == UserRole.adminRt;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxStyle.cardShadow,
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cp.kodeTitik,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cp.namaLokasi,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.patrolAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Jadwal Check-in: ${cp.targetWaktuCheckin} WIB',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.radar, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Jarak GPS Anda: ${dist.toStringAsFixed(1)} meter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dist <= cp.radiusMeter ? AppColors.verified : Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Radius aman: ${cp.radiusMeter.toInt()}m',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isOfficer) ...[
                if (status == CheckpointScheduleStatus.selesai)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.verifiedLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.verified, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pos ini sudah Anda check-in dan terverifikasi hari ini.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.verified,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final success = await ronda.checkinCheckpoint(
                              checkpoint: cp,
                              simulateProximity: true,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Check-in pos ${cp.kodeTitik} berhasil diverifikasi!'
                                        : (ronda.lastErrorMessage ?? 'Gagal check-in'),
                                  ),
                                  backgroundColor: success ? AppColors.verified : AppColors.emergency,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.near_me, size: 16),
                          label: const Text('Simulasi Dekat Pos (5m)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openQrCheckinDialog(context, cp, ronda);
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 16),
                          label: const Text('Scan QR Pos', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else if (isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ronda.notifyCheckpointReminder(checkpointId: cp.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Peringatan check-in pos ${cp.kodeTitik} dikirimkan ke petugas.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active, size: 16, color: AppColors.patrolAccent),
                    label: const Text('Ingatkan Petugas Check-in Pos Ini', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openQrCheckinDialog(BuildContext context, Checkpoint cp, RondaProvider ronda) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text('Pindai QR: ${cp.kodeTitik}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            Text(cp.namaLokasi, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ronda.checkinCheckpoint(checkpoint: cp, simulateProximity: false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Check-in ${cp.kodeTitik} berhasil!' : (ronda.lastErrorMessage ?? 'Gagal')),
                        backgroundColor: success ? AppColors.verified : AppColors.emergency,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Check-in dengan GPS Asli'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ronda.checkinCheckpoint(checkpoint: cp, simulateProximity: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Simulasi Check-in ${cp.kodeTitik} berhasil!' : (ronda.lastErrorMessage ?? 'Gagal')),
                        backgroundColor: success ? AppColors.verified : AppColors.emergency,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.near_me),
                label: const Text('Simulasi Berada di Pos (Jarak 5m)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBgColor(CheckpointScheduleStatus status) {
    switch (status) {
      case CheckpointScheduleStatus.selesai:
        return AppColors.verifiedLight;
      case CheckpointScheduleStatus.saat:
        return AppColors.patrolAccentLight;
      case CheckpointScheduleStatus.terlewat:
        return AppColors.emergencyLight;
      case CheckpointScheduleStatus.sebelum:
        return AppColors.secondaryContainer;
    }
  }

  Color _getStatusTextColor(CheckpointScheduleStatus status) {
    switch (status) {
      case CheckpointScheduleStatus.selesai:
        return AppColors.verified;
      case CheckpointScheduleStatus.saat:
        return AppColors.patrolAccent;
      case CheckpointScheduleStatus.terlewat:
        return AppColors.emergency;
      case CheckpointScheduleStatus.sebelum:
        return AppColors.secondary;
    }
  }

  Widget _buildStatusBadge(CheckpointScheduleStatus status) {
    final bg = _getStatusBgColor(status);
    final textCol = _getStatusTextColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ronda = context.watch<RondaProvider>();
    final checkpoints = ronda.checkpoints;
    final activeSos = ronda.activeEmergencies;
    final myPos = ronda.currentGpsPosition;

    final markers = <Marker>[];
    final circles = <CircleMarker>[];

    // 1. Checkpoint Markers & Geofence Circles
    for (final cp in checkpoints) {
      final status = ronda.getOfficerCheckpointStatus(cp);
      final isSelected = _selectedCheckpoint?.id == cp.id;

      // Geofence radius circle
      circles.add(
        CircleMarker(
          point: LatLng(cp.latitude, cp.longitude),
          radius: cp.radiusMeter,
          useRadiusInMeter: true,
          color: (status == CheckpointScheduleStatus.selesai
                  ? AppColors.verified
                  : AppColors.secondary)
              .withValues(alpha: 0.12),
          borderColor: (status == CheckpointScheduleStatus.selesai
                  ? AppColors.verified
                  : AppColors.secondary)
              .withValues(alpha: 0.5),
          borderStrokeWidth: 1.5,
        ),
      );

      // Checkpoint pin
      markers.add(
        Marker(
          point: LatLng(cp.latitude, cp.longitude),
          width: 58,
          height: 58,
          child: GestureDetector(
            onTap: () {
              if (widget.onCheckpointTap != null) {
                widget.onCheckpointTap!(cp);
              }
              _showCheckpointSheet(context, cp, ronda);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusTextColor(status),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    cp.kodeTitik,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.location_on,
                  color: _getStatusTextColor(status),
                  size: isSelected ? 34 : 28,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. User GPS Marker
    if (myPos != null) {
      markers.add(
        Marker(
          point: LatLng(myPos.latitude, myPos.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.my_location, color: Colors.blue, size: 24),
            ),
          ),
        ),
      );
    }

    // 3. Active Emergency SOS Markers
    for (final sos in activeSos) {
      markers.add(
        Marker(
          point: LatLng(sos.latitude, sos.longitude),
          width: 70,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  'SOS: ${sos.userName.split(" ").first}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.warning, color: AppColors.emergency, size: 30),
            ],
          ),
        ),
      );
    }

    final content = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: myPos != null ? LatLng(myPos.latitude, myPos.longitude) : _centerRt,
            initialZoom: 16.8,
            minZoom: 14.0,
            maxZoom: 19.0,
          ),
          children: [
            buildTileLayer(),
            CircleLayer(circles: circles),
            MarkerLayer(markers: markers),
          ],
        ),

        // Controls Overlay (Pusatkan Peta & Legenda Singkat)
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_center_btn',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: AppColors.primary,
                tooltip: 'Pusatkan ke Pos Kamling',
                onPressed: () => _centerOn(_centerRt, 17.0),
                child: const Icon(Icons.shield, size: 18),
              ),
              if (myPos != null) ...[
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'map_gps_btn',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Colors.blue,
                  tooltip: 'Lokasi Saya',
                  onPressed: () => _centerOn(LatLng(myPos.latitude, myPos.longitude), 18.0),
                  child: const Icon(Icons.gps_fixed, size: 18),
                ),
              ],
            ],
          ),
        ),

        // Bottom Banner / Legend
        Positioned(
          left: 10,
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: AppColors.verified, label: 'Selesai'),
                _LegendItem(color: AppColors.patrolAccent, label: 'Waktunya Scan'),
                _LegendItem(color: AppColors.emergency, label: 'Terlewat/SOS'),
                _LegendItem(color: AppColors.secondary, label: 'Mendatang'),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(title: const Text('Peta Interaktif Patroli RT')),
        body: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(height: widget.height, child: content),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class BoxStyle {
  static const cardShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 16,
    offset: Offset(0, -4),
  );
}
