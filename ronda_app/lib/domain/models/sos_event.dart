import 'package:ronda_app/domain/models/enums.dart';

/// Domain entity for `sos_events`.
class SosEvent {
  const SosEvent({
    required this.id,
    required this.siteId,
    required this.reporterId,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.addressNote,
    required this.note,
    required this.status,
    required this.triggeredAt,
    this.escalatedAt,
    this.responderId,
    this.acknowledgedAt,
    this.onSceneAt,
    this.resolvedAt,
    this.resolutionNote,
    this.resolutionPhotoPath,
    this.cancelReason,
    this.reporterName,
    this.responderName,
  });

  final String id;
  final String siteId;
  final String reporterId;
  final SosCategory category;
  final double latitude;
  final double longitude;
  final String addressNote;
  final String note;
  final SosStatus status;
  final DateTime triggeredAt;
  final DateTime? escalatedAt;
  final String? responderId;
  final DateTime? acknowledgedAt;
  final DateTime? onSceneAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String? resolutionPhotoPath;
  final String? cancelReason;
  final String? reporterName;
  final String? responderName;

  bool get isEscalated => escalatedAt != null;
  bool get isActive => status.isActive;

  Duration? get responseDuration {
    if (acknowledgedAt == null) {
      return null;
    }
    return acknowledgedAt!.difference(triggeredAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosEvent &&
          other.id == id &&
          other.siteId == siteId &&
          other.reporterId == reporterId &&
          other.category == category &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.addressNote == addressNote &&
          other.note == note &&
          other.status == status &&
          other.triggeredAt == triggeredAt &&
          other.escalatedAt == escalatedAt &&
          other.responderId == responderId &&
          other.acknowledgedAt == acknowledgedAt &&
          other.onSceneAt == onSceneAt &&
          other.resolvedAt == resolvedAt &&
          other.resolutionNote == resolutionNote &&
          other.resolutionPhotoPath == resolutionPhotoPath &&
          other.cancelReason == cancelReason;

  @override
  int get hashCode => Object.hash(
        id,
        siteId,
        reporterId,
        category,
        latitude,
        longitude,
        addressNote,
        note,
        status,
        triggeredAt,
        escalatedAt,
        responderId,
        acknowledgedAt,
        onSceneAt,
        resolvedAt,
        resolutionNote,
        resolutionPhotoPath,
        cancelReason,
      );
}

/// Domain entity for `device_tokens`.
class DeviceToken {
  const DeviceToken({
    required this.id,
    required this.userId,
    required this.fcmToken,
    required this.platform,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String fcmToken;
  final DevicePlatform platform;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceToken &&
          other.id == id &&
          other.userId == userId &&
          other.fcmToken == fcmToken &&
          other.platform == platform &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, userId, fcmToken, platform, updatedAt);
}
