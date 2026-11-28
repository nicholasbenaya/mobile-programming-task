import 'package:ronda_app/domain/models/enums.dart';

/// Domain entity for `shift_templates`.
class ShiftTemplate {
  const ShiftTemplate({
    required this.id,
    required this.siteId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isOvernight,
    required this.isActive,
  });

  final String id;
  final String siteId;
  final String name;
  final String startTime;
  final String endTime;
  final bool isOvernight;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftTemplate &&
          other.id == id &&
          other.siteId == siteId &&
          other.name == name &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.isOvernight == isOvernight &&
          other.isActive == isActive;

  @override
  int get hashCode =>
      Object.hash(id, siteId, name, startTime, endTime, isOvernight, isActive);
}

/// Domain entity for `patrol_schedules`.
class PatrolSchedule {
  const PatrolSchedule({
    required this.id,
    required this.siteId,
    required this.officerId,
    required this.shiftName,
    required this.shiftDate,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.createdAt,
    this.templateId,
    this.officerName,
  });

  final String id;
  final String siteId;
  final String officerId;
  final String? templateId;
  final String shiftName;
  final DateTime shiftDate;
  final DateTime startsAt;
  final DateTime endsAt;
  final ScheduleStatus status;
  final DateTime createdAt;
  final String? officerName;

  bool coversTimestamp(DateTime instant) {
    final utcInstant = instant.toUtc();
    return !utcInstant.isBefore(startsAt.toUtc()) &&
        !utcInstant.isAfter(endsAt.toUtc());
  }

  PatrolSchedule copyWith({
    String? officerId,
    String? officerName,
    ScheduleStatus? status,
  }) {
    return PatrolSchedule(
      id: id,
      siteId: siteId,
      officerId: officerId ?? this.officerId,
      templateId: templateId,
      shiftName: shiftName,
      shiftDate: shiftDate,
      startsAt: startsAt,
      endsAt: endsAt,
      status: status ?? this.status,
      createdAt: createdAt,
      officerName: officerName ?? this.officerName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatrolSchedule &&
          other.id == id &&
          other.siteId == siteId &&
          other.officerId == officerId &&
          other.templateId == templateId &&
          other.shiftName == shiftName &&
          other.shiftDate == shiftDate &&
          other.startsAt == startsAt &&
          other.endsAt == endsAt &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.officerName == officerName;

  @override
  int get hashCode => Object.hash(
        id,
        siteId,
        officerId,
        templateId,
        shiftName,
        shiftDate,
        startsAt,
        endsAt,
        status,
        createdAt,
        officerName,
      );
}

/// Configuration for fair collision-safe auto-schedule generation.
class AutoScheduleConfig {
  const AutoScheduleConfig({
    required this.startDate,
    required this.endDate,
    required this.officerIds,
    required this.templates,
    this.workDaysPerCycle = 5,
    this.restDaysPerCycle = 1,
    this.officersPerShift = 1,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<String> officerIds;
  final List<ShiftTemplate> templates;
  final int workDaysPerCycle;
  final int restDaysPerCycle;
  final int officersPerShift;
}

/// Domain entity for `shift_swaps`.
class ShiftSwap {
  const ShiftSwap({
    required this.id,
    required this.siteId,
    required this.scheduleId,
    required this.requesterId,
    required this.targetOfficerId,
    required this.reason,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.targetScheduleId,
    this.respondedAt,
    this.requesterName,
    this.targetOfficerName,
  });

  final String id;
  final String siteId;
  final String scheduleId;
  final String requesterId;
  final String targetOfficerId;
  final String? targetScheduleId;
  final String reason;
  final SwapStatus status;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final String? requesterName;
  final String? targetOfficerName;

  bool isExpiredAt(DateTime now) => !now.toUtc().isBefore(expiresAt.toUtc());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftSwap &&
          other.id == id &&
          other.siteId == siteId &&
          other.scheduleId == scheduleId &&
          other.requesterId == requesterId &&
          other.targetOfficerId == targetOfficerId &&
          other.targetScheduleId == targetScheduleId &&
          other.reason == reason &&
          other.status == status &&
          other.expiresAt == expiresAt &&
          other.respondedAt == respondedAt &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        siteId,
        scheduleId,
        requesterId,
        targetOfficerId,
        targetScheduleId,
        reason,
        status,
        expiresAt,
        respondedAt,
        createdAt,
      );
}

/// Domain entity for `shift_handovers` (Buku Mutasi / Serah Terima Shift).
class ShiftHandover {
  const ShiftHandover({
    required this.id,
    required this.siteId,
    required this.authorId,
    required this.summary,
    required this.assetStatus,
    required this.createdAt,
    this.fromScheduleId,
    this.photoPath,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.clientEventId,
    this.authorName,
    this.acknowledgedByName,
  });

  final String id;
  final String siteId;
  final String? fromScheduleId;
  final String authorId;
  final String summary;
  final String assetStatus;
  final String? photoPath;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? clientEventId;
  final DateTime createdAt;
  final String? authorName;
  final String? acknowledgedByName;

  bool get isAcknowledged => acknowledgedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftHandover &&
          other.id == id &&
          other.siteId == siteId &&
          other.fromScheduleId == fromScheduleId &&
          other.authorId == authorId &&
          other.summary == summary &&
          other.assetStatus == assetStatus &&
          other.photoPath == photoPath &&
          other.acknowledgedBy == acknowledgedBy &&
          other.acknowledgedAt == acknowledgedAt &&
          other.clientEventId == clientEventId &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        siteId,
        fromScheduleId,
        authorId,
        summary,
        assetStatus,
        photoPath,
        acknowledgedBy,
        acknowledgedAt,
        clientEventId,
        createdAt,
      );
}
