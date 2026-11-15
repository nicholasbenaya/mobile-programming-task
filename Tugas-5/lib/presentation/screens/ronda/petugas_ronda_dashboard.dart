import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/ronda/models/ronda_models.dart';
import '../../../domain/ronda/services/haversine_calculator.dart';
import '../../../providers/ronda_provider.dart';
import 'widgets/dynamic_roster_calendar_dialog.dart';
import 'widgets/patrol_calendar_widget.dart';
import 'widgets/patrol_interactive_map.dart';
import 'widgets/sos_qr_scanner_dialog.dart';

/// Dasbor Utama Khusus Petugas Ronda: Fokus pada Tugas Patroli, Scan Pos Fisik & Respons Darurat SOS
class PetugasRondaDashboard extends StatelessWidget {
  const PetugasRondaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ronda = context.watch<RondaProvider>();
    final user = ronda.currentUser!;

    final activeSos = ronda.activeEmergencies;
    final overdueCps = ronda.overdueCheckpoints;
    final notifications = ronda.notifications.take(3).toList();

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
                    color: ronda.isOfflineMode ? AppColors.patrolAccent : AppColors.verified,
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
          // 1. Pesan Sukses / Error Sistem
          if (ronda.lastErrorMessage != null) ...[
            _buildNotificationBanner(context, ronda.lastErrorMessage!, isError: true),
            const SizedBox(height: 12),
          ],
          if (ronda.lastSuccessMessage != null) ...[
            _buildNotificationBanner(context, ronda.lastSuccessMessage!, isError: false),
            const SizedBox(height: 12),
          ],

          // 2. Banner Notifikasi Darurat / Peringatan RT
          if (notifications.isNotEmpty) ...[
            _buildInternalNotificationsList(context, notifications),
            const SizedBox(height: 12),
          ],

          // 3. Peringatan Pos Patroli Terlewat (Overdue Reminder)
          if (overdueCps.isNotEmpty) ...[
            _buildOverdueWarningBanner(context, overdueCps),
            const SizedBox(height: 14),
          ],

          // 4. Banner Alarm Darurat Aktif (SOS)
          if (activeSos.isNotEmpty) ...[
            _buildActiveSosAlert(context, ronda, activeSos.first),
            const SizedBox(height: 16),
          ],

          // 5. Peta Interaktif Patroli Wilayah
          _buildPatrolMapCard(context, ronda),
          const SizedBox(height: 16),

          // 6. Status Tugas & Kesiagaan Piket
          _buildDutyStatusCard(context, ronda),
          const SizedBox(height: 16),

          // 7. Daftar Pos Checkpoint Fisik (Patroli QR + Haversine GPS + Jadwal Pos)
          _buildCheckpointsSection(context, ronda),
          const SizedBox(height: 16),

          // 8. Permintaan Tukar Jadwal On-going
          _buildOngoingSwapRequestsSection(context, ronda),
          const SizedBox(height: 16),

          // 9. Aksi Lapangan Cepat
          _buildQuickActionSection(context, ronda),
          const SizedBox(height: 16),

          // 10. Riwayat Audit Penanganan SOS Saya
          _buildResolvedSosAuditSection(context, ronda),
          const SizedBox(height: 20),

          // 11. Kalender & Roster Jadwal Ronda
          PatrolCalendarWidget(ronda: ronda, allowAdminManagement: false),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, RondaProvider ronda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Petugas Ronda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
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

  Widget _buildNotificationBanner(BuildContext context, String text, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.emergencyLight : AppColors.verifiedLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isError ? AppColors.emergency : AppColors.verified, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.emergency : AppColors.verified,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isError ? AppColors.emergency : AppColors.verified,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalNotificationsList(BuildContext context, List<RondaNotification> list) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.patrolAccentLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.patrolAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.patrolAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Pemberitahuan Sistem & Perintah RT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...list.map((n) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      '${n.title}: ${n.body}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOverdueWarningBanner(BuildContext context, List<Checkpoint> overdueCps) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emergencyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emergency, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_off_outlined, color: AppColors.emergency, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERINGATAN CHECK-IN POS TERLEWAT',
                  style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Terdapat ${overdueCps.length} pos yang telah melewati jam target patroli belum di-scan: ${overdueCps.map((c) => c.kodeTitik).join(", ")}. Segera menuju lokasi dan lakukan scan.',
                  style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSosAlert(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    final isHandling = event.isOnGoing && event.respondedByUserId == ronda.currentUser!.id;
    final isAwaitingRt = event.isMenungguVerifikasiRt;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.emergency,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergency.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PANGGILAN DARURAT (SOS) AKTIF!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.status.label,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Pelapor: ${event.userName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Lokasi: ${event.userAddress}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            if (event.catatan != null) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: "${event.catatan}"',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 14),

            // Tombol Aksi Respons Petugas
            if (event.isBelumDitangani) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade400,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => _handleRespondEmergency(context, ronda, event),
                  icon: const Icon(Icons.directions_run),
                  label: const Text('SAYA MERESPONS (MENUJU LOKASI)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else if (isHandling) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => _openRealQrScanner(context, ronda, event),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Pindai QR Warga', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
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
                        'Bukti foto telah terkirim ke Ketua RT. Menunggu pengesahan verifikasi.',
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

  /// Verifikasi Hak Merespons SOS: Hanya yang sedang bertugas yang boleh merespons
  void _handleRespondEmergency(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    if (ronda.isCurrentPetugasOnDuty) {
      ronda.respondEmergency(event.id);
      return;
    }

    // Jika di luar jam dinas / tidak terjadwal hari ini
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.patrolAccent),
            SizedBox(width: 8),
            Text('Status Dinas Petugas', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda saat ini tercatat di luar jadwal ronda aktif hari ini.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.patrolAccentLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Jadwal Anda: ${ronda.myTodaySchedule?.shiftName ?? "Tidak ada giliran piket hari ini"}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.patrolAccent),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Apakah Anda ingin mengaktifkan "Mode Siaga Darurat Lapangan" untuk merespons panggilan warga ini?',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
            onPressed: () {
              Navigator.pop(ctx);
              ronda.toggleManualDuty(true);
              ronda.respondEmergency(event.id);
            },
            child: const Text('Aktifkan Siaga & Respons'),
          ),
        ],
      ),
    );
  }

