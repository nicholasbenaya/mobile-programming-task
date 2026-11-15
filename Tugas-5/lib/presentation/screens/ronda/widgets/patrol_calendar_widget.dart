import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/ronda_provider.dart';

/// Komponen Kalender Jadwal Ronda Bersama (Transparan untuk RT, Petugas, dan Warga)
class PatrolCalendarWidget extends StatefulWidget {
  const PatrolCalendarWidget({
    super.key,
    required this.ronda,
    this.allowAdminManagement = false,
  });

  final RondaProvider ronda;
  final bool allowAdminManagement;

  @override
  State<PatrolCalendarWidget> createState() => _PatrolCalendarWidgetState();
}

class _PatrolCalendarWidgetState extends State<PatrolCalendarWidget> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _showAutoScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.patrolAccent),
            SizedBox(width: 8),
            Text('Atur Jadwal Otomatis', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistem akan menyusun rotasi jadwal secara otomatis dengan aturan:',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '• Pola 5 hari ronda aktif + 1 hari libur untuk setiap petugas.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '• Shift berputar merata (Malam, Sore, Siang) tanpa kekosongan jaga.',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '• Berlaku untuk 30 hari ke depan.',
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
              widget.ronda.generateAutoRoster(startDate: DateTime.now(), daysCount: 30);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jadwal ronda otomatis 30 hari berhasil disusun!')),
              );
            },
            child: const Text('Terapkan Jadwal'),
          ),
        ],
      ),
    );
  }

  void _showManualAssignDialog(BuildContext context) {
    final officers = widget.ronda.allOfficers;
    if (officers.isEmpty) return;

    String selectedUserId = officers.first.id;
    DateTime assignDate = _selectedDate;
    String selectedShift = 'Shift Malam (22:00 - 04:00)';
    String jamMulai = '22:00';
    String jamSelesai = '04:00';
    bool isLibur = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tugaskan Jadwal Petugas', style: TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Petugas
                  const Text('Pilih Petugas Ronda:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: officers.map((o) {
                      return DropdownMenuItem(value: o.id, child: Text(o.namaLengkap, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedUserId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tanggal
                  const Text('Tanggal Ronda:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(assignDate), style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: assignDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setDialogState(() => assignDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Pilihan Shift
                  const Text('Pilihan Shift:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedShift,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(
                        value: 'Shift Malam (22:00 - 04:00)',
                        child: Text('Shift Malam (22:00 - 04:00)', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'Shift Sore (16:00 - 22:00)',
                        child: Text('Shift Sore (16:00 - 22:00)', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'Shift Siang (08:00 - 16:00)',
                        child: Text('Shift Siang (08:00 - 16:00)', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: isLibur
                        ? null
                        : (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedShift = val;
                                if (val.contains('Malam')) {
                                  jamMulai = '22:00';
                                  jamSelesai = '04:00';
                                } else if (val.contains('Sore')) {
                                  jamMulai = '16:00';
                                  jamSelesai = '22:00';
                                } else {
                                  jamMulai = '08:00';
                                  jamSelesai = '16:00';
                                }
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 10),

                  // Switch Libur
                  SwitchListTile(
                    title: const Text('Tetapkan Sebagai Hari Libur / Istirahat', style: TextStyle(fontSize: 12)),
                    value: isLibur,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isLibur = val;
                        if (isLibur) {
                          selectedShift = 'Libur Piket (Hari Istirahat)';
                          jamMulai = '-';
                          jamSelesai = '-';
                        } else {
                          selectedShift = 'Shift Malam (22:00 - 04:00)';
                          jamMulai = '22:00';
                          jamSelesai = '04:00';
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.ronda.assignScheduleManual(
                    userId: selectedUserId,
                    date: assignDate,
                    shiftName: selectedShift,
                    jamMulai: jamMulai,
                    jamSelesai: jamSelesai,
                    isLibur: isLibur,
                  );
                  setState(() => _selectedDate = assignDate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jadwal berhasil disimpan!')),
                  );
                },
                child: const Text('Simpan Jadwal'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedulesForDay = widget.ronda.getSchedulesForDate(_selectedDate);

    // Daftar 14 hari ke depan untuk pemilih tanggal horizontal
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayList = List.generate(14, (idx) => today.add(Duration(days: idx)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kalender
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kalender & Roster Jadwal Ronda',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (widget.allowAdminManagement)
                  PopupMenuButton<String>(
                    tooltip: 'Kelola Jadwal',
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'auto') _showAutoScheduleDialog(context);
                      if (val == 'manual') _showManualAssignDialog(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'auto',
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: AppColors.patrolAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Atur Jadwal Otomatis (5-1)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'manual',
                        child: Row(
                          children: [
                            Icon(Icons.add_task, color: AppColors.secondary, size: 18),
                            SizedBox(width: 8),
                            Text('Tugaskan Petugas Manual'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Date Picker
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dayList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final day = dayList[idx];
                  final isSelected = day.year == _selectedDate.year &&
                      day.month == _selectedDate.month &&
                      day.day == _selectedDate.day;
                  final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedDate = day),
                    child: Container(
                      width: 54,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : (isToday ? AppColors.secondaryContainer.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerLow),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryLight
                              : (isToday ? AppColors.secondary : theme.colorScheme.outlineVariant),
                          width: isSelected || isToday ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE', 'id_ID').format(day),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday ? AppColors.secondary : theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Label Tanggal Terpilih
            Row(
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${schedulesForDay.length} Petugas Terdaftar',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const Divider(height: 16),

            // Daftar Petugas Terjadwal pada Hari Tersebut
            if (schedulesForDay.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Belum ada petugas yang dijadwalkan pada tanggal ini.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedulesForDay.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final sched = schedulesForDay[idx];
                  final isToday = _selectedDate.year == today.year &&
                      _selectedDate.month == today.month &&
                      _selectedDate.day == today.day;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: sched.isLibur
                          ? theme.colorScheme.surfaceContainerLow
                          : (isToday ? AppColors.patrolAccentLight.withValues(alpha: 0.3) : theme.colorScheme.surface),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sched.isLibur
                            ? theme.colorScheme.outlineVariant
                            : (isToday ? AppColors.patrolAccent.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: sched.isLibur ? Colors.grey.shade300 : AppColors.primaryContainer,
                          child: Icon(
                            sched.isLibur ? Icons.hotel : Icons.shield,
                            size: 16,
                            color: sched.isLibur ? Colors.grey.shade700 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sched.petugasName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: sched.isLibur ? Colors.grey.shade700 : null,
                                ),
                              ),
                              Text(
                                sched.shiftName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sched.isLibur ? Colors.grey.shade600 : AppColors.patrolAccent,
                                  fontWeight: sched.isLibur ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sched.isLibur
                                ? Colors.grey.shade200
                                : (isToday ? AppColors.verifiedLight : Colors.blue.shade50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sched.isLibur
                                ? 'Libur'
                                : (isToday ? 'Piket Hari Ini' : '${sched.jamMulai} - ${sched.jamSelesai}'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: sched.isLibur
                                  ? Colors.grey.shade700
                                  : (isToday ? AppColors.verified : Colors.blue.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Tombol Pintasan Tambah Jadwal untuk RT
            if (widget.allowAdminManagement) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showManualAssignDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tugaskan Petugas', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showAutoScheduleDialog(context),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Otomatis (5-1)', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
