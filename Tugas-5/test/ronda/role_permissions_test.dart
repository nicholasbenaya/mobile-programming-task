import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/models/ronda_models.dart';
import 'package:ronda_digital/domain/ronda/services/role_permissions.dart';

void main() {
  group('RolePermissions Tests (RBAC)', () {
    test('Admin RT memiliki akses penuh manajerial', () {
      const role = UserRole.adminRt;

      expect(RolePermissions.canManageSchedule(role), isTrue);
      expect(RolePermissions.canScanCheckpoint(role), isTrue);
      expect(RolePermissions.canTriggerSos(role), isTrue);
      expect(RolePermissions.canReportIncident(role), isTrue);
      expect(RolePermissions.canRequestShiftSwap(role), isTrue);
      expect(RolePermissions.canApproveShiftSwap(role), isTrue);
      expect(RolePermissions.canManageCheckpoints(role), isTrue);
      expect(RolePermissions.canExportReports(role), isTrue);
    });

    test('Petugas Ronda berwenang patroli dan tukar shift, tetapi tidak mengesahkan', () {
      const role = UserRole.petugasRonda;

      expect(RolePermissions.canManageSchedule(role), isFalse);
      expect(RolePermissions.canScanCheckpoint(role), isTrue);
      expect(RolePermissions.canTriggerSos(role), isTrue);
      expect(RolePermissions.canReportIncident(role), isTrue);
      expect(RolePermissions.canRequestShiftSwap(role), isTrue);
      expect(RolePermissions.canApproveShiftSwap(role), isFalse);
      expect(RolePermissions.canManageCheckpoints(role), isFalse);
      expect(RolePermissions.canExportReports(role), isFalse);
    });

    test('Warga biasa memiliki akses proteksi SOS dan laporan insiden', () {
      const role = UserRole.warga;

      expect(RolePermissions.canManageSchedule(role), isFalse);
      expect(RolePermissions.canScanCheckpoint(role), isFalse);
      expect(RolePermissions.canTriggerSos(role), isTrue);
      expect(RolePermissions.canReportIncident(role), isTrue);
      expect(RolePermissions.canRequestShiftSwap(role), isFalse);
      expect(RolePermissions.canApproveShiftSwap(role), isFalse);
      expect(RolePermissions.canManageCheckpoints(role), isFalse);
      expect(RolePermissions.canExportReports(role), isFalse);
    });
  });
}
