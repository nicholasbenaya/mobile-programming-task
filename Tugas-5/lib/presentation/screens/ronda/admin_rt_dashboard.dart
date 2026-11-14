import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/ronda/models/ronda_models.dart';
import '../../../providers/ronda_provider.dart';

/// Dasbor Utama Khusus Ketua RT (Admin): Berpusat pada Pengawasan, Log Real-time, Verifikasi Laporan & Persetujuan
class AdminRtDashboard extends StatelessWidget {
  const AdminRtDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ronda = context.watch<RondaProvider>();
    final user = ronda.currentUser!;

    final activeSos = ronda.emergencyEvents.where((e) => e.isActive).toList();
    final pendingSwaps = ronda.shiftSwaps.where((s) => s.status == ShiftSwapStatus.acceptedByTarget || s.status == ShiftSwapStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pusat Komando & Log RT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Ketua RT: ${user.namaLengkap}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
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
          // 1. Ringkasan Status Keamanan Wilayah
          _buildSummaryCards(context, ronda, activeSos.length, pendingSwaps.length),
          const SizedBox(height: 20),

          // 2. Banner Darurat Aktif (Jika ada)
          if (activeSos.isNotEmpty) ...[
            _buildActiveSosSection(context, ronda, activeSos),
            const SizedBox(height: 20),
          ],

          // 3. Persetujuan Perpindahan Jadwal (Shift Swap Approval)
          _buildShiftSwapSection(context, ronda, pendingSwaps),
          const SizedBox(height: 20),

          // 4. Log Check-in Patroli Petugas (Live Audit Feed)
          _buildPatrolLogSection(context, ronda),
          const SizedBox(height: 20),

          // 5. Linimasa Insiden Berfoto
          _buildIncidentSection(context, ronda),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, RondaProvider ronda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Ketua RT?'),
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

  Widget _buildSummaryCards(BuildContext context, RondaProvider ronda, int activeSosCount, int pendingSwapCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Insiden SOS',
            value: activeSosCount.toString(),
            subtitle: activeSosCount > 0 ? 'Perlu Dipantau' : 'Kondisi Aman',
            icon: Icons.warning_amber_rounded,
            color: activeSosCount > 0 ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Tukar Jadwal',
            value: pendingSwapCount.toString(),
            subtitle: pendingSwapCount > 0 ? 'Menunggu Approval' : 'Semua Beres',
            icon: Icons.swap_horiz,
            color: pendingSwapCount > 0 ? Colors.amber.shade800 : Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Patroli Masuk',
            value: ronda.patrolLogs.length.toString(),
            subtitle: 'Log Terverifikasi',
            icon: Icons.verified,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSosSection(BuildContext context, RondaProvider ronda, List<EmergencyEvent> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notification_important, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Manajemen Insiden Darurat (SOS)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${list.length} Kejadian',
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...list.map((event) => _buildSosCard(context, ronda, event)),
      ],
    );
  }

