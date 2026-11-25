import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/ronda/models/ronda_models.dart';
import '../../../providers/ronda_provider.dart';
import 'widgets/patrol_calendar_widget.dart';
import 'widgets/patrol_interactive_map.dart';

/// Dasbor Utama Khusus Warga: Fokus pada Tombol Panik SOS, QR Verifikasi Darurat, dan Kalender Ronda Lingkungan
class WargaDashboard extends StatefulWidget {
  const WargaDashboard({super.key});

  @override
  State<WargaDashboard> createState() => _WargaDashboardState();
}

class _WargaDashboardState extends State<WargaDashboard> {
  final TextEditingController _sosNoteController = TextEditingController();

  @override
  void dispose() {
    _sosNoteController.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context, RondaProvider ronda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Warga?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ronda = context.watch<RondaProvider>();
    final user = ronda.currentUser!;
    final myEmergency = ronda.myActiveEmergency;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.namaLengkap,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              user.alamatRumah,
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: () => ronda.refreshData(),
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
          // 1. Notifikasi Sukses / Error
          if (ronda.lastErrorMessage != null) ...[
            _buildNotification(context, ronda.lastErrorMessage!, isError: true),
            const SizedBox(height: 12),
          ],
          if (ronda.lastSuccessMessage != null) ...[
            _buildNotification(context, ronda.lastSuccessMessage!,
                isError: false),
            const SizedBox(height: 12),
          ],

          // 2. KARTU SOS DARURAT AKTIF (JIKA SEDANG MEMBUNYIKAN ALARM)
          if (myEmergency != null) ...[
            _buildActiveEmergencyCard(context, ronda, myEmergency),
            const SizedBox(height: 16),
          ] else ...[
            // 3. TOMBOL PANIK DARURAT (JIKA TIDAK AKTIF)
            _buildPanicTriggerCard(context, ronda),
            const SizedBox(height: 16),
          ],

          // 4. Lapor Fasilitas Rusak / Kejadian Warga (Non-Darurat)
          _buildCivicIncidentReportCard(context, ronda),
          const SizedBox(height: 16),

          // 5. Peta Interaktif Wilayah RT & Pos Ronda
          _buildPatrolMapCard(context, ronda),
          const SizedBox(height: 16),

          // 6. Kalender & Roster Jadwal Ronda Transparan untuk Warga
          PatrolCalendarWidget(ronda: ronda, allowAdminManagement: false),
          const SizedBox(height: 16),

          // 7. Riwayat Audit Penanganan Darurat SOS Selesai
          _buildResolvedSosAuditSection(context, ronda),
          const SizedBox(height: 16),

          // 8. Riwayat Laporan Kejadian Warga
          _buildCivicIncidentsHistory(context, ronda),
          const SizedBox(height: 16),

          // 9. Kontak Darurat Lingkungan RT
          _buildEmergencyContactsCard(context),
        ],
      ),
    );
  }

  Widget _buildNotification(BuildContext context, String text,
      {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.emergencyLight : AppColors.verifiedLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isError ? AppColors.emergency : AppColors.verified),
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

  /// Tampilan Saat Warga Sedang Menyalakan Tombol Panik (Menampilkan QR Verifikasi Milik Warga)
  Widget _buildActiveEmergencyCard(
      BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    Color badgeColor;
    String badgeText;

    switch (event.status) {
      case EmergencyStatus.belumDitangani:
        badgeColor = AppColors.emergency;
        badgeText = 'BELUM DITANGANI (Alarm Berdering di Seluruh RT)';
        break;
      case EmergencyStatus.onGoing:
        badgeColor = AppColors.patrolAccent;
        badgeText =
            'SEDANG DIRESPONS (Petugas ${event.respondedByUserName ?? ""} Menuju Rumah Anda)';
        break;
      case EmergencyStatus.menungguVerifikasiRt:
        badgeColor = Colors.purple;
        badgeText = 'PENANGANAN BERFOTO (Menunggu Verifikasi RT)';
        break;
      case EmergencyStatus.selesai:
        badgeColor = AppColors.verified;
        badgeText = 'SELESAI / TERTANGANI';
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.emergency, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.crisis_alert,
                    color: AppColors.emergency, size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ALARM DARURAT ANDA AKTIF',
                    style: TextStyle(
                        color: AppColors.emergency,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
                Text(DateFormat('HH:mm:ss').format(event.triggeredAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                badgeText,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // QR CODE VERIFIKASI SELESAI
            const Text(
              'QR Code Verifikasi Petugas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tunjukkan kode QR di bawah kepada Petugas Ronda yang tiba di rumah Anda sebagai verifikasi fisik penyelesaian insiden.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: event.verificationQrToken,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Token: ${event.verificationQrToken}',
              style: const TextStyle(
                  fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Tombol Batalkan Alarm (Jika salah tekan)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onPressed: () => _confirmCancelEmergency(context, ronda, event),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batalkan Panggilan Darurat Ini (Salah Tekan)',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelEmergency(
      BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Alarm Darurat?'),
        content: const Text(
            'Apakah Anda yakin situasi telah terkendali dan ingin mematikan alarm SOS?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kembali')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
            onPressed: () {
              Navigator.pop(ctx);
              ronda.cancelMyEmergency(event.id);
            },
            child: const Text('Ya, Matikan Alarm'),
          ),
        ],
      ),
    );
  }

  Widget _buildPanicTriggerCard(BuildContext context, RondaProvider ronda) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.emergency.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Tombol Panik Darurat (SOS Siskamling)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tekan tombol merah di bawah ini apabila Anda menghadapi bahaya, pencurian, kebakaran, atau kecurigaan di sekitar rumah.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),

            // Tombol Panik Besar
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(60),
                onTap: () => _showPanicConfirmationDialog(context, ronda),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emergency,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.crisis_alert, size: 48, color: Colors.white),
                      SizedBox(height: 2),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alarm akan memicu sirene & notifikasi prioritas tinggi ke pos ronda dan perangkat Ketua RT.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showPanicConfirmationDialog(BuildContext context, RondaProvider ronda) {
    _sosNoteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.emergency),
            SizedBox(width: 8),
            Text('Konfirmasi Alarm SOS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin menyalakan sirine darurat siskamling?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sosNoteController,
              decoration: const InputDecoration(
                labelText: 'Keterangan Situasi (Opsional)',
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
            onPressed: () {
              Navigator.pop(ctx);
              ronda.triggerPanic(
                catatan: _sosNoteController.text.trim().isEmpty
                    ? null
                    : _sosNoteController.text.trim(),
              );
            },
            child: const Text('BUNYIKAN ALARM'),
          ),
        ],
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
                const Icon(Icons.location_searching,
                    color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Peta Pos Ronda & Keamanan Lingkungan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  '${ronda.checkpoints.length} Pos Ronda',
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

  Widget _buildCivicIncidentReportCard(
      BuildContext context, RondaProvider ronda) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle_outlined,
                    color: AppColors.patrolAccent, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lapor Fasilitas Rusak / Masalah Lingkungan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Non-SOS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Laporkan lampu penerangan jalan mati, fasilitas umum rusak, tumpukan sampah liar, atau saluran got mampet kepada pengurus RT dan petugas patroli.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.patrolAccent),
                  foregroundColor: AppColors.patrolAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showReportCivicDialog(context, ronda),
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Buat Laporan Fasilitas / Lingkungan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportCivicDialog(BuildContext context, RondaProvider ronda) {
    final noteController = TextEditingController();
    IncidentCategory selectedCategory = IncidentCategory.fasilitasRusak;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.report_problem, color: AppColors.patrolAccent),
                SizedBox(width: 8),
                Text('Laporan Warga', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Kategori Masalah:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<IncidentCategory>(
                    initialValue: selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: IncidentCategory.fasilitasRusak,
                          child: Text('Fasilitas Umum Rusak',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: IncidentCategory.lampuMati,
                          child: Text('Lampu Penerangan Mati',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: IncidentCategory.sampah,
                          child: Text('Tumpukan Sampah / Saluran Tersumbat',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: IncidentCategory.orangMencurigakan,
                          child: Text('Aktivitas Mencurigakan',
                              style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: IncidentCategory.lainnya,
                          child: Text('Masalah Lainnya',
                              style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Keterangan & Lokasi Kejadian:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText:
                          'Contoh: Lampu tiang no 3 di gang buntu mati sudah 2 hari...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.photo_camera, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Foto bukti lampiran kamera otomatis disertakan via GPS.',
                            style:
                                TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight),
                onPressed: () {
                  final text = noteController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Harap tuliskan keterangan laporan.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ronda.reportIncident(
                    category: selectedCategory,
                    keterangan: text,
                    photoPath:
                        '/storage/emulated/0/DCIM/laporan_warga_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Laporan warga berhasil dikirim ke Pengurus RT & Petugas Ronda!'),
                      backgroundColor: AppColors.verified,
                    ),
                  );
                },
                child: const Text('Kirim Laporan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCivicIncidentsHistory(
      BuildContext context, RondaProvider ronda) {
    final myIncidents = ronda.incidents
        .where((i) => i.userId == ronda.currentUser?.id)
        .toList();
    if (myIncidents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Riwayat Laporan Temuan Warga Saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Text('${myIncidents.length} Laporan',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ...myIncidents.take(3).map((report) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.patrolAccentLight,
                    radius: 16,
                    child: const Icon(Icons.build,
                        size: 16, color: AppColors.patrolAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              report.category.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd/MM HH:mm')
                                  .format(report.createdAt),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          report.keterangan,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ],
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

  Widget _buildResolvedSosAuditSection(
      BuildContext context, RondaProvider ronda) {
    final resolved = ronda.resolvedEmergencies;
    if (resolved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.health_and_safety, color: AppColors.verified, size: 20),
            SizedBox(width: 8),
            Text(
              'Transparansi Penanganan Darurat RT (Selesai)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...resolved.take(2).map((event) {
          final dur = event.durationToResolve != null
              ? '${event.durationToResolve!.inMinutes} menit'
              : '-';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.verified, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Darurat: ${event.userName} (${event.userAddress})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Tertangani oleh: ${event.respondedByUserName ?? "Petugas"} • Durasi: $dur',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black87),
                        ),
                      ],
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

  Widget _buildEmergencyContactsCard(BuildContext context) {
    final contacts = [
      {
        'name': 'Pos Kamling Utama RT 04',
        'phone': '0812-3456-7801',
        'role': 'Pos Ronda'
      },
      {
        'name': 'Ketua RT 04 (Nicholas Benaya)',
        'phone': '0812-3456-7801',
        'role': 'Admin RT'
      },
      {
        'name': 'Polsek Sukolilo Surabaya',
        'phone': '031-5947110',
        'role': 'Polisi'
      },
      {
        'name': 'Command Center 112 / Damkar',
        'phone': '112',
        'role': 'Darurat'
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Nomor Penting & Darurat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...contacts.map((c) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  radius: 16,
                  child: const Icon(Icons.phone,
                      color: AppColors.secondary, size: 16),
                ),
                title: Text(c['name']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${c['phone']} • ${c['role']}',
                    style: const TextStyle(fontSize: 11)),
              );
            }),
          ],
        ),
      ),
    );
  }
}
