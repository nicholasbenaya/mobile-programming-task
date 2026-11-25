import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/haversine_calculator.dart';
import 'package:ronda_digital/domain/ronda/services/qr_token_verifier.dart';
import 'package:ronda_digital/domain/ronda/services/shift_swap_manager.dart';
import 'package:ronda_digital/domain/ronda/services/sos_event_dispatcher.dart';
import 'seed_data.dart';

/// Server Backend Mock yang Mengemulasi API Node.js + Express + TypeScript + Prisma
class MockBackend {
  MockBackend({DateTime? baseDate}) {
    _users.addAll(SeedData.allUsers);
    _checkpoints.addAll(SeedData.checkpoints);
    _schedules.addAll(SeedData.initialSchedules(baseDate ?? DateTime.now()));
  }

  final List<RondaUser> _users = [];
  final List<Checkpoint> _checkpoints = [];
  final List<PatrolSchedule> _schedules = [];
  final List<ShiftSwapRequest> _shiftSwaps = [];
  final List<PatrolCheckin> _patrolLogs = [];
  final List<IncidentReport> _incidents = [];
  final List<EmergencyEvent> _emergencyEvents = [];

  final List<RondaNotification> _notifications = [];

  final Map<String, int> _failedLoginAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  final SosEventDispatcher _sosDispatcher =
      SosEventDispatcher(debounceWindowSeconds: 15);
  final List<FcmEmergencyPayload> fcmBroadcastHistory = [];

  List<RondaNotification> get notifications =>
      List.unmodifiable(_notifications);

