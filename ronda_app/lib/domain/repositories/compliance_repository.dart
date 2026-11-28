import 'package:ronda_app/domain/models/compliance.dart';

/// Contract for real persisted compliance analytics and monthly CSV/PDF export.
abstract interface class ComplianceRepository {
  Future<MonthlyComplianceSummary> fetchMonthlySummary({
    required String siteId,
    required int year,
    required int month,
  });

  Future<ExportFileResult> exportCheckinsCsv({
    required String siteId,
    required int year,
    required int month,
  });

  Future<ExportFileResult> exportMonthlySummaryPdf({
    required String siteId,
    required int year,
    required int month,
  });
}
