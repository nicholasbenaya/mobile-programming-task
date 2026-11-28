import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/schedule.dart';

/// Specific violation codes returned by [ShiftCollisionRules.validateSwapRequest].
enum ShiftSwapViolation {
  sameOfficer,
  notScheduleOwner,
  crossSiteSchedule,
  existingPendingSwap,
  pastExpiryWindow,
  targetOfficerCollision,
  requesterReciprocalCollision,
  invalidTargetSchedule,
}

/// Outcome of validating a shift swap before submitting or accepting it.
class ShiftSwapValidationResult {
  const ShiftSwapValidationResult({
    required this.isValid,
    this.violation,
    this.message,
  });

  const ShiftSwapValidationResult.valid()
      : isValid = true,
        violation = null,
        message = null;

  final bool isValid;
  final ShiftSwapViolation? violation;
  final String? message;
}

/// Pure-Dart schedule collision and peer swap rules mirroring `0004_schedule_swap_handover.sql`.
abstract final class ShiftCollisionRules {
  static const Duration swapExpiryLeadTime = Duration(hours: 3);

  /// Half-open interval overlap check: adjacent shifts (`endA == startB`) do not collide.
  static bool intervalsOverlap({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    final aStart = startA.toUtc();
    final aEnd = endA.toUtc();
    final bStart = startB.toUtc();
    final bEnd = endB.toUtc();
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  /// Returns true if [officerId] already has an active overlapping shift in [siteId].
  static bool hasOfficerCollision({
    required String siteId,
    required String officerId,
    required DateTime startsAt,
    required DateTime endsAt,
    required Iterable<PatrolSchedule> existingSchedules,
    Set<String> ignoreScheduleIds = const <String>{},
  }) {
    for (final existing in existingSchedules) {
      if (existing.siteId != siteId || existing.officerId != officerId) {
        continue;
      }
      if (!existing.status.countsForCollision) {
        continue;
      }
      if (ignoreScheduleIds.contains(existing.id)) {
        continue;
      }
      if (intervalsOverlap(
        startA: startsAt,
        endA: endsAt,
        startB: existing.startsAt,
        endB: existing.endsAt,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Swap requests expire automatically 3 hours before the shift starts.
  static DateTime computeSwapExpiresAt(DateTime shiftStartsAt) {
    return shiftStartsAt.toUtc().subtract(swapExpiryLeadTime);
  }

  static bool isSwapExpired({
    required DateTime expiresAt,
    required DateTime now,
  }) {
    return !now.toUtc().isBefore(expiresAt.toUtc());
  }

  /// Enforces max 1 active `pending` swap per shift assignment.
  static bool hasPendingSwapForSchedule({
    required String scheduleId,
    required Iterable<ShiftSwap> existingSwaps,
  }) {
    return existingSwaps.any(
      (swap) => swap.scheduleId == scheduleId && swap.status == SwapStatus.pending,
    );
  }

  /// Validates ownership, single-pending constraint, 3-hour deadline, and collision safety.
  static ShiftSwapValidationResult validateSwapRequest({
    required PatrolSchedule sourceSchedule,
    required String requesterId,
    required String targetOfficerId,
    required DateTime now,
    required Iterable<PatrolSchedule> siteSchedules,
    required Iterable<ShiftSwap> existingSwaps,
    PatrolSchedule? targetSchedule,
  }) {
    if (requesterId == targetOfficerId) {
      return const ShiftSwapValidationResult(
        isValid: false,
        violation: ShiftSwapViolation.sameOfficer,
        message: 'Tidak dapat menukar shift dengan diri sendiri.',
      );
    }

    if (sourceSchedule.officerId != requesterId) {
      return const ShiftSwapValidationResult(
        isValid: false,
        violation: ShiftSwapViolation.notScheduleOwner,
        message: 'Anda hanya dapat mengajukan tukar shift untuk jadwal milik sendiri.',
      );
    }

    if (hasPendingSwapForSchedule(
      scheduleId: sourceSchedule.id,
      existingSwaps: existingSwaps,
    )) {
      return const ShiftSwapValidationResult(
        isValid: false,
        violation: ShiftSwapViolation.existingPendingSwap,
        message: 'Shift ini sudah memiliki permintaan tukar yang menunggu persetujuan.',
      );
    }

    final expiresAt = computeSwapExpiresAt(sourceSchedule.startsAt);
    if (isSwapExpired(expiresAt: expiresAt, now: now)) {
      return const ShiftSwapValidationResult(
        isValid: false,
        violation: ShiftSwapViolation.pastExpiryWindow,
        message: 'Tukar shift hanya dapat dilakukan minimal 3 jam sebelum shift dimulai.',
      );
    }

    if (targetSchedule != null) {
      if (targetSchedule.siteId != sourceSchedule.siteId) {
        return const ShiftSwapValidationResult(
          isValid: false,
          violation: ShiftSwapViolation.crossSiteSchedule,
          message: 'Jadwal balasan harus berasal dari wilayah yang sama.',
        );
      }
      if (targetSchedule.officerId != targetOfficerId ||
          targetSchedule.id == sourceSchedule.id) {
        return const ShiftSwapValidationResult(
          isValid: false,
          violation: ShiftSwapViolation.invalidTargetSchedule,
          message: 'Jadwal balasan tidak dimiliki oleh petugas tujuan.',
        );
      }
    }

    final ignoredIds = <String>{
      sourceSchedule.id,
      if (targetSchedule != null) targetSchedule.id,
    };

    if (hasOfficerCollision(
      siteId: sourceSchedule.siteId,
      officerId: targetOfficerId,
      startsAt: sourceSchedule.startsAt,
      endsAt: sourceSchedule.endsAt,
      existingSchedules: siteSchedules,
      ignoreScheduleIds: ignoredIds,
    )) {
      return const ShiftSwapValidationResult(
        isValid: false,
        violation: ShiftSwapViolation.targetOfficerCollision,
        message: 'Petugas tujuan sudah memiliki jadwal bentrok pada jam shift tersebut.',
      );
    }

    if (targetSchedule != null &&
        hasOfficerCollision(
          siteId: sourceSchedule.siteId,
          officerId: requesterId,
          startsAt: targetSchedule.startsAt,
          endsAt: targetSchedule.endsAt,
          existingSchedules: siteSchedules,
          ignoreScheduleIds: ignoredIds,
        )) {
      return const ShiftSwapValidationResult(
        isValid: false,
        violation: ShiftSwapViolation.requesterReciprocalCollision,
        message: 'Anda memiliki jadwal bentrok pada jam shift balasan tersebut.',
      );
    }

    return const ShiftSwapValidationResult.valid();
  }
}
