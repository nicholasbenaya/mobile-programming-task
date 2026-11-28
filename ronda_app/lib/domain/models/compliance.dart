import 'dart:typed_data';

/// Aggregated compliance metrics computed strictly from real persisted site records.
class MonthlyComplianceSummary {
  const MonthlyComplianceSummary({
    required this.siteId,
    required this.year,
    required this.month,
    required this.totalScheduledShifts,
    required this.completedShifts,
    required this.totalCheckins,
    required this.verifiedCheckins,
    required this.flaggedCheckins,
    required this.rejectedCheckins,
    required this.manualApprovedOverrides,
    required this.manualRejectedOverrides,
    required this.openIncidentReports,
    required this.resolvedIncidentReports,
    required this.totalSosEvents,
    required this.officerStats,
    this.medianSosResponseSeconds,
    this.averageSosResponseSeconds,
  });

  final String siteId;
  final int year;
  final int month;
  final int totalScheduledShifts;
  final int completedShifts;
  final int totalCheckins;
  final int verifiedCheckins;
  final int flaggedCheckins;
  final int rejectedCheckins;
  final int manualApprovedOverrides;
  final int manualRejectedOverrides;
  final int openIncidentReports;
  final int resolvedIncidentReports;
  final int totalSosEvents;
  final double? medianSosResponseSeconds;
  final double? averageSosResponseSeconds;
  final List<OfficerComplianceStat> officerStats;

  double? get shiftCompletionRate {
    if (totalScheduledShifts == 0) {
      return null;
    }
    return completedShifts / totalScheduledShifts;
  }

  int get pendingAuditCount => flaggedCheckins;
}

/// Per-officer monthly breakdown used in compliance dashboard and PDF exports.
class OfficerComplianceStat {
  const OfficerComplianceStat({
    required this.officerId,
    required this.officerName,
    required this.scheduledShifts,
    required this.verifiedCheckins,
    required this.flaggedCheckins,
    required this.rejectedCheckins,
  });

  final String officerId;
  final String officerName;
  final int scheduledShifts;
  final int verifiedCheckins;
  final int flaggedCheckins;
  final int rejectedCheckins;
}

/// In-memory exported CSV or PDF file ready to save or pass to OS share sheet.
class ExportFileResult {
  const ExportFileResult({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}