  /// Cek apakah petugas sedang memiliki jadwal ronda aktif pada tanggal bersangkutan
  bool isPetugasOnDuty(String userId, [DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return _schedules.any((s) =>
        s.userId == userId &&
        !s.isLibur &&
        s.tanggalRonda.year == now.year &&
        s.tanggalRonda.month == now.month &&
        s.tanggalRonda.day == now.day);
  }

  // 1. Auth Endpoint: POST /api/auth/login (Terenkripsi SHA-256 + Rate Limiting)
  RondaUser login(
      {required String whatsapp,
      required String password,
      DateTime? currentTime}) {
    final cleanPhone = whatsapp.trim().replaceAll(' ', '').replaceAll('-', '');
    final now = currentTime ?? DateTime.now();

    // Proteksi brute force: Cek status lockout sementara
    final lockout = _lockoutUntil[cleanPhone];
    if (lockout != null && now.isBefore(lockout)) {
      final sisaMenit = lockout.difference(now).inMinutes + 1;
      throw StateError(
        'Akun terkunci sementara karena 5 kali percobaan salah berturut-turut (ERR_AUTH_LOCKOUT). Coba lagi dalam $sisaMenit menit.',
      );
    }

    final user = _users.firstWhere(
      (u) =>
          u.nomorWhatsapp.replaceAll(' ', '').replaceAll('-', '') == cleanPhone,
      orElse: () => throw StateError(
          'Nomor WhatsApp $whatsapp tidak terdaftar di sistem siskamling RT.'),
    );

    if (!user.verifyPassword(password)) {
      final attempts = (_failedLoginAttempts[cleanPhone] ?? 0) + 1;
      _failedLoginAttempts[cleanPhone] = attempts;
      if (attempts >= 5) {
        _lockoutUntil[cleanPhone] = now.add(const Duration(minutes: 15));
        throw StateError(
          'Batas 5 kali percobaan salah tercapai. Akun Anda dikunci sementara selama 15 menit (ERR_AUTH_LOCKOUT).',
        );
      }
      throw StateError(
          'Kata sandi yang Anda masukkan salah. Percobaan gagal: $attempts/5.');
    }

    // Reset counter setelah login berhasil
    _failedLoginAttempts.remove(cleanPhone);
    _lockoutUntil.remove(cleanPhone);

    return user;
  }

  RondaUser loginByWhatsapp(String whatsapp) {
    return login(whatsapp: whatsapp, password: SeedData.defaultDemoPassword);
  }

  // 2. Checkpoints Endpoint: GET /api/checkpoints
  List<Checkpoint> getCheckpoints(String rtId) {
    return _checkpoints.where((c) => c.rtId == rtId).toList();
  }

  // 3. Patrol Check-in Endpoint: POST /api/patrol/checkin
  PatrolCheckin submitCheckin({
    required String checkinId,
    required String checkpointId,
    required String userId,
    required String qrPayload,
    required double userLat,
    required double userLon,
    double? accuracy,
    double? batteryLevel,
    DateTime? scanTime,
    bool forceDutyOverride = false,
  }) {
    final now = scanTime ?? DateTime.now();

    // 1. Validasi Jadwal Shift Petugas Individual
    // Petugas HANYA dapat check-in jika terjadwal dinas pada hari ini & waktu scan berada dalam shiftnya
    if (!forceDutyOverride) {
      final userSched = _schedules.cast<PatrolSchedule?>().firstWhere(
            (s) =>
                s != null &&
                s.userId == userId &&
                !s.isLibur &&
                s.tanggalRonda.year == now.year &&
                s.tanggalRonda.month == now.month &&
                s.tanggalRonda.day == now.day,
            orElse: () => null,
          );

      if (userSched == null) {
        throw StateError(
          'Akses Ditolak: Anda tidak memiliki jadwal dinas aktif pada tanggal ini (atau berstatus libur).',
        );
      }

      if (!userSched.isTimeInShift(now)) {
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        throw StateError(
          'Akses Ditolak: Waktu scan ($timeStr WIB) berada di luar jam dinas Anda '
          '(${userSched.shiftName}: ${userSched.jamMulai} - ${userSched.jamSelesai} WIB). '
          'Setiap petugas wajib check-in sesuai jadwal shift masing-masing.',
        );
      }
    }

    final checkpoint = _checkpoints.firstWhere(
      (c) => c.id == checkpointId,
      orElse: () =>
          throw ArgumentError('Checkpoint $checkpointId tidak terdaftar.'),
    );

    // Verifikasi Token QR Bertanda Waktu
    final qrResult = QrTokenVerifier.verifyPayload(
      payload: qrPayload,
      expectedCheckpointId: checkpointId,
      secretKey: checkpoint.secretKey,
      currentTime: now,
    );

    if (!qrResult.isValid) {
      throw StateError('Validasi QR Gagal: ${qrResult.rejectionReason}');
    }

    // Verifikasi Geofence Radius GPS (Haversine)
    final geofenceResult = HaversineCalculator.verifyGeofence(
      userLat: userLat,
      userLon: userLon,
      targetLat: checkpoint.latitude,
      targetLon: checkpoint.longitude,
      radiusMeters: checkpoint.radiusMeter,
      accuracyMeters: accuracy,
    );

    if (!geofenceResult.isValid) {
      throw StateError(
          'Validasi Geofence Gagal: ${geofenceResult.rejectionReason}');
    }

    // Rekam Log Patroli
    final checkin = PatrolCheckin(
      id: checkinId,
      checkpointId: checkpointId,
      userId: userId,
      scannedAt: now,
      latitudeUser: userLat,
      longitudeUser: userLon,
      distanceMeter: geofenceResult.distanceMeters,
      accuracy: accuracy,
      batteryLevel: batteryLevel,
      syncStatus: SyncStatus.synced,
    );

    _patrolLogs.insert(0, checkin);
    return checkin;
  }

  // 4. Jadwal & Shift Swap Endpoints
  List<PatrolSchedule> getSchedules(String rtId) =>
      _schedules.where((s) => s.rtId == rtId).toList();

  /// Menugaskan jadwal secara manual oleh Ketua RT
  PatrolSchedule assignScheduleManual({
    required String rtId,
    required String userId,
    required DateTime date,
    required String shiftName,
    required String jamMulai,
    required String jamSelesai,
    bool isLibur = false,
  }) {
    final user = _users.firstWhere((u) => u.id == userId);
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Hapus jadwal eksisting petugas di tanggal tersebut jika ada
    _schedules.removeWhere((s) =>
        s.userId == userId &&
        s.tanggalRonda.year == normalizedDate.year &&
        s.tanggalRonda.month == normalizedDate.month &&
        s.tanggalRonda.day == normalizedDate.day);

    final newSched = PatrolSchedule(
      id: 'SCHED-${userId.toUpperCase()}-${normalizedDate.millisecondsSinceEpoch}',
      rtId: rtId,
      userId: userId,
      petugasName: user.namaLengkap,
      tanggalRonda: normalizedDate,
      shiftName: shiftName,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      isLibur: isLibur,
    );

    _schedules.add(newSched);
    _schedules.sort((a, b) => a.tanggalRonda.compareTo(b.tanggalRonda));

    // Kirim notifikasi pembaruan jadwal
    _notifications.insert(
      0,
      RondaNotification(
        id: 'notif-sched-${DateTime.now().millisecondsSinceEpoch}',
        rtId: rtId,
        title: 'Jadwal Ronda Ditetapkan',
        body:
            'Ketua RT telah menugaskan Anda (${user.namaLengkap}) pada $shiftName tanggal ${normalizedDate.day}/${normalizedDate.month}/${normalizedDate.year}.',
        type: RondaNotificationType.scheduleUpdate,
        targetUserId: userId,
        createdAt: DateTime.now(),
      ),
    );

    return newSched;
  }

  /// Generator Otomatis Jadwal Ronda (Aturan: 5 Hari Ronda + 1 Hari Libur per Petugas)
  List<PatrolSchedule> generateAutoRoster({
    required String rtId,
    DateTime? startDate,
    int daysCount = 30,
  }) {
    final officers = _users
        .where((u) => u.rtId == rtId && u.role == UserRole.petugasRonda)
        .toList();
    if (officers.isEmpty) {
      throw StateError('Tidak ada petugas ronda terdaftar di RT ini.');
    }

    final start = startDate ?? DateTime.now();
    final normalizedStart = DateTime(start.year, start.month, start.day);

    // Hapus jadwal mendatang mulai tanggal start
    _schedules.removeWhere(
        (s) => s.rtId == rtId && !s.tanggalRonda.isBefore(normalizedStart));

    final generated = <PatrolSchedule>[];
    const shifts = [
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

    // Pola 5 hari ronda + 1 hari libur (siklus 6 hari)
    // Berikan stagger offset pada setiap petugas agar libur tidak bersamaan
    for (int dayIndex = 0; dayIndex < daysCount; dayIndex++) {
      final targetDate = normalizedStart.add(Duration(days: dayIndex));

      int activeShiftIndex = 0;
      for (int officerIdx = 0; officerIdx < officers.length; officerIdx++) {
        final officer = officers[officerIdx];
        // Siklus 6 hari: 0,1,2,3,4 = Ronda, 5 = Libur
        final cycleDay = (dayIndex + officerIdx * 2) % 6;
        final isLibur = cycleDay == 5;

        final shiftInfo = isLibur
            ? {'name': 'Libur Piket (Hari Istirahat)', 'start': '-', 'end': '-'}
            : shifts[activeShiftIndex % shifts.length];

        if (!isLibur) {
          activeShiftIndex++;
        }

        final sched = PatrolSchedule(
          id: 'AUTO-${officer.id}-$dayIndex-${targetDate.millisecondsSinceEpoch}',
          rtId: rtId,
          userId: officer.id,
          petugasName: officer.namaLengkap,
          tanggalRonda: targetDate,
          shiftName: shiftInfo['name']!,
          jamMulai: shiftInfo['start']!,
          jamSelesai: shiftInfo['end']!,
          isLibur: isLibur,
        );

        generated.add(sched);
        _schedules.add(sched);
      }
    }

    _schedules.sort((a, b) => a.tanggalRonda.compareTo(b.tanggalRonda));

    // Catat notifikasi pengumuman jadwal umum
    _notifications.insert(
      0,
      RondaNotification(
        id: 'notif-auto-roster-${DateTime.now().millisecondsSinceEpoch}',
        rtId: rtId,
        title: 'Jadwal Ronda Otomatis Disusun',
        body:
            'Jadwal ronda bergilir 5 hari dinas + 1 hari libur untuk $daysCount hari ke depan telah disahkan oleh Ketua RT.',
        type: RondaNotificationType.scheduleUpdate,
        includeOffDuty: true,
        createdAt: DateTime.now(),
      ),
    );

    return generated;
  }

  ShiftSwapRequest requestShiftSwap({
    required String requestId,
    required String scheduleId,
    required String requesterId,
    required String targetUserId,
    required String alasan,
    String? requesterShift,
    DateTime? targetDate,
    String? targetShift,
    DateTime? createdAt,
  }) {
    final schedule = _schedules.firstWhere((s) => s.id == scheduleId);
    final requester = _users.firstWhere((u) => u.id == requesterId);
    final target = _users.firstWhere((u) => u.id == targetUserId);

    final request = ShiftSwapManager.createRequest(
      requestId: requestId,
      schedule: schedule,
      requester: requester,
      targetUser: target,
      alasan: alasan,
      requesterShift: requesterShift,
      targetDate: targetDate,
      targetShift: targetShift,
      createdAt: createdAt,
      existingSwaps: _shiftSwaps,
    );

    _shiftSwaps.insert(0, request);
    return request;
  }

  void respondShiftSwap({
    required String requestId,
    required String responderId,
    required bool isAccepted,
  }) {
    final request = _shiftSwaps.firstWhere((r) => r.id == requestId);
    final schedule = _schedules.firstWhere((s) => s.id == request.scheduleId);

    // Cari jadwal targetUser jika ada targetDate untuk mutasi 2 arah
    PatrolSchedule? targetSchedule;
    if (request.targetDate != null) {
      targetSchedule = _schedules.cast<PatrolSchedule?>().firstWhere(
            (s) =>
                s != null &&
                s.userId == responderId &&
                s.tanggalRonda.year == request.targetDate!.year &&
                s.tanggalRonda.month == request.targetDate!.month &&
                s.tanggalRonda.day == request.targetDate!.day,
            orElse: () => null,
          );
    }

    ShiftSwapManager.respondByTargetUser(
      request: request,
      schedule: schedule,
      respondingUserId: responderId,
      isAccepted: isAccepted,
      targetSchedule: targetSchedule,
    );

    // Log notifikasi audit untuk Ketua RT dan para pihak
    _notifications.insert(
      0,
      RondaNotification(
        id: 'notif-swap-${DateTime.now().millisecondsSinceEpoch}',
        rtId: schedule.rtId,
        title: isAccepted
            ? 'Mutasi Jadwal: Pertukaran Disetujui'
            : 'Permintaan Tukar Ditolak',
        body: isAccepted
            ? 'Pertukaran jadwal antara ${request.requesterName} dan ${request.targetUserName} disetujui oleh rekan bersangkutan dan jadwal patroli otomatis diperbarui.'
            : '${request.targetUserName} menolak permohonan tukar jadwal dari ${request.requesterName}.',
        type: RondaNotificationType.scheduleUpdate,
        createdAt: DateTime.now(),
      ),
    );
  }

  void approveShiftSwap({
    required String requestId,
    required UserRole approverRole,
    required bool isApproved,
  }) {
    final request = _shiftSwaps.firstWhere((r) => r.id == requestId);
    final schedule = _schedules.firstWhere((s) => s.id == request.scheduleId);

    ShiftSwapManager.approveByAdmin(
      request: request,
      schedule: schedule,
      approverRole: approverRole,
      isApproved: isApproved,
    );
  }

  List<ShiftSwapRequest> get shiftSwaps => List.unmodifiable(_shiftSwaps);

  void removeShiftSwap(String requestId) {
    _shiftSwaps.removeWhere((swap) => swap.id == requestId);
  }

  // 5. Emergency SOS Endpoints (Multi-Stage Lifecycle)
  EmergencyEvent triggerPanic({
    required String eventId,
    required String userId,
    required double latitude,
    required double longitude,
    String? catatan,
    DateTime? timestamp,
  }) {
    final user = _users.firstWhere((u) => u.id == userId);
    final result = _sosDispatcher.triggerPanic(
      eventId: eventId,
      user: user,
      latitude: latitude,
      longitude: longitude,
      catatan: catatan,
      timestamp: timestamp,
    );

    _emergencyEvents.insert(0, result.event);
    fcmBroadcastHistory.add(result.fcmPayload);

    // Kirim notifikasi darurat internal
    _notifications.insert(
      0,
      RondaNotification(
        id: 'notif-sos-$eventId',
        rtId: user.rtId,
        title: 'PANGGILAN DARURAT (SOS)!',
        body:
            '${user.namaLengkap} di ${user.alamatRumah} membutuhkan bantuan segera.',
        type: RondaNotificationType.sosEmergency,
        includeOffDuty: true,
        createdAt: DateTime.now(),
      ),
    );

    return result.event;
  }

  /// Broadcast / Notifikasi Darurat Manual oleh Ketua RT
  void broadcastSosAlert({
    required String rtId,
    required String eventId,
    required bool includeOffDuty,
    String? customMessage,
  }) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    final msg = customMessage ??
        'PERINTAH KETUA RT: Segera bergerak ke lokasi insiden darurat di ${event.userAddress} (Pelapor: ${event.userName})!';

    _notifications.insert(
      0,
      RondaNotification(
        id: 'broadcast-sos-${DateTime.now().millisecondsSinceEpoch}',
        rtId: rtId,
        title: 'DARURAT SOS: Panggilan Khusus Ketua RT',
        body: msg,
        type: RondaNotificationType.sosEmergency,
        includeOffDuty: includeOffDuty,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Peringatan Check-in Pos Patroli Manual oleh Ketua RT
  void notifyCheckpointReminder({
    required String rtId,
    required String checkpointId,
    String? targetUserId,
    String? customMessage,
  }) {
    final cp = _checkpoints.firstWhere((c) => c.id == checkpointId);
    final msg = customMessage ??
        'Peringatan Ketua RT: Pos ${cp.kodeTitik} (${cp.namaLokasi}) belum dipindai sesuai jadwal (${cp.targetWaktuCheckin} WIB). Harap segera lakukan check-in patroli.';

    _notifications.insert(
      0,
      RondaNotification(
        id: 'chk-reminder-${DateTime.now().millisecondsSinceEpoch}',
        rtId: rtId,
        title: 'PERINGATAN CHECK-IN PATROLI',
        body: msg,
        type: RondaNotificationType.checkpointReminder,
        targetUserId: targetUserId,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Petugas merespons insiden (Hanya yang sedang bertugas yang diperbolehkan)
  void respondEmergency({
    required String eventId,
    required String responderId,
    bool forceDutyOverride = false,
  }) {
    if (!forceDutyOverride && !isPetugasOnDuty(responderId)) {
      throw StateError(
          'Akses Ditolak: Hanya petugas yang sedang bertugas/berpatroli aktif hari ini yang berhak merespons darurat SOS.');
    }

    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    final responder = _users.firstWhere((u) => u.id == responderId);
    _sosDispatcher.respondEmergency(event, responder: responder);
  }

  void resolveEmergencyWithQr({
    required String eventId,
    required String scannedQrPayload,
    required String responderId,
  }) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    final responder = _users.firstWhere((u) => u.id == responderId);
    _sosDispatcher.resolveEmergencyWithQr(
      event,
      scannedQrPayload: scannedQrPayload,
      responder: responder,
    );
  }

  void resolveEmergencyWithPhoto({
    required String eventId,
    required String photoPath,
    required String notes,
    required String responderId,
  }) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    final responder = _users.firstWhere((u) => u.id == responderId);
    _sosDispatcher.resolveEmergencyWithPhoto(
      event,
      photoPath: photoPath,
      notes: notes,
      responder: responder,
    );
  }

  void adminVerifyEmergency({
    required String eventId,
    required String adminId,
    required bool isApproved,
    String? adminNotes,
  }) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    final admin = _users.firstWhere((u) => u.id == adminId);
    _sosDispatcher.adminVerifyEmergency(
      event,
      admin: admin,
      isApproved: isApproved,
      adminNotes: adminNotes,
    );
  }

  void resolveEmergency(String eventId, {String? reason}) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    _sosDispatcher.resolveEmergency(event);
    if (reason != null) {
      event.resolutionNotes = reason;
    }
  }

  /// Pembatalan alarm darurat palsu (false alarm) secara mandiri oleh warga pelapor
  void cancelEmergency({
    required String eventId,
    required String userId,
    String? reason,
  }) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    if (event.userId != userId) {
      throw StateError(
          'Akses Ditolak: Hanya warga pelapor yang berhak membatalkan alarm darurat ini.');
    }
    if (event.status == EmergencyStatus.selesai) {
      throw StateError(
          'Alarm darurat ini sudah berstatus selesai dan tidak dapat dibatalkan.');
    }
    event.status = EmergencyStatus.selesai;
    event.resolvedAt = DateTime.now();
    event.resolutionNotes =
        'DIBATALKAN PELAPOR: ${reason ?? "Alarm palsu / tidak sengaja tertekan"}';
  }

  // 6. Insiden Kejadian Berfoto: POST /api/incidents
  IncidentReport reportIncident({
    required String incidentId,
    required String userId,
    required IncidentCategory category,
    required String keterangan,
    required String photoPath,
    required double latitude,
    required double longitude,
    double? compass,
  }) {
    final user = _users.firstWhere((u) => u.id == userId);
    final report = IncidentReport(
      id: incidentId,
      rtId: user.rtId,
      userId: user.id,
      reporterName: user.namaLengkap,
      category: category,
      keterangan: keterangan,
      photoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
      compass: compass,
      createdAt: DateTime.now(),
    );

    _incidents.insert(0, report);
    return report;
  }

  List<PatrolCheckin> get patrolLogs => List.unmodifiable(_patrolLogs);
  List<IncidentReport> get incidents => List.unmodifiable(_incidents);
  List<EmergencyEvent> get emergencyEvents =>
      List.unmodifiable(_emergencyEvents);
  List<EmergencyEvent> get resolvedEmergencies => _emergencyEvents
      .where((e) => e.status == EmergencyStatus.selesai)
      .toList();

  void syncEmergencies(List<EmergencyEvent> items) {
    if (items.isEmpty) return;
    final map = {for (final e in _emergencyEvents) e.id: e};
    for (final item in items) {
      map[item.id] = item;
    }
    _emergencyEvents.clear();
    _emergencyEvents.addAll(map.values);
    _emergencyEvents.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
  }

  void syncPatrolLogs(List<PatrolCheckin> items) {
    if (items.isEmpty) return;
    final map = {for (final l in _patrolLogs) l.id: l};
    for (final item in items) {
      map[item.id] = item;
    }
    _patrolLogs.clear();
    _patrolLogs.addAll(map.values);
    _patrolLogs.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }

  void syncSchedules(List<PatrolSchedule> items) {
    if (items.isEmpty) return;
    final map = {for (final s in _schedules) s.id: s};
    for (final item in items) {
      map[item.id] = item;
    }
    _schedules.clear();
    _schedules.addAll(map.values);
    _schedules.sort((a, b) => a.tanggalRonda.compareTo(b.tanggalRonda));
  }

  void syncShiftSwaps(List<ShiftSwapRequest> items) {
    if (items.isEmpty) return;
    final map = {for (final s in _shiftSwaps) s.id: s};
    for (final item in items) {
      map[item.id] = item;
    }
    _shiftSwaps.clear();
    _shiftSwaps.addAll(map.values);
    _shiftSwaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void syncNotifications(List<RondaNotification> items) {
    if (items.isEmpty) return;
    final map = {for (final n in _notifications) n.id: n};
    for (final item in items) {
      map[item.id] = item;
    }
    _notifications.clear();
    _notifications.addAll(map.values);
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void syncIncidents(List<IncidentReport> items) {
    if (items.isEmpty) return;
    final map = {for (final i in _incidents) i.id: i};
    for (final item in items) {
      map[item.id] = item;
    }
    _incidents.clear();
    _incidents.addAll(map.values);
    _incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
