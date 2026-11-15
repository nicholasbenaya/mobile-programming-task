import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/ronda/models/ronda_models.dart';
import '../../../providers/ronda_provider.dart';
import 'widgets/dynamic_roster_calendar_dialog.dart';
import 'widgets/patrol_calendar_widget.dart';
import 'widgets/patrol_interactive_map.dart';

/// Dasbor Utama Khusus Ketua RT (Admin): Berpusat pada Pengawasan, Log Real-time, Verifikasi Laporan & Persetujuan
class AdminRtDashboard extends StatelessWidget {
  const AdminRtDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ronda = context.watch<RondaProvider>();
    final user = ronda.currentUser!;

    final activeSos = ronda.emergencyEvents.where((e) => e.isActive).toList();
    final pendingSwaps = ronda.shiftSwaps
        .where((s) => s.status == ShiftSwapStatus.acceptedByTarget || s.status == ShiftSwapStatus.pending)
        .toList();
    final onDutyOfficers = ronda.onDutyOfficersToday;
    final overdueCps = ronda.overdueCheckpoints;

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
              'Ketua RT: ${user.namaLengkap} - RT 04 / RW 02',
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
          // Banner Notifikasi Sukses / Error
          if (ronda.lastErrorMessage != null) ...[
            _buildNotificationBanner(context, ronda.lastErrorMessage!, isError: true),
            const SizedBox(height: 12),
          ],
          if (ronda.lastSuccessMessage != null) ...[
            _buildNotificationBanner(context, ronda.lastSuccessMessage!, isError: false),
            const SizedBox(height: 12),
          ],

          // 1. Ringkasan Status Keamanan Wilayah
          _buildSummaryCards(context, ronda, activeSos.length, pendingSwaps.length, onDutyOfficers.length),
          const SizedBox(height: 16),

          // 2. Peta Interaktif Patroli Wilayah RT
          _buildPatrolMapCard(context, ronda),
          const SizedBox(height: 16),

          // 3. Kejelasan Jadwal: Petugas yang Sedang Berjaga Hari Ini
          _buildTonightRosterCard(context, ronda, onDutyOfficers),
          const SizedBox(height: 16),

          // 4. Banner Darurat Aktif (Jika ada SOS) dengan Fitur Broadcast Ketua RT
          if (activeSos.isNotEmpty) ...[
            _buildActiveSosSection(context, ronda, activeSos),
            const SizedBox(height: 16),
          ],

          // 5. Pengawasan Pos Patroli & Peringatan Check-in Manual
          _buildCheckpointSupervisionCard(context, ronda, overdueCps),
          const SizedBox(height: 16),

          // 6. Kalender & Manajemen Jadwal Ronda (Auto-Scheduler 5-1 + Manual Assign)
          PatrolCalendarWidget(ronda: ronda, allowAdminManagement: true),
          const SizedBox(height: 16),

          // 7. Log Mutasi Jadwal Ronda (Laporan Pertukaran Rekan Petugas)
          _buildShiftSwapSection(context, ronda, pendingSwaps),
          const SizedBox(height: 16),

          // 8. Riwayat Audit Penanganan Darurat (SOS) Selesai
          _buildResolvedSosAuditSection(context, ronda),
          const SizedBox(height: 16),

          // 9. Log Check-in Patroli Petugas (Live Audit Feed)
          _buildPatrolLogSection(context, ronda),
          const SizedBox(height: 16),

          // 10. Linimasa Insiden Berfoto
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

