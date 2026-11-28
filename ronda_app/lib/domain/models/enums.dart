/// Domain enums aligned 1:1 with PostgreSQL CHECK constraints.
enum SiteType {
  desa('desa'),
  perumahan('perumahan'),
  rtRw('rt_rw'),
  klaster('klaster'),
  fasilitas('fasilitas'),
  lainnya('lainnya');

  const SiteType(this.value);
  final String value;

  static SiteType fromValue(String raw) => SiteType.values.firstWhere(
        (e) => e.value == raw,
        orElse: () => throw FormatException('Jenis wilayah tidak dikenali: $raw'),
      );
}

enum SiteRole {
  admin('admin'),
  officer('officer'),
  resident('resident');

  const SiteRole(this.value);
  final String value;

  bool get isStaff => this == SiteRole.admin || this == SiteRole.officer;

  static SiteRole fromValue(String raw) => SiteRole.values.firstWhere(
        (e) => e.value == raw,
        orElse: () => throw FormatException('Peran wilayah tidak dikenali: $raw'),
      );
}

enum MembershipStatus {
  pending('pending'),
  active('active'),
  suspended('suspended');

  const MembershipStatus(this.value);
  final String value;

  static MembershipStatus fromValue(String raw) =>
      MembershipStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status keanggotaan tidak dikenali: $raw'),
      );
}

enum ScheduleStatus {
  scheduled('scheduled'),
  completed('completed'),
  absent('absent'),
  swapped('swapped');

  const ScheduleStatus(this.value);
  final String value;

  bool get countsForCollision =>
      this == ScheduleStatus.scheduled || this == ScheduleStatus.completed;

  static ScheduleStatus fromValue(String raw) => ScheduleStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status jadwal tidak dikenali: $raw'),
      );
}

enum SwapStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired'),
  adminOverridden('admin_overridden');

  const SwapStatus(this.value);
  final String value;

  static SwapStatus fromValue(String raw) => SwapStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status tukar shift tidak dikenali: $raw'),
      );
}

enum AutoVerificationStatus {
  autoVerified('auto_verified'),
  flaggedReview('flagged_review'),
  autoRejected('auto_rejected');

  const AutoVerificationStatus(this.value);
  final String value;

  static AutoVerificationStatus fromValue(String raw) =>
      AutoVerificationStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status otomatis tidak dikenali: $raw'),
      );
}

enum ManualReviewStatus {
  manualApproved('manual_approved'),
  manualRejected('manual_rejected');

  const ManualReviewStatus(this.value);
  final String value;

  static ManualReviewStatus fromValue(String raw) =>
      ManualReviewStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status audit manual tidak dikenali: $raw'),
      );
}

enum EffectiveCheckinStatus {
  autoVerified('auto_verified'),
  flaggedReview('flagged_review'),
  autoRejected('auto_rejected'),
  manualApproved('manual_approved'),
  manualRejected('manual_rejected');

  const EffectiveCheckinStatus(this.value);
  final String value;

  bool get isApproved =>
      this == EffectiveCheckinStatus.autoVerified ||
      this == EffectiveCheckinStatus.manualApproved;

  bool get needsReview => this == EffectiveCheckinStatus.flaggedReview;

  bool get isRejected =>
      this == EffectiveCheckinStatus.autoRejected ||
      this == EffectiveCheckinStatus.manualRejected;

  static EffectiveCheckinStatus resolve({
    required AutoVerificationStatus autoStatus,
    ManualReviewStatus? manualStatus,
  }) {
    if (manualStatus != null) {
      return switch (manualStatus) {
        ManualReviewStatus.manualApproved =>
          EffectiveCheckinStatus.manualApproved,
        ManualReviewStatus.manualRejected =>
          EffectiveCheckinStatus.manualRejected,
      };
    }
    return switch (autoStatus) {
      AutoVerificationStatus.autoVerified =>
        EffectiveCheckinStatus.autoVerified,
      AutoVerificationStatus.flaggedReview =>
        EffectiveCheckinStatus.flaggedReview,
      AutoVerificationStatus.autoRejected =>
        EffectiveCheckinStatus.autoRejected,
    };
  }

  static EffectiveCheckinStatus fromValue(String raw) =>
      EffectiveCheckinStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status efektif check-in tidak dikenali: $raw'),
      );
}

