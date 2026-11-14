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

  final SosEventDispatcher _sosDispatcher = SosEventDispatcher(debounceWindowSeconds: 15);
  final List<FcmEmergencyPayload> fcmBroadcastHistory = [];

  // 1. Auth Endpoint: POST /api/auth/login
  RondaUser loginByWhatsapp(String whatsapp) {
    final user = _users.firstWhere(
      (u) => u.nomorWhatsapp == whatsapp,
      orElse: () => throw StateError('Pengguna dengan nomor $whatsapp tidak ditemukan.'),
    );
    return user;
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
  }) {
    final now = scanTime ?? DateTime.now();
    final checkpoint = _checkpoints.firstWhere(
      (c) => c.id == checkpointId,
      orElse: () => throw ArgumentError('Checkpoint $checkpointId tidak terdaftar.'),
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
      throw StateError('Validasi Geofence Gagal: ${geofenceResult.rejectionReason}');
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

    _patrolLogs.add(checkin);
    return checkin;
  }

  // 4. Jadwal & Shift Swap Endpoints
  List<PatrolSchedule> getSchedules(String rtId) =>
      _schedules.where((s) => s.rtId == rtId).toList();

  ShiftSwapRequest requestShiftSwap({
    required String requestId,
    required String scheduleId,
    required String requesterId,
    required String targetUserId,
    required String alasan,
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
    );

    _shiftSwaps.add(request);
    return request;
  }

  void respondShiftSwap({
    required String requestId,
    required String responderId,
    required bool isAccepted,
  }) {
    final request = _shiftSwaps.firstWhere((r) => r.id == requestId);
    ShiftSwapManager.respondByTargetUser(
      request: request,
      respondingUserId: responderId,
      isAccepted: isAccepted,
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

  // 5. Emergency SOS Endpoint: POST /api/emergency/panic
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

    _emergencyEvents.add(result.event);
    fcmBroadcastHistory.add(result.fcmPayload);
    return result.event;
  }

  void resolveEmergency(String eventId) {
    final event = _emergencyEvents.firstWhere((e) => e.id == eventId);
    _sosDispatcher.resolveEmergency(event);
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

    _incidents.add(report);
    return report;
  }

  List<PatrolCheckin> get patrolLogs => List.unmodifiable(_patrolLogs);
  List<IncidentReport> get incidents => List.unmodifiable(_incidents);
  List<EmergencyEvent> get emergencyEvents => List.unmodifiable(_emergencyEvents);
}
