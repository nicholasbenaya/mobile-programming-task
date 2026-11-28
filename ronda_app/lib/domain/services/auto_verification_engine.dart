import 'package:ronda_app/domain/models/checkpoint.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/schedule.dart';
import 'package:ronda_app/domain/services/haversine_calculator.dart';
import 'package:ronda_app/domain/services/qr_codec.dart';

/// Input forensic snapshot for deterministic check-in integrity evaluation.
class AutoVerificationInput {
  const AutoVerificationInput({
    required this.checkpoint,
    required this.qrRawPayload,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMocked,
    required this.photoSha256,
    required this.capturedAtClient,
    required this.evaluatedAtServer,
    required this.isOfflineSubmission,
    this.qrSecret,
    this.photoPath,
    this.expectedPhotoPathPrefix,
    this.activeSchedule,
    this.officerId,
  });

  final Checkpoint checkpoint;
  final String qrRawPayload;
  final String? qrSecret;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isMocked;
  final String photoSha256;
  final String? photoPath;
  final String? expectedPhotoPathPrefix;
  final DateTime capturedAtClient;
  final DateTime evaluatedAtServer;
  final bool isOfflineSubmission;
  final PatrolSchedule? activeSchedule;
  final String? officerId;
}

/// Deterministic output mirroring server-side `submit_patrol_checkin` rules.
class AutoVerificationResult {
  const AutoVerificationResult({
    required this.autoStatus,
    required this.flagReasons,
    required this.distanceMeters,
    required this.scannedTokenVersion,
  });

  final AutoVerificationStatus autoStatus;
  final List<CheckinFlagReason> flagReasons;
  final double distanceMeters;
  final int scannedTokenVersion;

  bool get isAutoVerified => autoStatus == AutoVerificationStatus.autoVerified;
  bool get isFlaggedForReview =>
      autoStatus == AutoVerificationStatus.flaggedReview;
  bool get isAutoRejected => autoStatus == AutoVerificationStatus.autoRejected;
}

/// Pure-Dart mirror of PostgreSQL `submit_patrol_checkin` integrity checks
/// used for immediate pre-submit and offline officer feedback.
abstract final class AutoVerificationEngine {
  static const double lowGpsAccuracyThresholdMeters = 35.0;
  static const Duration maxOfflineSyncDelay = Duration(minutes: 30);
  static const Duration maxClockSkew = Duration(minutes: 5);
  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-fA-F]{64}$');

  static AutoVerificationResult evaluate(AutoVerificationInput input) {
    final reasons = <CheckinFlagReason>[];
    var hasHardFail = false;
    var hasSoftFlag = false;

    void addReason(CheckinFlagReason reason) {
      reasons.add(reason);
      if (reason.isHardFail) {
        hasHardFail = true;
      } else {
        hasSoftFlag = true;
      }
    }

    // Rule 1: Signed QR structure, active checkpoint, token version, and optional HMAC.
    final parsedQr = QrCodec.tryParse(input.qrRawPayload);
    final scannedVersion =
        parsedQr?.tokenVersion ?? QrCodec.extractVersionOrZero(input.qrRawPayload);

    var qrValid = parsedQr != null &&
        QrCodec.matchesCheckpoint(qr: parsedQr, checkpoint: input.checkpoint);
    if (qrValid && input.qrSecret != null) {
      qrValid = QrCodec.verifySignature(
        qr: parsedQr,
        secret: input.qrSecret!,
      );
    }
    if (!qrValid) {
      addReason(CheckinFlagReason.qrInvalidOrRevoked);
    }

    // Rule 2: Mock GPS flag.
    if (input.isMocked) {
      addReason(CheckinFlagReason.mockGpsDetected);
    }

    // Rule 3: Photo SHA-256 format and optional storage path ownership check.
    final normalizedHash = input.photoSha256.trim();
    var photoValid = _sha256Pattern.hasMatch(normalizedHash);
    if (photoValid && input.photoPath != null) {
      final path = input.photoPath!.trim();
      if (path.isEmpty) {
        photoValid = false;
      } else if (input.expectedPhotoPathPrefix != null &&
          !path.startsWith(input.expectedPhotoPathPrefix!)) {
        photoValid = false;
      }
    }
    if (!photoValid) {
      addReason(CheckinFlagReason.photoHashMissingOrMismatch);
    }

    // Rule 4 & 5: Haversine geofence distance (borderline soft flag vs extreme hard fail).
    final distanceMeters = HaversineCalculator.distanceMeters(
      lat1: input.latitude,
      lng1: input.longitude,
      lat2: input.checkpoint.latitude,
      lng2: input.checkpoint.longitude,
    );
    final extremeLimitMeters = HaversineCalculator.extremeGeofenceLimitMeters(
      input.checkpoint.radiusMeters,
    );

    if (distanceMeters > extremeLimitMeters) {
      addReason(CheckinFlagReason.outsideGeofenceExtreme);
    } else if (distanceMeters > input.checkpoint.radiusMeters) {
      addReason(CheckinFlagReason.outsideGeofenceBorderline);
    }

    // Rule 6: GPS horizontal accuracy threshold.
    if (!input.accuracyMeters.isFinite ||
        input.accuracyMeters < 0 ||
        input.accuracyMeters > lowGpsAccuracyThresholdMeters) {
      addReason(CheckinFlagReason.lowGpsAccuracy);
    }

    // Rule 7: Shift window verification.
    if (!_isWithinValidSchedule(input)) {
      addReason(CheckinFlagReason.outsideShiftWindow);
    }

    // Rule 8: Offline sync delay (> 30 min) or client/server clock skew (> 5 min).
    final skew = input.evaluatedAtServer
        .toUtc()
        .difference(input.capturedAtClient.toUtc());
    final maxAllowedLag =
        input.isOfflineSubmission ? maxOfflineSyncDelay : maxClockSkew;
    final isFutureSkew = skew < -maxClockSkew;
    final isPastDelay = skew > maxAllowedLag;
    if (isFutureSkew || isPastDelay) {
      addReason(CheckinFlagReason.offlineDelayOrClockSkew);
    }

    final autoStatus = hasHardFail
        ? AutoVerificationStatus.autoRejected
        : hasSoftFlag
            ? AutoVerificationStatus.flaggedReview
            : AutoVerificationStatus.autoVerified;

    return AutoVerificationResult(
      autoStatus: autoStatus,
      flagReasons: List<CheckinFlagReason>.unmodifiable(reasons),
      distanceMeters: distanceMeters,
      scannedTokenVersion: scannedVersion,
    );
  }

  static bool _isWithinValidSchedule(AutoVerificationInput input) {
    final schedule = input.activeSchedule;
    if (schedule == null) {
      return false;
    }
    if (!schedule.status.countsForCollision) {
      return false;
    }
    if (schedule.siteId.toLowerCase() != input.checkpoint.siteId.toLowerCase()) {
      return false;
    }
    if (input.officerId != null &&
        schedule.officerId.toLowerCase() != input.officerId!.toLowerCase()) {
      return false;
    }
    return schedule.coversTimestamp(input.capturedAtClient);
  }
}
