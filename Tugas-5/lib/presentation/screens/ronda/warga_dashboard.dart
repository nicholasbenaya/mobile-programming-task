import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/ronda/models/ronda_models.dart';
import '../../../providers/ronda_provider.dart';
import 'widgets/patrol_calendar_widget.dart';

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
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
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
            _buildNotification(context, ronda.lastSuccessMessage!, isError: false),
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

          // 4. Kalender & Roster Jadwal Ronda Transparan untuk Warga
          PatrolCalendarWidget(ronda: ronda, allowAdminManagement: false),
          const SizedBox(height: 16),

          // 5. Kontak Darurat Lingkungan RT
          _buildEmergencyContactsCard(context),
        ],
      ),
    );
  }

  Widget _buildNotification(BuildContext context, String text, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.emergencyLight : AppColors.verifiedLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isError ? AppColors.emergency : AppColors.verified),
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
  Widget _buildActiveEmergencyCard(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    Color badgeColor;
    String badgeText;

    switch (event.status) {
      case EmergencyStatus.belumDitangani:
        badgeColor = AppColors.emergency;
        badgeText = 'BELUM DITANGANI (Alarm Berdering di Seluruh RT)';
        break;
      case EmergencyStatus.onGoing:
        badgeColor = AppColors.patrolAccent;
        badgeText = 'SEDANG DIRESPONS (Petugas ${event.respondedByUserName ?? ""} Menuju Rumah Anda)';
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
                const Icon(Icons.crisis_alert, color: AppColors.emergency, size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ALARM DARURAT ANDA AKTIF',
                    style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(DateFormat('HH:mm:ss').format(event.triggeredAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
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
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
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
              label: const Text('Batalkan Panggilan Darurat Ini (Salah Tekan)', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelEmergency(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Alarm Darurat?'),
        content: const Text('Apakah Anda yakin situasi telah terkendali dan ingin mematikan alarm SOS?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
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
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
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
    _sosNoteController.text = 'Melihat orang asing memanjat pagar rumah tetangga!';
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
            onPressed: () {
              Navigator.pop(ctx);
              ronda.triggerPanic(
                catatan: _sosNoteController.text.trim().isEmpty ? null : _sosNoteController.text.trim(),
              );
            },
            child: const Text('BUNYIKAN ALARM'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(BuildContext context) {
    final contacts = [
      {'name': 'Pos Kamling Utama RT 04', 'phone': '0812-3456-7801', 'role': 'Pos Ronda'},
      {'name': 'Ketua RT 04 (Nicholas Benaya)', 'phone': '0812-3456-7801', 'role': 'Admin RT'},
      {'name': 'Polsek Sukolilo Surabaya', 'phone': '031-5947110', 'role': 'Polisi'},
      {'name': 'Command Center 112 / Damkar', 'phone': '112', 'role': 'Darurat'},
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
                  child: const Icon(Icons.phone, color: AppColors.secondary, size: 16),
                ),
                title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${c['phone']} • ${c['role']}', style: const TextStyle(fontSize: 11)),
              );
            }),
          ],
        ),
      ),
    );
  }
}