  Widget _buildSummaryCards(BuildContext context, RondaProvider ronda, int activeSosCount, int pendingSwapCount, int onDutyCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Insiden SOS',
            value: activeSosCount.toString(),
            subtitle: activeSosCount > 0 ? 'Perlu Respons' : 'Aman',
            icon: Icons.warning_amber_rounded,
            color: activeSosCount > 0 ? AppColors.emergency : AppColors.verified,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Petugas Piket',
            value: onDutyCount.toString(),
            subtitle: 'Bertugas Hari Ini',
            icon: Icons.shield,
            color: onDutyCount > 0 ? AppColors.patrolAccent : Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Tukar Jadwal',
            value: pendingSwapCount.toString(),
            subtitle: pendingSwapCount > 0 ? 'Menunggu Approval' : 'Selesai',
            icon: Icons.swap_horiz,
            color: pendingSwapCount > 0 ? AppColors.secondary : AppColors.verified,
          ),
        ),
      ],
    );
  }

  /// Kejelasan Jadwal: Menampilkan siapa yang seharusnya sedang berjaga hari ini
  Widget _buildTonightRosterCard(BuildContext context, RondaProvider ronda, List<RondaUser> onDutyOfficers) {
    final now = DateTime.now();
    final todaySchedules = ronda.getSchedulesForDate(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge, color: AppColors.patrolAccent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Petugas Berjaga Hari Ini (Piket Ronda)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => DynamicRosterCalendarDialog.show(
                    context: context,
                    mode: CalendarDialogMode.adminAssign,
                  ),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Atur di Kalender', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todaySchedules.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.patrolAccentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.patrolAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan: Belum ada petugas yang dijadwalkan piket hari ini. Gunakan kalender di bawah untuk mengatur jadwal.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaySchedules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final s = todaySchedules[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: s.isLibur ? Colors.grey.shade100 : AppColors.patrolAccentLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: s.isLibur ? Colors.grey.shade300 : AppColors.patrolAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: s.isLibur ? Colors.grey.shade400 : AppColors.primaryLight,
                          child: Icon(
                            s.isLibur ? Icons.hotel : Icons.person,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.petugasName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                s.shiftName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: s.isLibur ? Colors.grey.shade700 : AppColors.patrolAccent,
                                  fontWeight: s.isLibur ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.isLibur ? Colors.grey.shade300 : AppColors.verifiedLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.isLibur ? 'Libur' : 'Aktif Piket',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: s.isLibur ? Colors.grey.shade800 : AppColors.verified,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Pengawasan Pos Patroli & Kemampuan Peringatan Manual Check-in oleh Ketua RT
  Widget _buildCheckpointSupervisionCard(BuildContext context, RondaProvider ronda, List<Checkpoint> overdueCps) {
    final checkpoints = ronda.checkpoints;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rtl, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Jadwal Patroli Pos Fisik & Status Check-in',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (overdueCps.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${overdueCps.length} Pos Terlewat',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emergency),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...checkpoints.map((cp) {
              final status = ronda.getCheckpointStatus(cp);
              Color badgeColor;
              String badgeText;

              switch (status) {
                case CheckpointScheduleStatus.sebelum:
                  badgeColor = Colors.blue.shade700;
                  badgeText = 'Mendatang (${cp.targetWaktuCheckin})';
                  break;
                case CheckpointScheduleStatus.saat:
                  badgeColor = AppColors.patrolAccent;
                  badgeText = 'WAKTUNYA SCAN!';
                  break;
                case CheckpointScheduleStatus.terlewat:
                  badgeColor = AppColors.emergency;
                  badgeText = 'TERLEWAT';
                  break;
                case CheckpointScheduleStatus.selesai:
                  badgeColor = AppColors.verified;
                  badgeText = 'Sudah Di-scan';
                  break;
              }

              final isOverdue = status == CheckpointScheduleStatus.terlewat;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOverdue ? AppColors.emergencyLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverdue ? AppColors.emergency.withValues(alpha: 0.5) : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == CheckpointScheduleStatus.selesai ? Icons.check_circle : Icons.timer,
                      size: 16,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${cp.kodeTitik} - ${cp.namaLokasi}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Target: ${cp.targetWaktuCheckin} WIB (Toleransi ${cp.windowMenitSetelah}m)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Notify Manual RT
                    IconButton(
                      tooltip: 'Peringatkan Petugas Check-in',
                      icon: const Icon(Icons.notification_add, size: 18, color: AppColors.patrolAccent),
                      onPressed: () {
                        ronda.notifyCheckpointReminder(checkpointId: cp.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Peringatan check-in untuk ${cp.kodeTitik} telah dikirim ke petugas.')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSosSection(BuildContext context, RondaProvider ronda, List<EmergencyEvent> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notification_important, color: AppColors.emergency, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Manajemen Insiden Darurat (SOS)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emergencyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${list.length} Kejadian',
                style: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 11),
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
        statusColor = AppColors.emergency;
        statusTitle = 'BELUM DITANGANI';
        statusIcon = Icons.hourglass_top;
        break;
      case EmergencyStatus.onGoing:
        statusColor = AppColors.patrolAccent;
        statusTitle = 'ON-GOING (SEDANG DIRESPONS)';
        statusIcon = Icons.directions_run;
        break;
      case EmergencyStatus.menungguVerifikasiRt:
        statusColor = Colors.purple;
        statusTitle = 'MENUNGGU VERIFIKASI RT (BUKTI FOTO)';
        statusIcon = Icons.policy;
        break;
      case EmergencyStatus.selesai:
        statusColor = AppColors.verified;
        statusTitle = 'SELESAI';
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
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
              style: const TextStyle(fontSize: 13),
            ),
            if (event.catatan != null) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: "${event.catatan}"',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 10),

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
            const SizedBox(height: 10),

            // Tombol Khusus Ketua RT: Broadcast / Peringatkan Petugas (Piket & Cadangan)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emergencyLight,
                  foregroundColor: AppColors.emergency,
                ),
                onPressed: () => _showBroadcastOfficerDialog(context, ronda, event),
                icon: const Icon(Icons.campaign, size: 18),
                label: const Text('Broadcast Peringatan ke Semua Petugas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.emergency),
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

  /// Dialog Broadcast Panggilan Siaga Ketua RT
  void _showBroadcastOfficerDialog(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    bool includeOffDuty = true;
    final messageController = TextEditingController(
      text: 'PERINTAH KETUA RT: Panggilan darurat aktif di ${event.userAddress} (Pelapor: ${event.userName}). Seluruh personel siaga!',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.campaign, color: AppColors.emergency),
                SizedBox(width: 8),
                Text('Peringatkan Petugas Ronda', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kirimkan notifikasi darurat prioritas tinggi ke perangkat petugas ronda:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sertakan Petugas Cadangan / Sedang Libur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Jika dicentang, semua petugas ronda terdaftar akan menerima peringatan darurat ini.', style: TextStyle(fontSize: 10)),
                  value: includeOffDuty,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => includeOffDuty = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Instruksi Khusus Ketua RT',
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
                  ronda.broadcastSosToOfficers(
                    eventId: event.id,
                    includeOffDuty: includeOffDuty,
                    customMessage: messageController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Peringatan darurat berhasil dipancarkan ke seluruh petugas ronda!')),
                  );
                },
                child: const Text('Kirim Peringatan'),
              ),
            ],
          );
        },
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
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isApproved ? AppColors.verified : AppColors.emergency,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ronda.adminVerifyEmergency(
                eventId: event.id,
                isApproved: isApproved,
                adminNotes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
            },
            child: Text(isApproved ? 'Setujui (Selesai)' : 'Tolak'),
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
                const Icon(Icons.map, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Peta Pemantauan Patroli Siskamling RT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  '${ronda.checkpoints.length} Pos Ronda Terdaftar',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 230,
            child: PatrolInteractiveMap(height: 230),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSwapSection(BuildContext context, RondaProvider ronda, List<ShiftSwapRequest> list) {
    final allSwaps = ronda.shiftSwaps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sync_alt, color: AppColors.secondary, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Log Mutasi Jadwal Patroli (Persetujuan Rekan)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Text('${allSwaps.length} Entri', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Pertukaran jadwal langsung berlaku saat disetujui rekan bersangkutan (Peer Consent) tanpa birokrasi, tercatat di log audit RT.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        if (allSwaps.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Belum ada riwayat mutasi / pertukaran jadwal antar petugas.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          )
        else
          ...allSwaps.take(4).map((req) {
            Color statusColor;
            String statusText;
            switch (req.status) {
              case ShiftSwapStatus.acceptedByTarget:
              case ShiftSwapStatus.approvedByAdmin:
                statusColor = AppColors.verified;
                statusText = 'Disetujui Rekan (Jadwal Aktif)';
                break;
              case ShiftSwapStatus.rejected:
                statusColor = AppColors.emergency;
                statusText = 'Ditolak Rekan';
                break;
              case ShiftSwapStatus.pending:
                statusColor = AppColors.patrolAccent;
                statusText = 'Menunggu Respon Rekan';
                break;
              case ShiftSwapStatus.expired:
                statusColor = AppColors.textSecondaryLight;
                statusText = 'Kedaluwarsa (H-3 Jam)';
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${req.requesterName} ➔ ${req.targetUserName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shift: ${req.requesterShift} ➔ ${req.targetShift}'
                      '${req.targetDate != null ? " (${DateFormat("dd/MM/yyyy").format(req.targetDate!)})" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (req.alasan.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Alasan: "${req.alasan}"',
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

  Widget _buildResolvedSosAuditSection(BuildContext context, RondaProvider ronda) {
    final resolvedList = ronda.resolvedEmergencies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user, color: AppColors.verified, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Riwayat Audit Penanganan Darurat (SOS) Selesai',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Text('${resolvedList.length} Selesai', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        if (resolvedList.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Belum ada riwayat insiden darurat yang diselesaikan.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          )
        else
          ...resolvedList.take(4).map((event) {
            final durRespond = event.durationToRespond != null
                ? '${event.durationToRespond!.inMinutes}m'
                : '-';
            final durResolve = event.durationToResolve != null
                ? '${event.durationToResolve!.inMinutes}m'
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
                          child: Text(
                            'SELESAI - ${event.resolvedVia?.label ?? "Verifikasi"}',
                            style: const TextStyle(color: AppColors.verified, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          event.resolvedAt != null ? DateFormat('dd/MM/yy HH:mm').format(event.resolvedAt!) : '',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pelapor: ${event.userName} (${event.userAddress})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Petugas Penangan: ${event.respondedByUserName ?? "-"} • Respon: $durRespond • Penyelesaian: $durResolve',
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

  Widget _buildPatrolLogSection(BuildContext context, RondaProvider ronda) {
    final logs = ronda.patrolLogs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.secondary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Log Audit Check-in Patroli Real-time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text('${ronda.patrolLogs.length} Total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Belum ada data check-in patroli malam ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          )
        else
          ...logs.map((log) {
            final cp = ronda.checkpoints.where((c) => c.id == log.checkpointId).firstOrNull;
            final user = ronda.availableUsers.where((u) => u.id == log.userId).firstOrNull;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.verifiedLight,
                  child: Icon(Icons.check, color: AppColors.verified, size: 16),
                ),
                title: Text(
                  '${cp?.kodeTitik ?? "POS"} - ${cp?.namaLokasi ?? "Pos Ronda"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'Petugas: ${user?.namaLengkap ?? log.userId} • Jarak GPS: ${log.distanceMeter.toStringAsFixed(1)}m',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  DateFormat('HH:mm').format(log.scannedAt),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildIncidentSection(BuildContext context, RondaProvider ronda) {
    final incidents = ronda.incidents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library, color: Colors.deepOrange, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Laporan Insiden Berfoto Warga & Petugas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text('${incidents.length} Laporan', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        if (incidents.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Belum ada laporan insiden berfoto.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          )
        else
          ...incidents.map((inc) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inc.category.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                          Text(inc.keterangan, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('Pelapor: ${inc.reporterName} • ${DateFormat("HH:mm").format(inc.createdAt)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