enum CheckinFlagReason {
  qrInvalidOrRevoked('QR_INVALID_OR_REVOKED', isHardFail: true),
  mockGpsDetected('MOCK_GPS_DETECTED', isHardFail: true),
  outsideGeofenceExtreme('OUTSIDE_GEOFENCE_EXTREME', isHardFail: true),
  outsideGeofenceBorderline('OUTSIDE_GEOFENCE_BORDERLINE', isHardFail: false),
  lowGpsAccuracy('LOW_GPS_ACCURACY', isHardFail: false),
  outsideShiftWindow('OUTSIDE_SHIFT_WINDOW', isHardFail: false),
  offlineDelayOrClockSkew('OFFLINE_DELAY_OR_CLOCK_SKEW', isHardFail: false),
  photoHashMissingOrMismatch('PHOTO_HASH_MISSING_OR_MISMATCH', isHardFail: true);

  const CheckinFlagReason(this.value, {required this.isHardFail});
  final String value;
  final bool isHardFail;

  static CheckinFlagReason fromValue(String raw) =>
      CheckinFlagReason.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Kode alasan flag tidak dikenali: $raw'),
      );
}

enum AuditAction {
  autoEvaluated('auto_evaluated'),
  manualApproved('manual_approved'),
  manualRejected('manual_rejected');

  const AuditAction(this.value);
  final String value;

  static AuditAction fromValue(String raw) => AuditAction.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Aksi audit tidak dikenali: $raw'),
      );
}

enum SosCategory {
  pencurian('pencurian'),
  kebakaran('kebakaran'),
  medis('medis'),
  orangMencurigakan('orang_mencurigakan'),
  darurat('darurat');

  const SosCategory(this.value);
  final String value;

  static SosCategory fromValue(String raw) => SosCategory.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Kategori SOS tidak dikenali: $raw'),
      );
}

enum SosStatus {
  open('open'),
  acknowledged('acknowledged'),
  onScene('on_scene'),
  resolved('resolved'),
  cancelledFalseAlarm('cancelled_false_alarm');

  const SosStatus(this.value);
  final String value;

  bool get isActive =>
      this == SosStatus.open ||
      this == SosStatus.acknowledged ||
      this == SosStatus.onScene;

  static SosStatus fromValue(String raw) => SosStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () => throw FormatException('Status SOS tidak dikenali: $raw'),
      );
}

enum IncidentCategory {
  orangMencurigakan('orang_mencurigakan'),
  kerusakanFasilitas('kerusakan_fasilitas'),
  lampuMati('lampu_mati'),
  vandalisme('vandalisme'),
  kebersihan('kebersihan'),
  lainnya('lainnya');

  const IncidentCategory(this.value);
  final String value;

  static IncidentCategory fromValue(String raw) =>
      IncidentCategory.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Kategori laporan tidak dikenali: $raw'),
      );
}

enum IncidentStatus {
  open('open'),
  inProgress('in_progress'),
  resolved('resolved'),
  rejected('rejected');

  const IncidentStatus(this.value);
  final String value;

  static IncidentStatus fromValue(String raw) =>
      IncidentStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status laporan tidak dikenali: $raw'),
      );
}

enum EmptyHouseStatus {
  active('active'),
  returned('returned'),
  cancelled('cancelled');

  const EmptyHouseStatus(this.value);
  final String value;

  static EmptyHouseStatus fromValue(String raw) =>
      EmptyHouseStatus.values.firstWhere(
        (e) => e.value == raw,
        orElse: () => throw FormatException(
          'Status lapor rumah kosong tidak dikenali: $raw',
        ),
      );
}

enum DevicePlatform {
  android('android'),
  ios('ios');

  const DevicePlatform(this.value);
  final String value;

  static DevicePlatform fromValue(String raw) =>
      DevicePlatform.values.firstWhere(
        (e) => e.value == raw,
        orElse: () => throw FormatException('Platform perangkat tidak dikenali: $raw'),
      );
}

enum OfflineSyncState {
  pending('pending'),
  uploadingPhoto('uploading_photo'),
  submitting('submitting'),
  synced('synced'),
  failed('failed');

  const OfflineSyncState(this.value);
  final String value;

  static OfflineSyncState fromValue(String raw) =>
      OfflineSyncState.values.firstWhere(
        (e) => e.value == raw,
        orElse: () =>
            throw FormatException('Status sinkronisasi tidak dikenali: $raw'),
      );
}
