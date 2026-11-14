import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/ronda/models/ronda_models.dart';
import '../../../providers/ronda_provider.dart';

/// Dasbor Utama Khusus Warga: Fokus pada Tombol Panik SOS, QR Verifikasi Darurat, dan Roster Keamanan Lingkungan
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

          // 4. Petugas Ronda yang Bertugas Malam Ini
          _buildTonightPatrolCard(context, ronda),
          const SizedBox(height: 16),

          // 5. Kontak Darurat Lingkungan RT
          _buildEmergencyContactsCard(context),
        ],
      ),
    );
  }

  Widget _buildNotification(BuildContext context, String text, {required bool isError}) {
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
              text,
              style: TextStyle(color: isError ? Colors.red.shade900 : Colors.green.shade900, fontSize: 12),
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
        badgeColor = Colors.red;
        badgeText = 'BELUM DITANGANI (Alarm Berdering di Seluruh RT)';
        break;
      case EmergencyStatus.onGoing:
        badgeColor = Colors.orange;
        badgeText = 'SEDANG DIRESPONS (Petugas ${event.respondedByUserName ?? ''} Menuju Rumah Anda)';
        break;
      case EmergencyStatus.menungguVerifikasiRt:
        badgeColor = Colors.purple;
        badgeText = 'PENANGANAN BERFOTO (Menunggu Verifikasi RT)';
        break;
      case EmergencyStatus.selesai:
        badgeColor = Colors.green;
        badgeText = 'SELESAI / TERTANGANI';
        break;
    }

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.crisis_alert, color: Colors.red, size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ALARM DARURAT ANDA AKTIF',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
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
                color: badgeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withAlpha(80)),
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
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: QrImageView(
                data: event.verificationQrToken,
                version: QrVersions.auto,
                size: 170.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.verificationQrToken,
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Tombol Batalkan Alarm
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => ronda.cancelMyEmergency(event.id),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Alarm (Kondisi Aman / Salah Pencet)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol Panik Utama saat dalam Kondisi Aman
  Widget _buildPanicTriggerCard(BuildContext context, RondaProvider ronda) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Tombol Panik Keamanan (SOS)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tekan jika Anda melihat bahaya, maling, kebakaran, atau membutuhkan bantuan darurat siskamling malam ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Tombol Bulat Besar
            GestureDetector(
              onTap: () => _confirmTriggerPanic(context, ronda),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 36),
                    SizedBox(height: 4),
                    Text(
                      'SOS',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'DARURAT',
                      style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sinyal alarm akan memicu sirine di smartphone seluruh petugas ronda dan Ketua RT.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTriggerPanic(BuildContext context, RondaProvider ronda) {
    _sosNoteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Alarm SOS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin membunyikan alarm darurat siskamling?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sosNoteController,
              decoration: const InputDecoration(
                labelText: 'Keterangan Situasi (Opsional)',
                hintText: 'Misal: Ada suara mencurigakan di atap',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  Widget _buildTonightPatrolCard(BuildContext context, RondaProvider ronda) {
    final schedules = ronda.schedules;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: Colors.teal, size: 22),
                SizedBox(width: 8),
                Text(
                  'Petugas Ronda Malam Ini',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (schedules.isEmpty)
              const Text('Belum ada jadwal patroli aktif.', style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              ...schedules.map((s) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 16,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  title: Text(s.petugasName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Jaga: ${s.jamMulai} - ${s.jamSelesai} WIB', style: const TextStyle(fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Aktif Patroli', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                );
              }),
          ],
        ),
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
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.blue, size: 22),
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
                  backgroundColor: Colors.blue.shade100,
                  radius: 16,
                  child: Icon(Icons.phone, color: Colors.blue.shade900, size: 16),
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
