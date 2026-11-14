import '../models/ronda_models.dart';

/// Mesin Otorisasi Hak Akses Berbasis Peran (RBAC)
class RolePermissions {
  const RolePermissions._();

  /// Apakah peran ini boleh membuat dan mengatur jadwal ronda?
  static bool canManageSchedule(UserRole role) => role == UserRole.adminRt;

  /// Apakah peran ini berwenang memindai QR checkpoint pos ronda?
  static bool canScanCheckpoint(UserRole role) =>
      role == UserRole.adminRt || role == UserRole.petugasRonda;

  /// Apakah peran ini berhak menekan tombol panik darurat SOS?
  static bool canTriggerSos(UserRole role) => true; // Seluruh warga berhak dilindungi

  /// Apakah peran ini berwenang melaporkan insiden/kejadian lingkungan?
  static bool canReportIncident(UserRole role) => true;

  /// Apakah peran ini boleh mengajukan pertukaran jadwal ronda?
  static bool canRequestShiftSwap(UserRole role) =>
      role == UserRole.petugasRonda || role == UserRole.adminRt;

  /// Apakah peran ini berwenang memberikan persetujuan final tukar jadwal?
  static bool canApproveShiftSwap(UserRole role) => role == UserRole.adminRt;

  /// Apakah peran ini berhak menambah atau mengedit titik checkpoint QR pos ronda?
  static bool canManageCheckpoints(UserRole role) => role == UserRole.adminRt;

  /// Apakah peran ini berhak mengekspor rekapitulasi kehadiran dan log insiden (CSV)?
  static bool canExportReports(UserRole role) => role == UserRole.adminRt;
}
