import 'package:ronda_app/domain/models/enums.dart';

/// Domain entity for `patrol_checkins`.
class PatrolCheckin {
  const PatrolCheckin({
    required this.id,
    required this.clientEventId,
    required this.siteId,
    required this.checkpointId,
    required this.officerId,
    required this.qrTokenVersionScanned,
    required this.photoPath,
    required this.photoSha256,
    required this.capturedAtClient,
    required this.syncedAtServer,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.distanceMeters,
    required this.isMocked,
    required this.isOfflineSubmission,
    required this.officerNote,
    required this.autoStatus,
    required this.flagReasons,
    required this.effectiveStatus,
    required this.createdAt,
    this.scheduleId,
    this.deviceModel,
    this.manualStatus,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.checkpointCode,
    this.checkpointName,
    this.officerName,
    this.reviewerName,
  });

  final String id;
  final String clientEventId;
  final String siteId;
  final String checkpointId;
  final String? scheduleId;
  final String officerId;
  final int qrTokenVersionScanned;
  final String photoPath;
  final String photoSha256;
  final DateTime capturedAtClient;
  final DateTime syncedAtServer;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double distanceMeters;
  final bool isMocked;
  final bool isOfflineSubmission;
  final String? deviceModel;
  final String officerNote;
  final AutoVerificationStatus autoStatus;
  final List<CheckinFlagReason> flagReasons;
  final ManualReviewStatus? manualStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final EffectiveCheckinStatus effectiveStatus;
  final DateTime createdAt;
  final String? checkpointCode;
  final String? checkpointName;
  final String? officerName;
  final String? reviewerName;

  bool get isManuallyOverridden => manualStatus != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatrolCheckin &&
          other.id == id &&
          other.clientEventId == clientEventId &&
          other.siteId == siteId &&
          other.checkpointId == checkpointId &&
          other.scheduleId == scheduleId &&
          other.officerId == officerId &&
          other.qrTokenVersionScanned == qrTokenVersionScanned &&
          other.photoPath == photoPath &&
          other.photoSha256 == photoSha256 &&
          other.capturedAtClient == capturedAtClient &&
          other.syncedAtServer == syncedAtServer &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.accuracyMeters == accuracyMeters &&
          other.distanceMeters == distanceMeters &&
          other.isMocked == isMocked &&
          other.isOfflineSubmission == isOfflineSubmission &&
          other.deviceModel == deviceModel &&
          other.officerNote == officerNote &&
          other.autoStatus == autoStatus &&
          _listEquals(other.flagReasons, flagReasons) &&
          other.manualStatus == manualStatus &&
          other.reviewedBy == reviewedBy &&
          other.reviewedAt == reviewedAt &&
          other.reviewNote == reviewNote &&
          other.effectiveStatus == effectiveStatus &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        clientEventId,
        siteId,
        checkpointId,
        scheduleId,
        officerId,
        qrTokenVersionScanned,
        photoPath,
        photoSha256,
        capturedAtClient,
        syncedAtServer,
        latitude,
        longitude,
        accuracyMeters,
        distanceMeters,
        isMocked,
        isOfflineSubmission,
        deviceModel,
        officerNote,
        autoStatus,
        Object.hashAll(flagReasons),
        manualStatus,
        reviewedBy,
        reviewedAt,
        reviewNote,
        effectiveStatus,
        createdAt,
      ]);
}

/// Domain entity for immutable `checkin_audit_logs`.
class CheckinAuditLog {
  const CheckinAuditLog({
    required this.id,
    required this.checkinId,
    required this.siteId,
    required this.action,
    required this.newStatus,
    required this.note,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.previousStatus,
  });

  final String id;
  final String checkinId;
  final String siteId;
  final String? actorId;
  final String? actorName;
  final AuditAction action;
  final String? previousStatus;
  final String newStatus;
  final String note;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinAuditLog &&
          other.id == id &&
          other.checkinId == checkinId &&
          other.siteId == siteId &&
          other.actorId == actorId &&
          other.action == action &&
          other.previousStatus == previousStatus &&
          other.newStatus == newStatus &&
          other.note == note &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        checkinId,
        siteId,
        actorId,
        action,
        previousStatus,
        newStatus,
        note,
        createdAt,
      );
}

/// Client capture payload submitted online or persisted to SQLite offline queue.
class CheckinSubmissionDraft {
  const CheckinSubmissionDraft({
    required this.clientEventId,
    required this.siteId,
    required this.checkpointId,
    required this.qrRawPayload,
    required this.localPhotoPath,
    required this.photoSha256,
    required this.capturedAtClient,
    required this.monotonicMs,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMocked,
    this.scheduleId,
    this.deviceModel,
    this.officerNote = '',
  });

  final String clientEventId;
  final String siteId;
  final String checkpointId;
  final String? scheduleId;
  final String qrRawPayload;
  final String localPhotoPath;
  final String photoSha256;
  final DateTime capturedAtClient;
  final int monotonicMs;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isMocked;
  final String? deviceModel;
  final String officerNote;
}

/// Local SQLite offline queue representation shown in Officer sync sheet.
class OfflineQueueItem {
  const OfflineQueueItem({
    required this.clientEventId,
    required this.siteId,
    required this.checkpointId,
    required this.localPhotoPath,
    required this.photoSha256,
    required this.capturedAtClient,
    required this.syncState,
    required this.retryCount,
    this.lastError,
    this.checkpointName,
  });

  final String clientEventId;
  final String siteId;
  final String checkpointId;
  final String localPhotoPath;
  final String photoSha256;
  final DateTime capturedAtClient;
  final OfflineSyncState syncState;
  final int retryCount;
  final String? lastError;
  final String? checkpointName;
}

/// Outcome returned by `CheckinRepository.submitCheckin`.
class CheckinSubmitOutcome {
  const CheckinSubmitOutcome({
    this.syncedCheckin,
    this.queuedItem,
  }) : assert(
          (syncedCheckin != null) ^ (queuedItem != null),
          'Exactly one of syncedCheckin or queuedItem must be provided.',
        );

  final PatrolCheckin? syncedCheckin;
  final OfflineQueueItem? queuedItem;

  bool get isQueuedOffline => queuedItem != null;
}

/// Summary returned after an offline sync pass finishes.
class SyncRunSummary {
  const SyncRunSummary({
    required this.syncedCount,
    required this.failedCount,
    required this.remainingCount,
  });

  final int syncedCount;
  final int failedCount;
  final int remainingCount;
}

/// Filter options for Admin manual check-in audit queue.
class AuditQueueFilter {
  const AuditQueueFilter({
    this.effectiveStatuses,
    this.autoStatus,
    this.manualStatus,
    this.officerId,
    this.checkpointId,
    this.fromDate,
    this.toDate,
    this.limit = 100,
  });

  final List<EffectiveCheckinStatus>? effectiveStatuses;
  final AutoVerificationStatus? autoStatus;
  final ManualReviewStatus? manualStatus;
  final String? officerId;
  final String? checkpointId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
