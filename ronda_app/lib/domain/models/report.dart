import 'package:ronda_app/domain/models/enums.dart';

/// Domain entity for `incident_reports` (non-SOS security and facility reports).
class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.siteId,
    required this.reporterId,
    required this.category,
    required this.title,
    required this.description,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.clientEventId,
    this.handledBy,
    this.resolutionNote,
    this.reporterName,
    this.handledByName,
  });

  final String id;
  final String? clientEventId;
  final String siteId;
  final String reporterId;
  final IncidentCategory category;
  final String title;
  final String description;
  final String photoPath;
  final double latitude;
  final double longitude;
  final IncidentStatus status;
  final String? handledBy;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reporterName;
  final String? handledByName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentReport &&
          other.id == id &&
          other.clientEventId == clientEventId &&
          other.siteId == siteId &&
          other.reporterId == reporterId &&
          other.category == category &&
          other.title == title &&
          other.description == description &&
          other.photoPath == photoPath &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.status == status &&
          other.handledBy == handledBy &&
          other.resolutionNote == resolutionNote &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        clientEventId,
        siteId,
        reporterId,
        category,
        title,
        description,
        photoPath,
        latitude,
        longitude,
        status,
        handledBy,
        resolutionNote,
        createdAt,
        updatedAt,
      );
}

/// Filter options for non-SOS incident report streams.
class IncidentReportFilter {
  const IncidentReportFilter({
    this.status,
    this.category,
  });

  final IncidentStatus? status;
  final IncidentCategory? category;
}

/// Domain entity for `empty_house_watches` (Lapor Mudik / Rumah Kosong).
class EmptyHouseWatch {
  const EmptyHouseWatch({
    required this.id,
    required this.siteId,
    required this.residentId,
    required this.houseLabel,
    required this.latitude,
    required this.longitude,
    required this.startDate,
    required this.endDate,
    required this.emergencyContact,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.residentName,
  });

  final String id;
  final String siteId;
  final String residentId;
  final String houseLabel;
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime endDate;
  final String emergencyContact;
  final String notes;
  final EmptyHouseStatus status;
  final DateTime createdAt;
  final String? residentName;

  bool isActiveOnDate(DateTime date) {
    if (status != EmptyHouseStatus.active) {
      return false;
    }
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptyHouseWatch &&
          other.id == id &&
          other.siteId == siteId &&
          other.residentId == residentId &&
          other.houseLabel == houseLabel &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.emergencyContact == emergencyContact &&
          other.notes == notes &&
          other.status == status &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        siteId,
        residentId,
        houseLabel,
        latitude,
        longitude,
        startDate,
        endDate,
        emergencyContact,
        notes,
        status,
        createdAt,
      );
}
