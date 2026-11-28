import 'package:ronda_app/domain/models/checkpoint.dart';

/// Contract for site checkpoints, printable QR payload generation, and resident transparency summaries.
abstract interface class CheckpointRepository {
  Stream<List<Checkpoint>> watchCheckpoints(
    String siteId, {
    bool activeOnly = false,
  });

  Future<Checkpoint> createCheckpoint({
    required String siteId,
    required String code,
    required String name,
    String description = '',
    required double latitude,
    required double longitude,
    int radiusMeters = 30,
    int sortOrder = 0,
    String? targetTimeLocal,
  });

  Future<Checkpoint> updateCheckpoint({
    required String checkpointId,
    String? code,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    int? sortOrder,
    String? targetTimeLocal,
    bool clearTargetTimeLocal = false,
    bool? isActive,
  });

  Future<void> deactivateCheckpoint(String checkpointId);

  Future<CheckpointQrPayload> getAdminQrPayload(String checkpointId);

  Future<CheckpointQrPayload> regenerateQrToken(String checkpointId);

  Future<List<CheckpointPatrolSummary>> fetchPatrolSummary({
    required String siteId,
    DateTime? since,
  });
}