  void _openRealQrScanner(BuildContext context, RondaProvider ronda, EmergencyEvent event) async {
    final result = await SosQrScannerDialog.show(context, ronda, event);
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insiden Darurat Resmi SELESAI (Validasi QR Warga Berhasil)!')),
      );
    }
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
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 32, color: Colors.grey.shade700),
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
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
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
    final isOnDuty = ronda.isCurrentPetugasOnDuty;
    final mySched = ronda.myTodaySchedule;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOnDuty ? AppColors.verifiedLight : Colors.grey.shade200,
                  radius: 20,
                  child: Icon(
                    isOnDuty ? Icons.shield : Icons.nightlight_outlined,
                    color: isOnDuty ? AppColors.verified : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isOnDuty ? 'Sedang Bertugas' : 'Di Luar Jam Dinas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isOnDuty ? AppColors.verified : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOnDuty ? AppColors.verifiedLight : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOnDuty ? 'AKTIF' : 'OFF',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isOnDuty ? AppColors.verified : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        mySched != null
                            ? '${mySched.shiftName} (${mySched.jamMulai} - ${mySched.jamSelesai} WIB)'
                            : 'Tidak ada shift dinas otomatis malam ini',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                // Toggle Manual Siaga
                Column(
                  children: [
                    Switch(
                      value: ronda.isManualDutyActive,
                      onChanged: (val) => ronda.toggleManualDuty(val),
                    ),
                    const Text('Siaga', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.wifi_tethering_off, size: 18, color: AppColors.patrolAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mode Blank Spot (Offline)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Simulasi area tanpa internet (antrean lokal)', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.patrolAccentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, size: 14, color: AppColors.patrolAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Antrean scan offline: ${ronda.offlineQueue.pendingCount} rekaman',
                      style: const TextStyle(fontSize: 11, color: AppColors.patrolAccent, fontWeight: FontWeight.bold),
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

  Widget _buildCheckpointsSection(BuildContext context, RondaProvider ronda) {
    final userPos = ronda.currentGpsPosition;
    final checkpoints = ronda.checkpoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.qr_code_2, color: AppColors.secondary, size: 22),
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
          final status = ronda.getCheckpointStatus(cp);

          Color statusBg;
          Color statusFg;
          String statusText;

          switch (status) {
            case CheckpointScheduleStatus.sebelum:
              statusBg = Colors.blue.shade50;
              statusFg = Colors.blue.shade700;
              statusText = 'Mendatang (${cp.targetWaktuCheckin} WIB)';
              break;
            case CheckpointScheduleStatus.saat:
              statusBg = AppColors.patrolAccentLight;
              statusFg = AppColors.patrolAccent;
              statusText = 'WAKTUNYA SCAN!';
              break;
            case CheckpointScheduleStatus.terlewat:
              statusBg = AppColors.emergencyLight;
              statusFg = AppColors.emergency;
              statusText = 'TERLEWAT (${cp.targetWaktuCheckin} WIB)';
              break;
            case CheckpointScheduleStatus.selesai:
              statusBg = AppColors.verifiedLight;
              statusFg = AppColors.verified;
              statusText = 'Terverifikasi';
              break;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: status == CheckpointScheduleStatus.selesai ? AppColors.verified : Colors.grey.shade200,
                    child: Icon(
                      status == CheckpointScheduleStatus.selesai ? Icons.check : Icons.pin_drop,
                      color: status == CheckpointScheduleStatus.selesai ? Colors.white : Colors.grey.shade700,
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusFg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Target: ${cp.targetWaktuCheckin}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          distance != null
                              ? 'Jarak GPS: ${distance.toStringAsFixed(1)}m (Radius: ${cp.radiusMeter.toInt()}m)'
                              : 'Menunggu sinyal GPS...',
                          style: TextStyle(
                            fontSize: 11,
                            color: isNear ? AppColors.verified : Colors.grey.shade700,
                            fontWeight: isNear ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Scan QR
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
                const Icon(Icons.qr_code_scanner, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text('Pindai QR: ${cp.kodeTitik}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            Text(cp.namaLokasi, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            const Text(
              'Pilih mode verifikasi check-in:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
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
            onPressed: () => _showRichShiftSwapDialog(context, ronda),
            icon: const Icon(Icons.swap_horiz, color: AppColors.secondary),
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
                decoration: const InputDecoration(labelText: 'Kategori Insiden'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Keterangan Temuan'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
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

  Widget _buildPatrolMapCard(BuildContext context, RondaProvider ronda) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.map, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Peta Interaktif Wilayah Patroli RT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  'Ketuk pin pos untuk scan',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 220,
            child: PatrolInteractiveMap(height: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingSwapRequestsSection(BuildContext context, RondaProvider ronda) {
    final incoming = ronda.myIncomingSwapRequests;
    final outgoing = ronda.myOutgoingSwapRequests;

    if (incoming.isEmpty && outgoing.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sync_alt, color: AppColors.patrolAccent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Permintaan Tukar Jadwal (On-Going Requests)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            if (incoming.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${incoming.length} Baru',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Permintaan Masuk (Incoming Requests)
        if (incoming.isNotEmpty) ...[
          const Text(
            'Permintaan Masuk dari Rekan (Perlu Persetujuan Anda):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.patrolAccent),
          ),
          const SizedBox(height: 6),
          ...incoming.map((req) {
            return Card(
              color: AppColors.patrolAccentLight.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.patrolAccent.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.primaryLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Dari: ${req.requesterName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM HH:mm').format(req.createdAt),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Menawarkan: ${req.requesterShift}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Menggantikan jadwal Anda: ${req.targetShift} (${req.targetDate != null ? DateFormat("dd MMMM yyyy", "id_ID").format(req.targetDate!) : "Jadwal Terjadwal"})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (req.alasan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Alasan: "${req.alasan}"',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.emergency,
                            side: const BorderSide(color: AppColors.emergency),
                          ),
                          onPressed: () {
                            ronda.respondShiftSwap(requestId: req.id, isAccepted: false);
                          },
                          child: const Text('Tolak', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AppColors.verified,
                          ),
                          onPressed: () {
                            ronda.respondShiftSwap(requestId: req.id, isAccepted: true);
                          },
                          child: const Text('Terima & Tukar', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
        ],

        // Permintaan Keluar (Outgoing Requests)
        if (outgoing.isNotEmpty) ...[
          const Text(
            'Pengajuan Saya ke Rekan Lain:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          ...outgoing.take(3).map((req) {
            Color statusColor;
            String statusLabel;
            switch (req.status) {
              case ShiftSwapStatus.pending:
                statusColor = AppColors.patrolAccent;
                statusLabel = 'Menunggu Respon Rekan';
                break;
              case ShiftSwapStatus.acceptedByTarget:
                statusColor = AppColors.verified;
                statusLabel = 'Disetujui Rekan (Jadwal Aktif)';
                break;
              case ShiftSwapStatus.rejected:
                statusColor = AppColors.emergency;
                statusLabel = 'Ditolak Rekan';
                break;
              case ShiftSwapStatus.approvedByAdmin:
                statusColor = AppColors.verified;
                statusLabel = 'Disahkan RT';
                break;
              case ShiftSwapStatus.expired:
                statusColor = AppColors.textSecondaryLight;
                statusLabel = 'Kedaluwarsa (H-3 Jam)';
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kepada: ${req.targetUserName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          '${req.requesterShift} ➔ ${req.targetShift}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildResolvedSosAuditSection(BuildContext context, RondaProvider ronda) {
    final myResolved = ronda.resolvedEmergencies
        .where((e) => e.respondedByUserId == ronda.currentUser?.id)
        .toList();

    if (myResolved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_toggle_off, color: AppColors.verified, size: 20),
            SizedBox(width: 8),
            Text(
              'Riwayat Audit Penanganan SOS Saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...myResolved.take(3).map((event) {
          final durResolve = event.durationToResolve != null
              ? '${event.durationToResolve!.inMinutes} menit'
              : '-';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.verifiedLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SELESAI TERTANGANI',
                          style: TextStyle(color: AppColors.verified, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        event.resolvedAt != null ? DateFormat('dd/MM HH:mm').format(event.resolvedAt!) : '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Warga Pelapor: ${event.userName} (${event.userAddress})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Metode Selesai: ${event.resolvedVia?.label ?? "Verifikasi Fisik"} • Durasi Tanggap: $durResolve',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                  if (event.resolutionNotes != null && event.resolutionNotes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Catatan: "${event.resolutionNotes}"',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Dialog Pengajuan Tukar Jadwal Interaktif menggunakan Kalender Dinamis
  void _showRichShiftSwapDialog(BuildContext context, RondaProvider ronda) {
    DynamicRosterCalendarDialog.show(
      context: context,
      mode: CalendarDialogMode.officerSwap,
    );
  }
}
