import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/ronda/models/ronda_models.dart';
import '../../../../providers/ronda_provider.dart';

enum CalendarDialogMode {
  adminAssign,
  officerSwap,
}

/// Dialog Kalender Dinamis Interaktif untuk:
/// 1. Penugasan Jadwal oleh Ketua RT (melihat ketersediaan & jadwal petugas per hari secara visual)
/// 2. Permintaan Tukar Jadwal oleh Petugas (memilih jadwal rekan yang ingin ditukar)
class DynamicRosterCalendarDialog extends StatefulWidget {
  const DynamicRosterCalendarDialog({
    super.key,
    required this.mode,
    this.initialDate,
  });

  final CalendarDialogMode mode;
  final DateTime? initialDate;

  static Future<void> show({
    required BuildContext context,
    required CalendarDialogMode mode,
    DateTime? initialDate,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DynamicRosterCalendarDialog(
        mode: mode,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<DynamicRosterCalendarDialog> createState() =>
      _DynamicRosterCalendarDialogState();
}

class _DynamicRosterCalendarDialogState
    extends State<DynamicRosterCalendarDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  // State untuk form penugasan RT
  String? _selectedOfficerId;
  String _selectedShiftName = 'Shift Malam (22:00 - 04:00)';
  String _jamMulai = '22:00';
  String _jamSelesai = '04:00';
  bool _isLibur = false;

  // State untuk permohonan tukar petugas
  PatrolSchedule? _selectedMySchedule;
  PatrolSchedule? _selectedColleagueSchedule;
  bool _isSubmittingSwap = false;
  final TextEditingController _swapReasonController = TextEditingController();

  static const List<Map<String, String>> _shiftPresets = [
    {'name': 'Shift Malam (22:00 - 04:00)', 'start': '22:00', 'end': '04:00'},
    {
      'name': 'Shift Dini Hari (02:00 - 08:00)',
      'start': '02:00',
      'end': '08:00'
    },
    {'name': 'Shift Sore (16:00 - 23:00)', 'start': '16:00', 'end': '23:00'},
    {
      'name': 'Shift Pagi-Siang (08:00 - 16:00)',
      'start': '08:00',
      'end': '16:00'
    },
  ];

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _swapReasonController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ronda = context.watch<RondaProvider>();
    final theme = Theme.of(context);
    final officers = ronda.allOfficers;
    final currentUser = ronda.currentUser;

    if (_selectedOfficerId == null && officers.isNotEmpty) {
      _selectedOfficerId = officers.first.id;
    }

    // Jadwal pada tanggal terpilih
    final schedulesForDay = ronda.getSchedulesForDate(_selectedDate);

    // Jangan tawarkan jadwal yang sudah melewati batas pengajuan H-3 jam.
    final now = DateTime.now();
    final mySchedules = ronda.schedules
        .where((s) =>
            s.userId == currentUser?.id &&
            !s.isLibur &&
            !s.isCompleted &&
            now.isBefore(s.startDateTime.subtract(const Duration(hours: 3))))
        .toList();
    final selectedMySchedule =
        mySchedules.where((s) => s.id == _selectedMySchedule?.id).firstOrNull;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Row(
                children: [
                  Icon(
                    widget.mode == CalendarDialogMode.adminAssign
                        ? Icons.edit_calendar
                        : Icons.swap_horiz,
                    color: AppColors.patrolAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.mode == CalendarDialogMode.adminAssign
                          ? 'Penugasan Jadwal Ronda RT'
                          : 'Pilih Jadwal Rekan untuk Ditukar',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Month Navigator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(_displayedMonth),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),

              // Calendar Days Grid
              _buildCalendarGrid(ronda),
              const SizedBox(height: 12),

              // Selected Date Summary Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMM yyyy', 'id_ID')
                          .format(_selectedDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '${schedulesForDay.where((s) => !s.isLibur).length} Petugas Piket',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Content Area by Mode
              Expanded(
                child: widget.mode == CalendarDialogMode.adminAssign
                    ? _buildAdminAssignSection(
                        context, ronda, officers, schedulesForDay)
                    : _buildOfficerSwapSection(context, ronda, mySchedules,
                        schedulesForDay, selectedMySchedule),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(RondaProvider ronda) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstDayOfWeek =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1)
            .weekday; // 1 = Monday
    final totalCells = ((daysInMonth + firstDayOfWeek - 1) / 7).ceil() * 7;

    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays
              .map((d) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayOffset = index - (firstDayOfWeek - 1);
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              return const SizedBox();
            }

            final day = dayOffset + 1;
            final date =
                DateTime(_displayedMonth.year, _displayedMonth.month, day);
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;

            final now = DateTime.now();
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            // Jumlah petugas piket di hari ini
            final scheds = ronda
                .getSchedulesForDate(date)
                .where((s) => !s.isLibur)
                .toList();
            final hasEligibleSwap = scheds.any((s) => now
                .isBefore(s.startDateTime.subtract(const Duration(hours: 3))));
            final hasPiket = widget.mode == CalendarDialogMode.officerSwap
                ? hasEligibleSwap
                : scheds.isNotEmpty;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.mode == CalendarDialogMode.officerSwap &&
                      !hasEligibleSwap
                  ? null
                  : () => setState(() {
                        _selectedDate = date;
                        _selectedColleagueSchedule = null;
                      }),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : (isToday
                          ? AppColors.secondaryContainer.withValues(alpha: 0.5)
                          : null),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : (isToday
                            ? AppColors.secondary
                            : Colors.grey.shade300),
                    width: isSelected || isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isToday ? AppColors.secondary : null),
                      ),
                    ),
                    if (hasPiket)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amberAccent
                                  : AppColors.patrolAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (scheds.length > 1) ...[
                            const SizedBox(width: 2),
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.lightGreenAccent
                                    : AppColors.verified,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Section Mode Admin: Penugasan Jadwal Manual & Roster View
  Widget _buildAdminAssignSection(
    BuildContext context,
    RondaProvider ronda,
    List<RondaUser> officers,
    List<PatrolSchedule> schedulesForDay,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Petugas Piket pada Hari Ini:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (schedulesForDay.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Belum ada petugas terjadwal pada hari ini.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            )
          else
            ...schedulesForDay.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: s.isLibur ? Colors.grey.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        s.isLibur ? Colors.grey.shade300 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.isLibur ? Icons.hotel : Icons.security,
                      size: 16,
                      color: s.isLibur ? Colors.grey : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.petugasName} - ${s.shiftName}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      s.isLibur ? 'Libur' : '${s.jamMulai} - ${s.jamSelesai}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: s.isLibur ? Colors.grey : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            'Formulir Penugasan Petugas:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          // Pilih Petugas
          DropdownButtonFormField<String>(
            initialValue: _selectedOfficerId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Pilih Petugas',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: officers
                .map((o) => DropdownMenuItem(
                    value: o.id,
                    child: Text(o.namaLengkap,
                        style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedOfficerId = val);
            },
          ),
          const SizedBox(height: 8),
          // Pilih Preset Shift
          DropdownButtonFormField<String>(
            initialValue: _selectedShiftName,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Shift Ronda',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: _shiftPresets
                .map((p) => DropdownMenuItem(
                      value: p['name'],
                      child: Text(p['name']!,
                          style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
            onChanged: _isLibur
                ? null
                : (val) {
                    if (val != null) {
                      final preset =
                          _shiftPresets.firstWhere((p) => p['name'] == val);
                      setState(() {
                        _selectedShiftName = val;
                        _jamMulai = preset['start']!;
                        _jamSelesai = preset['end']!;
                      });
                    }
                  },
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Tetapkan Hari Libur / Istirahat',
                style: TextStyle(fontSize: 12)),
            value: _isLibur,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _isLibur = val;
                if (_isLibur) {
                  _selectedShiftName = 'Libur Piket (Hari Istirahat)';
                  _jamMulai = '-';
                  _jamSelesai = '-';
                } else {
                  _selectedShiftName = _shiftPresets.first['name']!;
                  _jamMulai = _shiftPresets.first['start']!;
                  _jamSelesai = _shiftPresets.first['end']!;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight),
              onPressed: _isSubmittingSwap
                  ? null
                  : () async {
                      if (_selectedOfficerId == null) return;
                      ronda.assignScheduleManual(
                        userId: _selectedOfficerId!,
                        date: _selectedDate,
                        shiftName: _selectedShiftName,
                        jamMulai: _jamMulai,
                        jamSelesai: _jamSelesai,
                        isLibur: _isLibur,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Jadwal berhasil ditugaskan!')),
                      );
                    },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Simpan Penugasan Jadwal',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // Section Mode Petugas: Memilih Jadwal Rekan & Mengajukan Tukar
  Widget _buildOfficerSwapSection(
    BuildContext context,
    RondaProvider ronda,
    List<PatrolSchedule> mySchedules,
    List<PatrolSchedule> schedulesForDay,
    PatrolSchedule? selectedMySchedule,
  ) {
    final currentUser = ronda.currentUser;
    final colleagueSchedulesOnDay = schedulesForDay
        .where((s) =>
            s.userId != currentUser?.id &&
            !s.isLibur &&
            DateTime.now()
                .isBefore(s.startDateTime.subtract(const Duration(hours: 3))))
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pilih Jadwal Saya yang Ingin Ditukar
          const Text(
            '1. Pilih Jadwal Anda yang Hendak Ditukar:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (mySchedules.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text(
                  'Anda tidak memiliki jadwal dinas mendatang untuk ditukar.',
                  style: TextStyle(fontSize: 11)),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedMySchedule?.id ?? mySchedules.first.id,
              isExpanded: true,
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
              items: mySchedules
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${DateFormat("dd/MM").format(s.tanggalRonda)}: ${s.shiftName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedMySchedule =
                        mySchedules.firstWhere((s) => s.id == val);
                  });
                }
              },
            ),
          const SizedBox(height: 12),

          // 2. Pilih Jadwal Rekan pada Tanggal Terpilih di Kalender
          const Text(
            '2. Pilih Jadwal Rekan di Tanggal Kalender Ini:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (colleagueSchedulesOnDay.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text(
                  'Tidak ada rekan yang bertugas pada tanggal ini.',
                  style: TextStyle(fontSize: 11)),
            )
          else
            ...colleagueSchedulesOnDay.map((s) {
              final isChosen = _selectedColleagueSchedule?.id == s.id;
              return InkWell(
                onTap: () => setState(() => _selectedColleagueSchedule = s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isChosen
                        ? AppColors.patrolAccentLight
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isChosen
                          ? AppColors.patrolAccent
                          : Colors.grey.shade300,
                      width: isChosen ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChosen
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isChosen ? AppColors.patrolAccent : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s.petugasName} (${s.shiftName})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isChosen ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 10),

          // 3. Alasan Pertukaran
          const Text('3. Alasan Pertukaran:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _swapReasonController,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Contoh: Ada acara keluarga mendadak...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Tombol Ajukan
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight),
              onPressed: _isSubmittingSwap
                  ? null
                  : () async {
                      final mySched =
                          selectedMySchedule ?? mySchedules.firstOrNull;
                      final targetSched = _selectedColleagueSchedule;
                      final reason = _swapReasonController.text.trim();

                      if (mySched == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Pilih jadwal Anda terlebih dahulu!')),
                        );
                        return;
                      }
                      if (targetSched == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Pilih jadwal rekan yang ingin Anda tukar dari kalender!')),
                        );
                        return;
                      }
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Tuliskan alasan permohonan pertukaran jadwal!')),
                        );
                        return;
                      }

                      setState(() => _isSubmittingSwap = true);
                      final sent = await ronda.requestShiftSwap(
                        scheduleId: mySched.id,
                        targetUserId: targetSched.userId,
                        alasan: reason,
                        requesterShift: mySched.shiftName,
                        targetDate: targetSched.tanggalRonda,
                        targetShift: targetSched.shiftName,
                      );

                      if (!context.mounted) return;
                      if (!sent) {
                        setState(() => _isSubmittingSwap = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ronda.lastErrorMessage ??
                                'Permintaan gagal dikirim. Coba lagi setelah koneksi tersedia.'),
                            backgroundColor: AppColors.emergency,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Permintaan tukar jadwal terkirim ke ${targetSched.petugasName}! Menunggu persetujuan rekan.',
                          ),
                          backgroundColor: AppColors.verified,
                        ),
                      );
                    },
              icon: const Icon(Icons.send, size: 16),
              label: _isSubmittingSwap
                  ? const Text('Mengirim...')
                  : const Text('Kirim Pengajuan Tukar',
                      style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
