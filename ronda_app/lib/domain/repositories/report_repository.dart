import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/report.dart';

/// Contract for non-SOS security/facility incident reports and privacy-scoped empty house watches.
abstract interface class ReportRepository {
  Stream<List<IncidentReport>> watchIncidentReports({
    required String siteId,
    IncidentReportFilter filter = const IncidentReportFilter(),
  });

  Future<IncidentReport> submitIncidentReport({
    required String siteId,
    required IncidentCategory category,
    required String title,
    required String description,
    required String localPhotoPath,
    required double latitude,
    required double longitude,
    String? clientEventId,
  });

  Future<IncidentReport> updateReportStatus({
    required String reportId,
    required IncidentStatus status,
    String? resolutionNote,
  });

  Stream<List<EmptyHouseWatch>> watchEmptyHouseWatches(String siteId);

  Future<EmptyHouseWatch> createEmptyHouseWatch({
    required String siteId,
    required String houseLabel,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required String emergencyContact,
    String notes = '',
  });

  Future<EmptyHouseWatch> markResidentReturned(String watchId);

  Future<EmptyHouseWatch> cancelEmptyHouseWatch(String watchId);
}
