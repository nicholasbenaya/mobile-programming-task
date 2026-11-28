import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/domain/models/checkpoint.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/schedule.dart';
import 'package:ronda_app/domain/services/auto_verification_engine.dart';
import 'package:ronda_app/domain/services/qr_codec.dart';

void main() {
  const siteId = '11111111-1111-4111-8111-111111111111';
  const checkpointId = '22222222-2222-4222-8222-222222222222';
  const officerId = '33333333-3333-4333-8333-333333333333';
  const secret = 'abcdef0123456789abcdef0123456789';
  final validSha256 = 'a' * 64;

  final shiftStart = DateTime.utc(2026, 6, 1, 15, 0); // 22:00 WIB
  final shiftEnd = DateTime.utc(2026, 6, 1, 23, 0); // 06:00 WIB next day
  final captureTime = DateTime.utc(2026, 6, 1, 16, 0);

  Checkpoint buildCheckpoint({
    int radiusMeters = 30,
    int version = 1,
    bool isActive = true,
  }) {
    return Checkpoint(
      id: checkpointId,
      siteId: siteId,
      code: 'POS-01',
      name: 'Pos Gerbang',
      description: '',
      latitude: -7.2575,
      longitude: 112.7521,
      radiusMeters: radiusMeters,
      sortOrder: 1,
      qrTokenVersion: version,
      isActive: isActive,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  PatrolSchedule buildSchedule({
    String ownerId = officerId,
    ScheduleStatus status = ScheduleStatus.scheduled,
  }) {
    return PatrolSchedule(
      id: '44444444-4444-4444-8444-444444444444',
      siteId: siteId,
      officerId: ownerId,
      shiftName: 'Shift Malam',
      shiftDate: DateTime.utc(2026, 6, 1),
      startsAt: shiftStart,
      endsAt: shiftEnd,
      status: status,
      createdAt: DateTime.utc(2026, 5, 1),
    );
  }

  AutoVerificationInput buildValidInput({
    Checkpoint? checkpoint,
    String? qrRawPayload,
    String? qrSecret = secret,
    double latitude = -7.2575,
    double longitude = 112.7521,
    double accuracyMeters = 10.0,
    bool isMocked = false,
    String? photoSha256,
    String? photoPath,
    String? expectedPhotoPathPrefix,
    DateTime? capturedAtClient,
    DateTime? evaluatedAtServer,
    bool isOfflineSubmission = false,
    PatrolSchedule? activeSchedule,
    bool includeSchedule = true,
  }) {
    final cp = checkpoint ?? buildCheckpoint();
    final qr = qrRawPayload ??
        QrCodec.encode(
          siteId: cp.siteId,
          checkpointId: cp.id,
          tokenVersion: cp.qrTokenVersion,
          secret: secret,
        );
    return AutoVerificationInput(
      checkpoint: cp,
      qrRawPayload: qr,
      qrSecret: qrSecret,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      isMocked: isMocked,
      photoSha256: photoSha256 ?? validSha256,
      photoPath: photoPath,
      expectedPhotoPathPrefix: expectedPhotoPathPrefix,
      capturedAtClient: capturedAtClient ?? captureTime,
      evaluatedAtServer: evaluatedAtServer ?? captureTime.add(const Duration(seconds: 20)),
      isOfflineSubmission: isOfflineSubmission,
      activeSchedule: includeSchedule ? (activeSchedule ?? buildSchedule()) : null,
      officerId: officerId,
    );
  }

  group('AutoVerificationEngine', () {
    test('returns autoVerified when all integrity checks pass', () {
      final result = AutoVerificationEngine.evaluate(buildValidInput());

      expect(result.autoStatus, AutoVerificationStatus.autoVerified);
      expect(result.isAutoVerified, isTrue);
      expect(result.flagReasons, isEmpty);
      expect(result.distanceMeters, 0.0);
      expect(result.scannedTokenVersion, 1);
    });

    test('hard-fails on invalid, tampered, or revoked QR payload', () {
      final tampered = buildValidInput(
        qrRawPayload: 'RD1|$siteId|$checkpointId|1|${'f' * 64}',
      );
      final tamperedResult = AutoVerificationEngine.evaluate(tampered);
      expect(tamperedResult.autoStatus, AutoVerificationStatus.autoRejected);
      expect(
        tamperedResult.flagReasons,
        contains(CheckinFlagReason.qrInvalidOrRevoked),
      );

      final revoked = buildValidInput(
        checkpoint: buildCheckpoint(version: 2),
        qrRawPayload: QrCodec.encode(
          siteId: siteId,
          checkpointId: checkpointId,
          tokenVersion: 1,
          secret: secret,
        ),
      );
      final revokedResult = AutoVerificationEngine.evaluate(revoked);
      expect(revokedResult.autoStatus, AutoVerificationStatus.autoRejected);
      expect(revokedResult.scannedTokenVersion, 1);
      expect(
        revokedResult.flagReasons,
        contains(CheckinFlagReason.qrInvalidOrRevoked),
      );
    });

    test('supports client offline preview when qrSecret is null', () {
      final result = AutoVerificationEngine.evaluate(
        buildValidInput(qrSecret: null),
      );
      expect(result.isAutoVerified, isTrue);
    });

    test('hard-fails when mock GPS is detected', () {
      final result = AutoVerificationEngine.evaluate(
        buildValidInput(isMocked: true),
      );
      expect(result.isAutoRejected, isTrue);
      expect(result.flagReasons, contains(CheckinFlagReason.mockGpsDetected));
    });

    test('hard-fails when photo SHA-256 is invalid or storage path prefix mismatches', () {
      final badHash = AutoVerificationEngine.evaluate(
        buildValidInput(photoSha256: 'short'),
      );
      expect(badHash.isAutoRejected, isTrue);
      expect(
        badHash.flagReasons,
        contains(CheckinFlagReason.photoHashMissingOrMismatch),
      );

      final badPath = AutoVerificationEngine.evaluate(
        buildValidInput(
          photoPath: 'other-site/checkins/$officerId/event.jpg',
          expectedPhotoPathPrefix: '$siteId/checkins/$officerId/',
        ),
      );
      expect(badPath.isAutoRejected, isTrue);
      expect(
        badPath.flagReasons,
        contains(CheckinFlagReason.photoHashMissingOrMismatch),
      );
    });

    test('flags borderline geofence drift and hard-fails extreme geofence drift', () {
      // +0.0005 deg lat is ~55.6 m (> 30 m radius, <= 150 m extreme limit).
      final borderline = AutoVerificationEngine.evaluate(
        buildValidInput(latitude: -7.2570),
      );
      expect(borderline.isFlaggedForReview, isTrue);
      expect(borderline.distanceMeters, greaterThan(30.0));
      expect(borderline.distanceMeters, lessThanOrEqualTo(150.0));
      expect(
        borderline.flagReasons,
        equals([CheckinFlagReason.outsideGeofenceBorderline]),
      );

      // +0.0020 deg lat is ~222.4 m (> 150 m extreme limit for 30 m radius).
      final extreme = AutoVerificationEngine.evaluate(
        buildValidInput(latitude: -7.2555),
      );
      expect(extreme.isAutoRejected, isTrue);
      expect(extreme.distanceMeters, greaterThan(150.0));
      expect(
        extreme.flagReasons,
        equals([CheckinFlagReason.outsideGeofenceExtreme]),
      );

      // For a 70 m radius checkpoint, extreme limit is 210 m, so ~180 m is borderline.
      final largeRadiusBorderline = AutoVerificationEngine.evaluate(
        buildValidInput(
          checkpoint: buildCheckpoint(radiusMeters: 70),
          latitude: -7.2559,
        ),
      );
      expect(largeRadiusBorderline.isFlaggedForReview, isTrue);
      expect(
        largeRadiusBorderline.flagReasons,
        equals([CheckinFlagReason.outsideGeofenceBorderline]),
      );
    });

    test('flags low GPS accuracy strictly above 35 meters', () {
      final atThreshold = AutoVerificationEngine.evaluate(
        buildValidInput(accuracyMeters: 35.0),
      );
      expect(atThreshold.isAutoVerified, isTrue);

      final aboveThreshold = AutoVerificationEngine.evaluate(
        buildValidInput(accuracyMeters: 35.1),
      );
      expect(aboveThreshold.isFlaggedForReview, isTrue);
      expect(
        aboveThreshold.flagReasons,
        equals([CheckinFlagReason.lowGpsAccuracy]),
      );
    });

    test('flags outside shift window when schedule is missing, inactive, or outside hours', () {
      final noSchedule = AutoVerificationEngine.evaluate(
        buildValidInput(includeSchedule: false),
      );
      expect(noSchedule.isFlaggedForReview, isTrue);
      expect(
        noSchedule.flagReasons,
        contains(CheckinFlagReason.outsideShiftWindow),
      );

      final outsideTime = AutoVerificationEngine.evaluate(
        buildValidInput(
          capturedAtClient: shiftStart.subtract(const Duration(minutes: 10)),
          evaluatedAtServer: shiftStart.subtract(const Duration(minutes: 9)),
        ),
      );
      expect(outsideTime.isFlaggedForReview, isTrue);
      expect(
        outsideTime.flagReasons,
        contains(CheckinFlagReason.outsideShiftWindow),
      );

      final absentSchedule = AutoVerificationEngine.evaluate(
        buildValidInput(
          activeSchedule: buildSchedule(status: ScheduleStatus.absent),
        ),
      );
      expect(absentSchedule.isFlaggedForReview, isTrue);
      expect(
        absentSchedule.flagReasons,
        contains(CheckinFlagReason.outsideShiftWindow),
      );
    });

    test('enforces online 5-min clock skew, offline 30-min sync delay, and future skew', () {
      final onlineOk = AutoVerificationEngine.evaluate(
        buildValidInput(
          isOfflineSubmission: false,
          evaluatedAtServer: captureTime.add(const Duration(minutes: 5)),
        ),
      );
      expect(onlineOk.isAutoVerified, isTrue);

      final onlineDelayed = AutoVerificationEngine.evaluate(
        buildValidInput(
          isOfflineSubmission: false,
          evaluatedAtServer: captureTime.add(const Duration(minutes: 5, seconds: 1)),
        ),
      );
      expect(onlineDelayed.isFlaggedForReview, isTrue);
      expect(
        onlineDelayed.flagReasons,
        equals([CheckinFlagReason.offlineDelayOrClockSkew]),
      );

      final offlineOk = AutoVerificationEngine.evaluate(
        buildValidInput(
          isOfflineSubmission: true,
          evaluatedAtServer: captureTime.add(const Duration(minutes: 29)),
        ),
      );
      expect(offlineOk.isAutoVerified, isTrue);

      final offlineDelayed = AutoVerificationEngine.evaluate(
        buildValidInput(
          isOfflineSubmission: true,
          evaluatedAtServer: captureTime.add(const Duration(minutes: 31)),
        ),
      );
      expect(offlineDelayed.isFlaggedForReview, isTrue);
      expect(
        offlineDelayed.flagReasons,
        equals([CheckinFlagReason.offlineDelayOrClockSkew]),
      );

      final futureClockSkew = AutoVerificationEngine.evaluate(
        buildValidInput(
          isOfflineSubmission: true,
          evaluatedAtServer: captureTime.subtract(const Duration(minutes: 6)),
        ),
      );
      expect(futureClockSkew.isFlaggedForReview, isTrue);
      expect(
        futureClockSkew.flagReasons,
        equals([CheckinFlagReason.offlineDelayOrClockSkew]),
      );
    });

    test('prioritizes autoRejected when hard fails combine with soft flags and preserves all reasons', () {
      final result = AutoVerificationEngine.evaluate(
        buildValidInput(
          isMocked: true,
          accuracyMeters: 60.0,
          includeSchedule: false,
        ),
      );

      expect(result.isAutoRejected, isTrue);
      expect(
        result.flagReasons,
        containsAll([
          CheckinFlagReason.mockGpsDetected,
          CheckinFlagReason.lowGpsAccuracy,
          CheckinFlagReason.outsideShiftWindow,
        ]),
      );
    });
  });
}
