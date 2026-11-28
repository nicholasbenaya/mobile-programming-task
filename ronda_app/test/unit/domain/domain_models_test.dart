import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/domain/models/models.dart';

void main() {
  group('Domain enums serialization', () {
    test('roundtrips every enum value and throws FormatException on unknown strings', () {
      for (final value in SiteType.values) {
        expect(SiteType.fromValue(value.value), value);
      }
      for (final value in SiteRole.values) {
        expect(SiteRole.fromValue(value.value), value);
      }
      for (final value in MembershipStatus.values) {
        expect(MembershipStatus.fromValue(value.value), value);
      }
      for (final value in ScheduleStatus.values) {
        expect(ScheduleStatus.fromValue(value.value), value);
      }
      for (final value in SwapStatus.values) {
        expect(SwapStatus.fromValue(value.value), value);
      }
      for (final value in AutoVerificationStatus.values) {
        expect(AutoVerificationStatus.fromValue(value.value), value);
      }
      for (final value in ManualReviewStatus.values) {
        expect(ManualReviewStatus.fromValue(value.value), value);
      }
      for (final value in EffectiveCheckinStatus.values) {
        expect(EffectiveCheckinStatus.fromValue(value.value), value);
      }
      for (final value in CheckinFlagReason.values) {
        expect(CheckinFlagReason.fromValue(value.value), value);
      }
      for (final value in AuditAction.values) {
        expect(AuditAction.fromValue(value.value), value);
      }
      for (final value in SosCategory.values) {
        expect(SosCategory.fromValue(value.value), value);
      }
      for (final value in SosStatus.values) {
        expect(SosStatus.fromValue(value.value), value);
      }
      for (final value in IncidentCategory.values) {
        expect(IncidentCategory.fromValue(value.value), value);
      }
      for (final value in IncidentStatus.values) {
        expect(IncidentStatus.fromValue(value.value), value);
      }
      for (final value in EmptyHouseStatus.values) {
        expect(EmptyHouseStatus.fromValue(value.value), value);
      }
      for (final value in DevicePlatform.values) {
        expect(DevicePlatform.fromValue(value.value), value);
      }
      for (final value in OfflineSyncState.values) {
        expect(OfflineSyncState.fromValue(value.value), value);
      }

      expect(() => SiteRole.fromValue('superadmin'), throwsFormatException);
      expect(() => CheckinFlagReason.fromValue('UNKNOWN_RULE'), throwsFormatException);
    });
  });

  group('Domain model helpers', () {
    test('EffectiveCheckinStatus.resolve prioritizes manual override over autoStatus', () {
      expect(
        EffectiveCheckinStatus.resolve(
          autoStatus: AutoVerificationStatus.autoRejected,
          manualStatus: ManualReviewStatus.manualApproved,
        ),
        EffectiveCheckinStatus.manualApproved,
      );
      expect(
        EffectiveCheckinStatus.resolve(
          autoStatus: AutoVerificationStatus.autoVerified,
          manualStatus: ManualReviewStatus.manualRejected,
        ),
        EffectiveCheckinStatus.manualRejected,
      );
      expect(
        EffectiveCheckinStatus.resolve(
          autoStatus: AutoVerificationStatus.flaggedReview,
        ),
        EffectiveCheckinStatus.flaggedReview,
      );
    });

    test('EmptyHouseWatch.isActiveOnDate enforces inclusive date window and active status', () {
      final watch = EmptyHouseWatch(
        id: 'watch-1',
        siteId: 'site-1',
        residentId: 'res-1',
        houseLabel: 'Blok B-12',
        latitude: -7.25,
        longitude: 112.75,
        startDate: DateTime.utc(2026, 4, 1),
        endDate: DateTime.utc(2026, 4, 5),
        emergencyContact: '08123456789',
        notes: 'Lampu teras menyala otomatis',
        status: EmptyHouseStatus.active,
        createdAt: DateTime.utc(2026, 3, 30),
      );

      expect(watch.isActiveOnDate(DateTime.utc(2026, 3, 31)), isFalse);
      expect(watch.isActiveOnDate(DateTime.utc(2026, 4, 1)), isTrue);
      expect(watch.isActiveOnDate(DateTime.utc(2026, 4, 5)), isTrue);
      expect(watch.isActiveOnDate(DateTime.utc(2026, 4, 6)), isFalse);

      final returned = EmptyHouseWatch(
        id: 'watch-2',
        siteId: 'site-1',
        residentId: 'res-1',
        houseLabel: 'Blok B-12',
        latitude: -7.25,
        longitude: 112.75,
        startDate: DateTime.utc(2026, 4, 1),
        endDate: DateTime.utc(2026, 4, 5),
        emergencyContact: '08123456789',
        notes: '',
        status: EmptyHouseStatus.returned,
        createdAt: DateTime.utc(2026, 3, 30),
      );
      expect(returned.isActiveOnDate(DateTime.utc(2026, 4, 2)), isFalse);
    });

    test('MonthlyComplianceSummary returns null completion rate when no shifts exist', () {
      const empty = MonthlyComplianceSummary(
        siteId: 'site-1',
        year: 2026,
        month: 6,
        totalScheduledShifts: 0,
        completedShifts: 0,
        totalCheckins: 0,
        verifiedCheckins: 0,
        flaggedCheckins: 0,
        rejectedCheckins: 0,
        manualApprovedOverrides: 0,
        manualRejectedOverrides: 0,
        openIncidentReports: 0,
        resolvedIncidentReports: 0,
        totalSosEvents: 0,
        officerStats: [],
      );
      expect(empty.shiftCompletionRate, isNull);

      const populated = MonthlyComplianceSummary(
        siteId: 'site-1',
        year: 2026,
        month: 6,
        totalScheduledShifts: 20,
        completedShifts: 18,
        totalCheckins: 50,
        verifiedCheckins: 45,
        flaggedCheckins: 3,
        rejectedCheckins: 2,
        manualApprovedOverrides: 2,
        manualRejectedOverrides: 1,
        openIncidentReports: 1,
        resolvedIncidentReports: 4,
        totalSosEvents: 1,
        officerStats: [],
      );
      expect(populated.shiftCompletionRate, closeTo(0.9, 0.0001));
    });

    test('SosEvent computes responseDuration and active status accurately', () {
      final triggered = DateTime.utc(2026, 6, 1, 20, 0, 0);
      final acked = DateTime.utc(2026, 6, 1, 20, 1, 30);
      final event = SosEvent(
        id: 'sos-1',
        siteId: 'site-1',
        reporterId: 'user-1',
        category: SosCategory.pencurian,
        latitude: -7.25,
        longitude: 112.75,
        addressNote: 'Blok A-04',
        note: '',
        status: SosStatus.acknowledged,
        triggeredAt: triggered,
        acknowledgedAt: acked,
      );

      expect(event.isActive, isTrue);
      expect(event.isEscalated, isFalse);
      expect(event.responseDuration, const Duration(seconds: 90));
    });
  });
}
