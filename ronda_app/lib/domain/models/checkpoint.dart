/// Domain entity for `checkpoints`.
/// `qr_secret` stays server-side and is intentionally omitted from client models.
class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.siteId,
    required this.code,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.sortOrder,
    required this.qrTokenVersion,
    required this.isActive,
    required this.createdAt,
    this.targetTimeLocal,
  });

  final String id;
  final String siteId;
  final String code;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int sortOrder;
  final String? targetTimeLocal;
  final int qrTokenVersion;
  final bool isActive;
  final DateTime createdAt;

  Checkpoint copyWith({
    String? code,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    int? sortOrder,
    String? targetTimeLocal,
    bool clearTargetTimeLocal = false,
    int? qrTokenVersion,
    bool? isActive,
  }) {
    return Checkpoint(
      id: id,
      siteId: siteId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      sortOrder: sortOrder ?? this.sortOrder,
      targetTimeLocal: clearTargetTimeLocal
          ? null
          : (targetTimeLocal ?? this.targetTimeLocal),
      qrTokenVersion: qrTokenVersion ?? this.qrTokenVersion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Checkpoint &&
          other.id == id &&
          other.siteId == siteId &&
          other.code == code &&
          other.name == name &&
          other.description == description &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.radiusMeters == radiusMeters &&
          other.sortOrder == sortOrder &&
          other.targetTimeLocal == targetTimeLocal &&
          other.qrTokenVersion == qrTokenVersion &&
          other.isActive == isActive &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        siteId,
        code,
        name,
        description,
        latitude,
        longitude,
        radiusMeters,
        sortOrder,
        targetTimeLocal,
        qrTokenVersion,
        isActive,
        createdAt,
      );
}

/// Signed QR payload returned by `get_checkpoint_qr_payload` or `regenerate_checkpoint_qr`.
class CheckpointQrPayload {
  const CheckpointQrPayload({
    required this.checkpointId,
    required this.siteId,
    required this.code,
    required this.name,
    required this.qrTokenVersion,
    required this.qrPayload,
  });

  final String checkpointId;
  final String siteId;
  final String code;
  final String name;
  final int qrTokenVersion;
  final String qrPayload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckpointQrPayload &&
          other.checkpointId == checkpointId &&
          other.siteId == siteId &&
          other.code == code &&
          other.name == name &&
          other.qrTokenVersion == qrTokenVersion &&
          other.qrPayload == qrPayload;

  @override
  int get hashCode =>
      Object.hash(checkpointId, siteId, code, name, qrTokenVersion, qrPayload);
}

/// Resident-safe verification progress summary per checkpoint.
class CheckpointPatrolSummary {
  const CheckpointPatrolSummary({
    required this.checkpointId,
    required this.verifiedCount,
    this.lastVerifiedAt,
  });

  final String checkpointId;
  final DateTime? lastVerifiedAt;
  final int verifiedCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckpointPatrolSummary &&
          other.checkpointId == checkpointId &&
          other.lastVerifiedAt == lastVerifiedAt &&
          other.verifiedCount == verifiedCount;

  @override
  int get hashCode => Object.hash(checkpointId, lastVerifiedAt, verifiedCount);
}
