import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/schedule.dart';
import 'package:ronda_app/domain/services/shift_collision_rules.dart';

void main() {
  const siteId = '11111111-1111-4111-8111-111111111111';
  const otherSiteId = '99999999-9999-4999-8999-999999999999';
  const officerA = 'aaaa1111-1111-4111-8111-111111111111';
  const officerB = 'bbbb2222-2222-4222-8222-222222222222';

  PatrolSchedule buildSchedule({
    required String id,
    required String officerId,
    required DateTime startsAt,
    required DateTime endsAt,
    String targetSiteId = siteId,
    ScheduleStatus status = ScheduleStatus.scheduled,
  }) {
    return PatrolSchedule(
      id: id,
      siteId: targetSiteId,
      officerId: officerId,
      shiftName: 'Shift Malam',
      shiftDate: DateTime.utc(startsAt.year, startsAt.month, startsAt.day),
      startsAt: startsAt,
      endsAt: endsAt,
      status: status,
      createdAt: DateTime.utc(2026, 5, 1),
    );
  }

  group('ShiftCollisionRules.intervalsOverlap & hasOfficerCollision', () {
    test('treats touching adjacent shifts as non-overlapping', () {
      final firstStart = DateTime.utc(2026, 6, 1, 7, 0);
      final firstEnd = DateTime.utc(2026, 6, 1, 15, 0);
      final secondEnd = DateTime.utc(2026, 6, 1, 23, 0);

      expect(
        ShiftCollisionRules.intervalsOverlap(
          startA: firstStart,
          endA: firstEnd,
          startB: firstEnd,
          endB: secondEnd,
        ),
        isFalse,
      );
    });

    test('detects overlapping overnight shifts and ignores absent/swapped or other sites', () {
      final overnightA = buildSchedule(
        id: 'sched-1',
        officerId: officerA,
        startsAt: DateTime.utc(2026, 6, 1, 22, 0),
        endsAt: DateTime.utc(2026, 6, 2, 6, 0),
      );
      final absentShift = buildSchedule(
        id: 'sched-2',
        officerId: officerA,
        startsAt: DateTime.utc(2026, 6, 2, 10, 0),
        endsAt: DateTime.utc(2026, 6, 2, 18, 0),
        status: ScheduleStatus.absent,
      );
      final otherSiteShift = buildSchedule(
        id: 'sched-3',
        officerId: officerA,
        targetSiteId: otherSiteId,
        startsAt: DateTime.utc(2026, 6, 3, 8, 0),
        endsAt: DateTime.utc(2026, 6, 3, 16, 0),
      );

      final schedules = [overnightA, absentShift, otherSiteShift];

      expect(
        ShiftCollisionRules.hasOfficerCollision(
          siteId: siteId,
          officerId: officerA,
          startsAt: DateTime.utc(2026, 6, 2, 4, 0),
          endsAt: DateTime.utc(2026, 6, 2, 12, 0),
          existingSchedules: schedules,
        ),
        isTrue,
      );

      expect(
        ShiftCollisionRules.hasOfficerCollision(
          siteId: siteId,
          officerId: officerA,
          startsAt: DateTime.utc(2026, 6, 2, 12, 0),
          endsAt: DateTime.utc(2026, 6, 2, 14, 0),
          existingSchedules: schedules,
        ),
        isFalse,
      );

      expect(
        ShiftCollisionRules.hasOfficerCollision(
          siteId: siteId,
          officerId: officerA,
          startsAt: DateTime.utc(2026, 6, 3, 10, 0),
          endsAt: DateTime.utc(2026, 6, 3, 12, 0),
          existingSchedules: schedules,
        ),
        isFalse,
      );
    });
  });

  group('ShiftCollisionRules.validateSwapRequest', () {
    final shiftA = buildSchedule(
      id: 'sched-a',
      officerId: officerA,
      startsAt: DateTime.utc(2026, 6, 10, 15, 0),
      endsAt: DateTime.utc(2026, 6, 10, 23, 0),
    );
    final shiftB = buildSchedule(
      id: 'sched-b',
      officerId: officerB,
      startsAt: DateTime.utc(2026, 6, 11, 15, 0),
      endsAt: DateTime.utc(2026, 6, 11, 23, 0),
    );
    final safeNow = DateTime.utc(2026, 6, 10, 11, 59); // 3h01m before shiftA

    test('accepts valid single-direction and reciprocal swaps', () {
      final single = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerB,
        now: safeNow,
        siteSchedules: [shiftA, shiftB],
        existingSwaps: const [],
      );
      expect(single.isValid, isTrue);

      final reciprocal = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerB,
        targetSchedule: shiftB,
        now: safeNow,
        siteSchedules: [shiftA, shiftB],
        existingSwaps: const [],
      );
      expect(reciprocal.isValid, isTrue);
    });

    test('enforces 3-hour pre-shift expiration boundary', () {
      final exactBoundary = ShiftCollisionRules.computeSwapExpiresAt(shiftA.startsAt);
      expect(exactBoundary, DateTime.utc(2026, 6, 10, 12, 0));

      final expired = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerB,
        now: exactBoundary,
        siteSchedules: [shiftA],
        existingSwaps: const [],
      );
      expect(expired.isValid, isFalse);
      expect(expired.violation, ShiftSwapViolation.pastExpiryWindow);
    });

    test('enforces single-pending swap rule and ownership checks', () {
      final pendingSwap = ShiftSwap(
        id: 'swap-1',
        siteId: siteId,
        scheduleId: shiftA.id,
        requesterId: officerA,
        targetOfficerId: officerB,
        reason: 'Urusan keluarga',
        status: SwapStatus.pending,
        expiresAt: ShiftCollisionRules.computeSwapExpiresAt(shiftA.startsAt),
        createdAt: DateTime.utc(2026, 6, 9),
      );

      final duplicatePending = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerB,
        now: safeNow,
        siteSchedules: [shiftA],
        existingSwaps: [pendingSwap],
      );
      expect(duplicatePending.violation, ShiftSwapViolation.existingPendingSwap);

      final selfSwap = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerA,
        now: safeNow,
        siteSchedules: [shiftA],
        existingSwaps: const [],
      );
      expect(selfSwap.violation, ShiftSwapViolation.sameOfficer);

      final wrongOwner = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerB,
        targetOfficerId: officerA,
        now: safeNow,
        siteSchedules: [shiftA],
        existingSwaps: const [],
      );
      expect(wrongOwner.violation, ShiftSwapViolation.notScheduleOwner);
    });

    test('rejects swaps that cause collisions for target officer or reciprocal requester', () {
      final conflictingTargetShift = buildSchedule(
        id: 'sched-b-conflict',
        officerId: officerB,
        startsAt: DateTime.utc(2026, 6, 10, 20, 0),
        endsAt: DateTime.utc(2026, 6, 11, 4, 0),
      );

      final targetCollision = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerB,
        now: safeNow,
        siteSchedules: [shiftA, conflictingTargetShift],
        existingSwaps: const [],
      );
      expect(targetCollision.violation, ShiftSwapViolation.targetOfficerCollision);

      final conflictingRequesterShift = buildSchedule(
        id: 'sched-a-conflict',
        officerId: officerA,
        startsAt: DateTime.utc(2026, 6, 11, 18, 0),
        endsAt: DateTime.utc(2026, 6, 12, 2, 0),
      );

      final requesterCollision = ShiftCollisionRules.validateSwapRequest(
        sourceSchedule: shiftA,
        requesterId: officerA,
        targetOfficerId: officerB,
        targetSchedule: shiftB,
        now: safeNow,
        siteSchedules: [shiftA, shiftB, conflictingRequesterShift],
        existingSwaps: const [],
      );
      expect(
        requesterCollision.violation,
        ShiftSwapViolation.requesterReciprocalCollision,
      );
    });
  });
}
