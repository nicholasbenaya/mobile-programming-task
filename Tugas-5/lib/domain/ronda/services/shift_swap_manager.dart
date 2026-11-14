import '../models/ronda_models.dart';

/// Mesin State Machine Pengelolaan Pertukaran Jadwal Ronda (Shift Swap)
class ShiftSwapManager {
  const ShiftSwapManager._();

  /// Membuat permintaan pertukaran jadwal baru
  static ShiftSwapRequest createRequest({
    required String requestId,
    required PatrolSchedule schedule,
    required RondaUser requester,
    required RondaUser targetUser,
    required String alasan,
    String? requesterShift,
    DateTime? targetDate,
    String? targetShift,
    DateTime? createdAt,
  }) {
    if (requester.id == targetUser.id) {
      throw ArgumentError('Tidak dapat menukar jadwal dengan diri sendiri.');
    }

    if (schedule.userId != requester.id) {
      throw StateError('Hanya petugas yang terjadwal yang dapat mengajukan pertukaran shift ini.');
    }

    if (schedule.isCompleted) {
      throw StateError('Tidak dapat menukar jadwal yang sudah selesai dilaksanakan.');
    }

    return ShiftSwapRequest(
      id: requestId,
      scheduleId: schedule.id,
      requesterId: requester.id,
      requesterName: requester.namaLengkap,
      targetUserId: targetUser.id,
      targetUserName: targetUser.namaLengkap,
      alasan: alasan,
      requesterShift: requesterShift ?? schedule.shiftName,
      targetDate: targetDate ?? schedule.tanggalRonda,
      targetShift: targetShift ?? 'Shift Malam',
      status: ShiftSwapStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Respon dari rekan petugas pengganti yang ditargetkan (Setuju / Tolak)
  /// Ketika disetujui, jadwal langsung berpindah secara resmi (Peer-to-Peer Consent)
  /// tanpa perlu birokrasi approval Ketua RT, namun riwayat dicatat di log Ketua RT.
  static void respondByTargetUser({
    required ShiftSwapRequest request,
    required String respondingUserId,
    required bool isAccepted,
    PatrolSchedule? schedule,
    PatrolSchedule? targetSchedule,
  }) {
    if (request.targetUserId != respondingUserId) {
      throw StateError('Hanya pengguna yang ditunjuk yang berhak merespon pertukaran ini.');
    }

    if (request.status != ShiftSwapStatus.pending) {
      throw StateError('Permintaan tukar jadwal ini sudah tidak dalam status pending (${request.status.name}).');
    }

    if (isAccepted) {
      request.status = ShiftSwapStatus.acceptedByTarget;
      // Mutasi jadwal langsung aktif ke petugas pengganti
      if (schedule != null) {
        schedule.userId = request.targetUserId;
        schedule.petugasName = request.targetUserName;
      }
      if (targetSchedule != null) {
        targetSchedule.userId = request.requesterId;
        targetSchedule.petugasName = request.requesterName;
      }
    } else {
      request.status = ShiftSwapStatus.rejected;
    }
  }

  /// Override opsional persetujuan Ketua RT (jika ada sengketa administratif)
  static void approveByAdmin({
    required ShiftSwapRequest request,
    required PatrolSchedule schedule,
    required UserRole approverRole,
    required bool isApproved,
  }) {
    if (approverRole != UserRole.adminRt) {
      throw StateError('Hanya Ketua RT (Admin) yang memiliki wewenang mengesahkan pertukaran jadwal.');
    }

    if (schedule.id != request.scheduleId) {
      throw ArgumentError('ID Jadwal tidak cocok dengan data permintaan tukar.');
    }

    if (isApproved) {
      request.status = ShiftSwapStatus.approvedByAdmin;
      schedule.userId = request.targetUserId;
      schedule.petugasName = request.targetUserName;
    } else {
      request.status = ShiftSwapStatus.rejected;
    }
  }
}
