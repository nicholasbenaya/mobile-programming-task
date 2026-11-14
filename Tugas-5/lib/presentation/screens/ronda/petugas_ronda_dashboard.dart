import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/ronda/models/ronda_models.dart';
import '../../../domain/ronda/services/haversine_calculator.dart';
import '../../../providers/ronda_provider.dart';

/// Dasbor Utama Khusus Petugas Ronda: Fokus pada Tugas Patroli, Scan Pos Fisik & Respons Darurat SOS
class PetugasRondaDashboard extends StatelessWidget {
  const PetugasRondaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ronda = context.watch<RondaProvider>();
    final user = ronda.currentUser!;

    final activeSos = ronda.activeEmergencies;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.namaLengkap,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ronda.isOfflineMode ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ronda.isOfflineMode ? 'Mode Blank Spot (Offline)' : 'Online - RT 04 / RW 02',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Perbarui GPS',
            icon: ronda.isLoadingGps
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            onPressed: () => ronda.fetchLiveLocation(),
          ),
          IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ronda),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Banner Pesan Sukses / Error
          if (ronda.lastErrorMessage != null) ...[
            _buildNotificationBanner(context, ronda.lastErrorMessage!, isError: true),
            const SizedBox(height: 12),
          ],
          if (ronda.lastSuccessMessage != null) ...[
            _buildNotificationBanner(context, ronda.lastSuccessMessage!, isError: false),
            const SizedBox(height: 12),
          ],

          // 2. Banner Alarm Darurat Aktif (High Priority)
          if (activeSos.isNotEmpty) ...[
            _buildActiveSosAlert(context, ronda, activeSos.first),
            const SizedBox(height: 16),
          ],

          // 3. Status Tugas & Blank Spot Switcher
          _buildDutyStatusCard(context, ronda),
          const SizedBox(height: 16),

          // 4. Daftar Pos Checkpoint Fisik (Patroli QR + Haversine GPS)
          _buildCheckpointsSection(context, ronda),
          const SizedBox(height: 16),

          // 5. Aksi Lapangan Cepat
          _buildQuickActionSection(context, ronda),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, RondaProvider ronda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin mengakhiri sesi Petugas Ronda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ronda.logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(BuildContext context, String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isError ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.red : Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: isError ? Colors.red.shade900 : Colors.green.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSosAlert(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    final isHandling = event.status == EmergencyStatus.onGoing;
    final isAwaitingRt = event.status == EmergencyStatus.menungguVerifikasiRt;

    return Card(
      elevation: 4,
      color: Colors.red.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PANGGILAN DARURAT WARGA (SOS)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        event.status.label,
                        style: TextStyle(
                          color: isHandling ? Colors.yellow : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Text(
              'Pelapor: ${event.userName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              'Alamat: ${event.userAddress}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (event.catatan != null) ...[
              const SizedBox(height: 4),
              Text(
                'Pesan: "${event.catatan}"',
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 14),

            // Opsi Aksi Berdasarkan Status
            if (event.status == EmergencyStatus.belumDitangani) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => ronda.respondEmergency(event.id),
                  icon: const Icon(Icons.directions_run),
                  label: const Text('SAYA MERESPONS (MENUJU LOKASI)'),
                ),
              ),
            ] else if (isHandling) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                      onPressed: () => _showScanWargaQrDialog(context, ronda, event),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan QR Warga', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      onPressed: () => _showPhotoResolutionDialog(context, ronda, event),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Foto Bukti', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else if (isAwaitingRt) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bukti foto telah terkirim. Menunggu persetujuan Ketua RT untuk menyelesaikan status.',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showScanWargaQrDialog(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.blue),
            SizedBox(width: 8),
            Text('Scan QR Warga Pelapor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arahkan kamera smartphone ke QR Code yang ditampilkan pada aplikasi warga (${event.userName}).',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Token Verifikasi Warga:\n${event.verificationQrToken}',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final success = ronda.resolveEmergencyWithQr(
                eventId: event.id,
                scannedQrPayload: event.verificationQrToken,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insiden Darurat Resmi SELESAI (Validasi QR Sukses)!')),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Simulasi Scan QR Warga'),
          ),
        ],
      ),
    );
  }

  void _showPhotoResolutionDialog(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    final notesController = TextEditingController(text: 'Situasi aman terkendali, warga lansia tidak membawa HP.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unggah Foto Bukti Lapangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jika warga tidak dapat memindai QR, ambil foto bukti di lokasi. Status akan dikirimkan ke Ketua RT untuk diverifikasi.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 36, color: Colors.grey.shade700),
                  const SizedBox(height: 4),
                  const Text('Simulasi Kamera Lapangan Siap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('bukti_penanganan_${event.id}.jpg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Keterangan Penanganan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ronda.resolveEmergencyWithPhoto(
                eventId: event.id,
                photoPath: '/storage/emulated/0/DCIM/bukti_penanganan_${event.id}.jpg',
                notes: notesController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto bukti dikirim. Status menunggu verifikasi RT.')),
              );
            },
            child: const Text('Kirim ke Ketua RT'),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyStatusCard(BuildContext context, RondaProvider ronda) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: Colors.indigo, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tugas Jaga Malam Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Pukul 22:00 - 04:00 WIB', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: ronda.isOfflineMode,
                  onChanged: (val) => ronda.setOfflineMode(val),
                ),
              ],
            ),
            if (ronda.isOfflineMode) ...[
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Simulasi Area Blank Spot aktif (${ronda.offlineQueue.pendingCount} antrean)',
                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointsSection(BuildContext context, RondaProvider ronda) {
    final userPos = ronda.currentGpsPosition;
    final checkpoints = ronda.checkpoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.qr_code_2, color: Colors.teal, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Pos Checkpoint Fisik (Patroli QR)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            Text('${checkpoints.length} Pos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        ...checkpoints.map((cp) {
          // Hitung jarak Haversine GPS live
          double? distance;
          if (userPos != null) {
            distance = HaversineCalculator.distanceMeters(
              userPos.latitude,
              userPos.longitude,
              cp.latitude,
              cp.longitude,
            );
          }

          final isNear = distance != null && distance <= cp.radiusMeter;
          final isCheckedIn = ronda.patrolLogs.any((l) => l.checkpointId == cp.id);

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isCheckedIn ? Colors.teal.shade300 : Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isCheckedIn ? Colors.teal : Colors.grey.shade300,
                    child: Icon(
                      isCheckedIn ? Icons.check : Icons.pin_drop,
                      color: isCheckedIn ? Colors.white : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cp.kodeTitik} - ${cp.namaLokasi}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          distance != null
                              ? 'Jarak GPS: ${distance.toStringAsFixed(1)}m (Radius: ${cp.radiusMeter.toInt()}m)'
                              : 'Menunggu sinyal GPS...',
                          style: TextStyle(
                            fontSize: 11,
                            color: isNear ? Colors.green.shade700 : Colors.grey.shade700,
                            fontWeight: isNear ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isCheckedIn)
                          const Text(
                            'Sudah Di-check-in malam ini',
                            style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  // Tombol Scan QR
                  FilledButton.tonal(
                    onPressed: () => _handleCheckpointScan(context, ronda, cp),
                    child: const Text('Scan QR', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _handleCheckpointScan(BuildContext context, RondaProvider ronda, Checkpoint cp) {
    showModalBottomSheet(
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
                const Icon(Icons.qr_code_scanner, color: Colors.teal),
                const SizedBox(width: 8),
                Text('Pindai QR: ${cp.kodeTitik}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            Text(cp.namaLokasi, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text(
              'Pilih mode verifikasi check-in:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ronda.checkinCheckpoint(checkpoint: cp, simulateProximity: false);
                },
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Gunakan GPS Asli Perangkat'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ronda.checkinCheckpoint(checkpoint: cp, simulateProximity: true);
                },
                icon: const Icon(Icons.vibration),
                label: const Text('Simulasi Berada di Pos (Jarak 5m - Untuk Uji Coba)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionSection(BuildContext context, RondaProvider ronda) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => _showReportIncidentDialog(context, ronda),
            icon: const Icon(Icons.camera_alt, color: Colors.deepOrange),
            label: const Text('Lapor Insiden', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => _showShiftSwapDialog(context, ronda),
            icon: const Icon(Icons.swap_horiz, color: Colors.blue),
            label: const Text('Tukar Jadwal', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  void _showReportIncidentDialog(BuildContext context, RondaProvider ronda) {
    final noteController = TextEditingController();
    IncidentCategory selectedCat = IncidentCategory.orangMencurigakan;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lapor Temuan Insiden Patroli'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<IncidentCategory>(
                initialValue: selectedCat,
                items: IncidentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCat = val);
                },
                decoration: const InputDecoration(labelText: 'Kategori Insiden', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Keterangan Temuan', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ronda.reportIncident(
                  category: selectedCat,
                  keterangan: noteController.text.trim().isEmpty ? 'Pengecekan rutin di gang buntu' : noteController.text.trim(),
                  photoPath: '/storage/emulated/0/DCIM/insiden_${DateTime.now().millisecondsSinceEpoch}.jpg',
                );
              },
              child: const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftSwapDialog(BuildContext context, RondaProvider ronda) {
    final noteController = TextEditingController(text: 'Ada keperluan keluarga mendesak.');
    final schedules = ronda.schedules;
    final otherOfficers = ronda.availableUsers.where((u) => u.role == UserRole.petugasRonda && u.id != ronda.currentUser!.id).toList();

    if (schedules.isEmpty || otherOfficers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada petugas pengganti yang tersedia.')));
      return;
    }

    final targetUser = otherOfficers.first;
    final mySchedule = schedules.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Tukar Jadwal Ronda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jadwal Anda: ${DateFormat('dd MMMM yyyy').format(mySchedule.tanggalRonda)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Petugas Pengganti: ${targetUser.namaLengkap}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Alasan Pertukaran', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ronda.requestShiftSwap(
                scheduleId: mySchedule.id,
                targetUserId: targetUser.id,
                alasan: noteController.text.trim(),
              );
            },
            child: const Text('Kirim Pengajuan'),
          ),
        ],
      ),
    );
  }
}
