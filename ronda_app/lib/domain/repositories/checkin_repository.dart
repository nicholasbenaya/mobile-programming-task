import 'package:ronda_app/domain/models/checkin.dart';
import 'package:ronda_app/domain/models/enums.dart';

/// Contract for forensic check-in capture/submission, SQLite offline sync, and Admin manual audit.
abstract interface class CheckinRepository {
  Future<CheckinSubmitOutcome> submitCheckin(CheckinSubmissionDraft draft);

  Stream<List<PatrolCheckin>> watchShiftCheckins({
    required String siteId,
    DateTime? since,
    String? officerId,
  });

  Stream<int> watchPendingOfflineCount(String siteId);

  Future<List<OfflineQueueItem>> fetchPendingOfflineItems(String siteId);

  Future<SyncRunSummary> syncNow();

  Future<List<PatrolCheckin>> fetchAuditQueue({
    required String siteId,
    AuditQueueFilter filter = const AuditQueueFilter(),
  });

  Future<String> getEvidenceSignedUrl(
    String storagePath, {
    Duration expiresIn = const Duration(minutes: 15),
  });

  Future<PatrolCheckin> reviewCheckinManual({
    required String checkinId,
    required ManualReviewStatus decision,
    required String reviewNote,
  });

  Future<List<CheckinAuditLog>> fetchCheckinAuditLogs(String checkinId);
}
