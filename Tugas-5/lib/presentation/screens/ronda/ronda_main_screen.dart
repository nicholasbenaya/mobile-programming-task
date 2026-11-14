import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../domain/ronda/models/ronda_models.dart';
import '../../../domain/ronda/services/haversine_calculator.dart';
import '../../../providers/ronda_provider.dart';

/// Layar Utama Interaktif Ronda Digital untuk Pengujian Langsung (Live Testing)
class RondaMainScreen extends StatefulWidget {
  const RondaMainScreen({super.key});

  @override
  State<RondaMainScreen> createState() => _RondaMainScreenState();
}

class _RondaMainScreenState extends State<RondaMainScreen> with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Ambil GPS perangkat saat layar pertama kali dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RondaProvider>().fetchLiveLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ronda = context.watch<RondaProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ronda Digital',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'RT 04 / RW 02 Gebang Putih, Sukolilo',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          // Switcher Peran Cepat (Untuk Pengujian Multi-Role)
          PopupMenuButton<RondaUser>(
            tooltip: 'Ganti Peran Pengguna',
            icon: Chip(
              avatar: const Icon(Icons.person, size: 16),
              label: Text(
                ronda.currentUser.role.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
            onSelected: (user) => ronda.switchUser(user),
            itemBuilder: (context) {
              return ronda.availableUsers.map((user) {
                final isSelected = user.id == ronda.currentUser.id;
                return PopupMenuItem(
                  value: user,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.namaLengkap,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              user.role.label,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Banner Notifikasi Sukses / Error
          if (ronda.lastErrorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ronda.lastErrorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (ronda.lastSuccessMessage != null && ronda.lastErrorMessage == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade100,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ronda.lastSuccessMessage!,
                      style: TextStyle(color: Colors.green.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Tampilan Banner Alarm Darurat jika ada SOS Aktif
          if (ronda.activeEmergency != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade800,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🚨 ALARM DARURAT AKTIF!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${ronda.activeEmergency!.userName} (${ronda.activeEmergency!.userAddress})',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => ronda.resolveEmergency(ronda.activeEmergency!.id),
                    child: const Text('Selesai', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          // Konten Layar per Tab
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildScheduleTab(context, ronda),
                _buildCheckpointTab(context, ronda),
                _buildSosTab(context, ronda),
                _buildMapTab(context, ronda),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() => _currentTabIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ronda.offlineQueue.pendingCount > 0,
              label: Text('${ronda.offlineQueue.pendingCount}'),
              child: const Icon(Icons.qr_code_scanner_outlined),
            ),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: 'Check-in',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ronda.activeEmergency != null,
              backgroundColor: Colors.red,
              child: const Icon(Icons.emergency_outlined),
            ),
            selectedIcon: const Icon(Icons.emergency, color: Colors.red),
            label: 'SOS Panik',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta RT',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Jadwal & Ringkasan Shift
  // ---------------------------------------------------------------------------
  Widget _buildScheduleTab(BuildContext context, RondaProvider ronda) {
    final theme = Theme.of(context);
    final schedules = ronda.schedules;
    final checkedInCpIds = ronda.patrolLogs.map((l) => l.checkpointId).toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Profil Pengguna Aktif
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    ronda.currentUser.namaLengkap[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ronda.currentUser.namaLengkap,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        ronda.currentUser.alamatRumah,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peran: ${ronda.currentUser.role.label}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Progress Ronda Malam Ini
        Text(
          'Progress Patroli Malam Ini',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: ronda.checkpoints.isEmpty
              ? 0.0
              : (checkedInCpIds.length / ronda.checkpoints.length).clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Text(
          '${checkedInCpIds.length} dari ${ronda.checkpoints.length} Pos Ronda Terverifikasi',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Daftar Jadwal Shift
        Text(
          'Jadwal Ronda Bergilir',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...schedules.map((s) {
          final isMine = s.userId == ronda.currentUser.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.security,
                color: isMine ? theme.colorScheme.primary : Colors.grey,
              ),
              title: Text(
                s.petugasName + (isMine ? ' (Anda)' : ''),
                style: TextStyle(fontWeight: isMine ? FontWeight.bold : FontWeight.normal),
              ),
              subtitle: Text(
                'Shift: ${s.jamMulai} - ${s.jamSelesai} WIB',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Chip(
                label: Text(s.isCompleted ? 'Selesai' : 'Bertugas', style: const TextStyle(fontSize: 10)),
                backgroundColor: s.isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Check-in Checkpoint (QR + GPS)
  // ---------------------------------------------------------------------------
  Widget _buildCheckpointTab(BuildContext context, RondaProvider ronda) {
    final theme = Theme.of(context);
    final userPos = ronda.currentGpsPosition;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Saklar Simulasi Blank Spot & GPS
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      ronda.isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
                      color: ronda.isOfflineMode ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ronda.isOfflineMode ? 'Mode Offline (Blank Spot)' : 'Mode Online (Terhubung)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ronda.isOfflineMode
                                ? 'Scan checkpoint akan masuk antrean lokal (${ronda.offlineQueue.pendingCount} pending)'
                                : 'Check-in langsung terverifikasi ke server',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: ronda.isOfflineMode,
                      onChanged: (val) => ronda.setOfflineMode(val),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        userPos != null
                            ? 'GPS: ${userPos.latitude.toStringAsFixed(5)}, ${userPos.longitude.toStringAsFixed(5)} (±${userPos.accuracy.toStringAsFixed(1)}m)'
                            : 'GPS belum terkunci',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: ronda.isLoadingGps
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 18),
                      onPressed: () => ronda.fetchLiveLocation(),
                      tooltip: 'Perbarui Lokasi GPS',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Daftar Pos Ronda (Titik Checkpoint)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ...ronda.checkpoints.map((cp) {
          final isCheckedIn = ronda.patrolLogs.any((l) => l.checkpointId == cp.id);
          final distanceMeters = userPos != null
              ? HaversineCalculator.calculateDistance(
                  userPos.latitude,
                  userPos.longitude,
                  cp.latitude,
                  cp.longitude,
                )
              : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isCheckedIn ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(
                          isCheckedIn ? Icons.check : Icons.location_on,
                          color: isCheckedIn ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp.namaLokasi,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Kode: ${cp.kodeTitik} • Radius Batas: ${cp.radiusMeter}m',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (distanceMeters != null)
                        Chip(
                          label: Text(
                            '${distanceMeters.toStringAsFixed(0)} m',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: distanceMeters <= cp.radiusMeter
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Tombol 1: Check-in Menggunakan Lokasi Asli (Membuktikan geofence tolak jika jauh)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.gps_fixed, size: 14),
                          label: const Text('Check-in (GPS Asli)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            ronda.checkinCheckpoint(checkpoint: cp, simulateProximity: false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol 2: Simulasi Berada di Pos (Mempermudah testing penguji)
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.near_me, size: 14),
                          label: const Text('Simulasi Dekat Pos (5m)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            ronda.checkinCheckpoint(checkpoint: cp, simulateProximity: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Tombol Panik SOS
  // ---------------------------------------------------------------------------
  Widget _buildSosTab(BuildContext context, RondaProvider ronda) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Tombol Panik Siskamling',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol merah di bawah untuk memancarkan alarm sirine darurat dan koordinat lokasi ke seluruh warga RT.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 36),

            // Tombol Panik Besar
            _AnimatedPanicButton(
              onTriggered: () {
                ronda.triggerPanic(
                  catatan: 'Alarm darurat dipicu dari aplikasi oleh ${ronda.currentUser.namaLengkap}',
                );
              },
            ),
            const SizedBox(height: 36),

            if (ronda.activeEmergency != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'PANCARAN ALARM AKTIF!',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pelapor: ${ronda.activeEmergency!.userName}\nAlamat: ${ronda.activeEmergency!.userAddress}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.check),
                        label: const Text('Selesaikan / Matikan Alarm'),
                        onPressed: () => ronda.resolveEmergency(ronda.activeEmergency!.id),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: Peta Wilayah RT & Laporan Insiden
  // ---------------------------------------------------------------------------
  Widget _buildMapTab(BuildContext context, RondaProvider ronda) {
    // Koordinat pusat peta (Area Sukolilo / Gebang Putih ITS)
    final centerCoord = const LatLng(-7.282500, 112.795500);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerCoord,
            initialZoom: 16.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'id.ac.its.rondadigital',
            ),

            // Lingkaran Radius Geofence Checkpoint
            CircleLayer(
              circles: ronda.checkpoints.map((cp) {
                return CircleMarker(
                  point: LatLng(cp.latitude, cp.longitude),
                  radius: cp.radiusMeter,
                  useRadiusInMeter: true,
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1.5,
                );
              }).toList(),
            ),

            // Marker Titik Checkpoint
            MarkerLayer(
              markers: [
                ...ronda.checkpoints.map((cp) {
                  final isVisited = ronda.patrolLogs.any((l) => l.checkpointId == cp.id);
                  return Marker(
                    point: LatLng(cp.latitude, cp.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isVisited ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isVisited ? Icons.check : Icons.security,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                }),

                // Marker Darurat SOS jika ada yang aktif
                if (ronda.activeEmergency != null)
                  Marker(
                    point: LatLng(
                      ronda.activeEmergency!.latitude,
                      ronda.activeEmergency!.longitude,
                    ),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // FAB Tambah Laporan Insiden
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Laporkan Insiden'),
            onPressed: () => _showAddIncidentDialog(context, ronda),
          ),
        ),
      ],
    );
  }

  void _showAddIncidentDialog(BuildContext context, RondaProvider ronda) {
    final noteCtrl = TextEditingController();
    var selectedCat = IncidentCategory.orangMencurigakan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporkan Insiden Keamanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<IncidentCategory>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(labelText: 'Kategori Kejadian'),
                    items: IncidentCategory.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan Temuan Lapangan',
                      hintText: 'Contoh: Pagar rumah terbuka atau motor asing',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Kirim Laporan'),
                      onPressed: () {
                        if (noteCtrl.text.isNotEmpty) {
                          ronda.reportIncident(
                            category: selectedCat,
                            keterangan: noteCtrl.text,
                            photoPath: 'evidence/sample_photo.jpg',
                          );
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Tombol Panik dengan Animasi Getaran & Tekan Tahan
class _AnimatedPanicButton extends StatefulWidget {
  const _AnimatedPanicButton({required this.onTriggered});
  final VoidCallback onTriggered;

  @override
  State<_AnimatedPanicButton> createState() => _AnimatedPanicButtonState();
}

class _AnimatedPanicButtonState extends State<_AnimatedPanicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: widget.onTriggered,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 20 * scale,
                    spreadRadius: 6 * scale,
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 40),
                    SizedBox(height: 4),
                    Text(
                      'SOS PANIK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