  Widget _buildSosCard(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (event.status) {
      case EmergencyStatus.belumDitangani:
        statusColor = Colors.red;
        statusTitle = 'BELUM DITANGANI';
        statusIcon = Icons.hourglass_top;
        break;
      case EmergencyStatus.onGoing:
        statusColor = Colors.orange;
        statusTitle = 'ON-GOING (SEDANG DIRESPONS)';
        statusIcon = Icons.directions_run;
        break;
      case EmergencyStatus.menungguVerifikasiRt:
        statusColor = Colors.purple;
        statusTitle = 'MENUNGGU VERIFIKASI RT (BUKTI FOTO)';
        statusIcon = Icons.policy;
        break;
      case EmergencyStatus.selesai:
        statusColor = Colors.green;
        statusTitle = 'SELESAI';
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withAlpha(120), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(event.triggeredAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 16),
            // Info Pelapor
            Text(
              event.userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              'Lokasi: ${event.userAddress}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            if (event.catatan != null) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: "${event.catatan}"',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 8),

            // Petugas yang merespons
            if (event.respondedByUserName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Petugas Penangan: ${event.respondedByUserName}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Khusus Status: MENUNGGU VERIFIKASI RT (Foto Bukti)
            if (event.status == EmergencyStatus.menungguVerifikasiRt) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_camera, size: 18, color: Colors.purple.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Bukti Foto Lapangan Petugas:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keterangan: ${event.resolutionNotes ?? "-"}\nFile: ${event.resolutionPhotoPath}',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => _handleAdminVerification(context, ronda, event, false),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Tolak Laporan'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                            onPressed: () => _handleAdminVerification(context, ronda, event, true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Setujui (Selesai)'),
                          ),
                        ),
                      ],
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

  void _handleAdminVerification(BuildContext context, RondaProvider ronda, EmergencyEvent event, bool isApproved) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApproved ? 'Konfirmasi Verifikasi Laporan' : 'Tolak & Kembalikan ke Petugas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApproved
                  ? 'Apakah Anda yakin bukti foto di atas memadai dan status darurat ${event.userName} resmi diselesaikan?'
                  : 'Status akan dikembalikan ke ON-GOING agar petugas melakukan pengecekan ulang di lokasi warga.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Ketua RT (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isApproved ? Colors.green : Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ronda.adminVerifyEmergency(
                eventId: event.id,
                isApproved: isApproved,
                adminNotes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isApproved ? 'Insiden resmi disetujui SELESAI.' : 'Insiden dikembalikan ke petugas.'),
                ),
              );
            },
            child: Text(isApproved ? 'Setujui & Selesaikan' : 'Tolak Laporan'),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSwapSection(BuildContext context, RondaProvider ronda, List<ShiftSwapRequest> requests) {
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
            Row(
              children: [
                const Icon(Icons.swap_calls, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Approval Pertukaran Jadwal Ronda',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                if (requests.isEmpty)
                  const Text('Tidak ada antrean', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            if (requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Semua permohonan pertukaran jadwal telah diproses.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              )
            else
              ...requests.map((req) {
                final isWaitingAdmin = req.status == ShiftSwapStatus.acceptedByTarget;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${req.requesterName}  ➔  ${req.targetUserName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isWaitingAdmin ? Colors.amber.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isWaitingAdmin ? Colors.amber.shade900 : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Alasan: "${req.alasan}"', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      if (isWaitingAdmin) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => ronda.approveShiftSwap(requestId: req.id, isApproved: false),
                              child: const Text('Tolak'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => ronda.approveShiftSwap(requestId: req.id, isApproved: true),
                              child: const Text('Setujui Perubahan'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPatrolLogSection(BuildContext context, RondaProvider ronda) {
    final logs = ronda.patrolLogs;
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
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: Colors.teal, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Log Check-in Pos Patroli (Live Feed)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text('${logs.length} Rekaman', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada check-in petugas yang terekam malam ini.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              )
            else
              ...logs.take(5).map((log) {
                final cp = ronda.checkpoints.where((c) => c.id == log.checkpointId).firstOrNull;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 16,
                    child: Icon(Icons.qr_code, size: 16, color: Colors.white),
                  ),
                  title: Text(
                    cp?.namaLokasi ?? log.checkpointId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Jarak GPS: ${log.distanceMeter.toStringAsFixed(1)}m | Akurasi: ${log.accuracy?.toStringAsFixed(1) ?? "-"}m',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('HH:mm:ss').format(log.scannedAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text(log.syncStatus.name.toUpperCase(), style: TextStyle(fontSize: 9, color: Colors.green.shade700)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentSection(BuildContext context, RondaProvider ronda) {
    final incidents = ronda.incidents;
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
            Row(
              children: [
                const Icon(Icons.report_problem_outlined, color: Colors.deepOrange, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Log Temuan Insiden Berfoto',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text('${incidents.length} Laporan', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (incidents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Kondisi lingkungan aman terkendali. Belum ada insiden dilaporkan.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              )
            else
              ...incidents.map((inc) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    radius: 16,
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                  title: Text(
                    inc.category.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${inc.keterangan}\nPelapor: ${inc.reporterName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    DateFormat('HH:mm').format(inc.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
