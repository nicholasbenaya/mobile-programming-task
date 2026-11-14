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

  /// Respon dari warga pengganti yang ditargetkan (Setuju / Tolak)
  static void respondByTargetUser({
    required ShiftSwapRequest request,
    required String respondingUserId,
    required bool isAccepted,
  }) {
    if (request.targetUserId != respondingUserId) {
      throw StateError('Hanya pengguna yang ditunjuk yang berhak merespon pertukaran ini.');
    }

    if (request.status != ShiftSwapStatus.pending) {
      throw StateError('Permintaan tukar jadwal ini sudah tidak dalam status pending (${request.status.name}).');
    }

    request.status = isAccepted ? ShiftSwapStatus.acceptedByTarget : ShiftSwapStatus.rejected;
  }

  /// Persetujuan final oleh Ketua RT (Admin) yang memutasi jadwal resmi
  static void approveByAdmin({
    required ShiftSwapRequest request,
    required PatrolSchedule schedule,
    required UserRole approverRole,
    required bool isApproved,
  }) {
    if (approverRole != UserRole.adminRt) {
      throw StateError('Hanya Ketua RT (Admin) yang memiliki wewenang mengesahkan pertukaran jadwal.');
    }

    if (request.status != ShiftSwapStatus.acceptedByTarget) {
      throw StateError('Pertukaran hanya bisa disahkan admin jika sudah disetujui oleh calon pengganti.');
    }

    if (schedule.id != request.scheduleId) {
      throw ArgumentError('ID Jadwal tidak cocok dengan data permintaan tukar.');
    }

    if (isApproved) {
      request.status = ShiftSwapStatus.approvedByAdmin;
      // Mutasi jadwal resmi ke petugas baru
      schedule.userId = request.targetUserId;
      schedule.petugasName = request.targetUserName;
    } else {
      request.status = ShiftSwapStatus.rejected;
    }
  }
}
