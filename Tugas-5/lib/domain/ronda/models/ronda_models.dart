import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';

/// Peran Pengguna pada Ekosistem Ronda Digital (RBAC)
enum UserRole {
  adminRt,
  petugasRonda,
  warga;

  String get label {
    switch (this) {
      case UserRole.adminRt:
        return 'Ketua RT (Admin)';
      case UserRole.petugasRonda:
        return 'Petugas Ronda';
      case UserRole.warga:
        return 'Warga';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN_RT':
      case 'ADMINRT':
      case 'ADMIN':
        return UserRole.adminRt;
      case 'PETUGAS_RONDA':
      case 'PETUGAS':
        return UserRole.petugasRonda;
      case 'WARGA':
      default:
        return UserRole.warga;
    }
  }
}

/// Siklus Status Insiden Darurat (SOS Lifecycle)
enum EmergencyStatus {
  belumDitangani,
  onGoing,
  menungguVerifikasiRt,
  selesai;

  String get label {
    switch (this) {
      case EmergencyStatus.belumDitangani:
        return 'Belum Ditangani (Menunggu Respons)';
      case EmergencyStatus.onGoing:
        return 'Sedang Direspons Petugas';
      case EmergencyStatus.menungguVerifikasiRt:
        return 'Menunggu Verifikasi RT (Bukti Foto)';
      case EmergencyStatus.selesai:
        return 'Selesai / Tertangani';
    }
  }

  static EmergencyStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BELUM_DITANGANI':
      case 'BELUMDITANGANI':
      case 'ACTIVE':
        return EmergencyStatus.belumDitangani;
      case 'ON_GOING':
      case 'ONGOING':
        return EmergencyStatus.onGoing;
      case 'MENUNGGU_VERIFIKASI_RT':
      case 'MENUNGGUVERIFIKASIRT':
      case 'WAITING_RT':
        return EmergencyStatus.menungguVerifikasiRt;
      case 'SELESAI':
      case 'DONE':
      case 'RESOLVED':
      default:
        return EmergencyStatus.selesai;
    }
  }
}

/// Metode Penyelesaian Insiden Darurat
enum EmergencyResolutionType {
  qrWarga,
  fotoBukti;

  String get label {
    switch (this) {
      case EmergencyResolutionType.qrWarga:
        return 'Scan QR Warga Pelapor (Otomatis Selesai)';
      case EmergencyResolutionType.fotoBukti:
        return 'Foto Bukti Lapangan (Perlu Verifikasi RT)';
    }
  }

  static EmergencyResolutionType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'QR_WARGA':
      case 'QRWARGA':
        return EmergencyResolutionType.qrWarga;
      case 'FOTO_BUKTI':
      case 'FOTOBUKTI':
        return EmergencyResolutionType.fotoBukti;
      default:
        return null;
    }
  }
}

/// Kategori Insiden / Temuan Patroli & Laporan Warga
enum IncidentCategory {
  pencurian,
  kebakaran,
  keributan,
  orangMencurigakan,
  fasilitasRusak,
  lampuMati,
  sampah,
  lainnya;

  String get label {
    switch (this) {
      case IncidentCategory.pencurian:
        return 'Pencurian / Pembobolan';
      case IncidentCategory.kebakaran:
        return 'Kebakaran / Korsleting';
      case IncidentCategory.keributan:
        return 'Keributan / Gangguan Ketertiban';
      case IncidentCategory.orangMencurigakan:
        return 'Orang Mencurigakan';
      case IncidentCategory.fasilitasRusak:
        return 'Kerusakan Fasilitas Umum (Portal/Gapura/Jalan)';
      case IncidentCategory.lampuMati:
        return 'Lampu Jalan / Lingkungan Padam';
      case IncidentCategory.sampah:
        return 'Sampah Menumpuk / Saluran Tersumbat';
      case IncidentCategory.lainnya:
        return 'Lainnya / Keluhan Umum';
    }
  }
}

/// Status Pengajuan Pertukaran Jadwal (Shift Swap)
enum ShiftSwapStatus {
  pending,
  acceptedByTarget,
  rejected,
  approvedByAdmin;

  String get label {
    switch (this) {
      case ShiftSwapStatus.pending:
        return 'Menunggu Persetujuan Rekan';
      case ShiftSwapStatus.acceptedByTarget:
      case ShiftSwapStatus.approvedByAdmin:
        return 'Disetujui Bersama (Jadwal Resmi Berpindah)';
      case ShiftSwapStatus.rejected:
        return 'Ditolak Rekan';
    }
  }
}

/// Status Sinkronisasi Log Offline
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;
}

/// Entitas Pengguna Terenkripsi (RBAC)
class RondaUser {
  const RondaUser({
    required this.id,
    required this.rtId,
    required this.namaLengkap,
    required this.nomorWhatsapp,
    required this.alamatRumah,
    required this.role,
    this.fcmToken,
    this.passwordHash = '',
    this.salt = 'ronda_salt_its_kelompok_4',
  });

  final String id;
  final String rtId;
  final String namaLengkap;
  final String nomorWhatsapp;
  final String alamatRumah;
  final UserRole role;
  final String? fcmToken;
  final String passwordHash;
  final String salt;

  /// Algoritma Hashing SHA-256 Ber-Salt untuk Keamanan Kredensial
  static String hashPassword(String password, [String salt = 'ronda_salt_its_kelompok_4']) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  /// Verifikasi kecocokan sandi pengguna
  bool verifyPassword(String inputPassword) {
    if (passwordHash.isEmpty) return true; // Fallback jika belum di-hash
    final computed = hashPassword(inputPassword, salt);
    return computed == passwordHash;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'nama_lengkap': namaLengkap,
        'nomor_whatsapp': nomorWhatsapp,
        'alamat_rumah': alamatRumah,
        'role': role.name,
        'fcm_token': fcmToken,
        'password_hash': passwordHash,
        'salt': salt,
      };

  factory RondaUser.fromJson(Map<String, dynamic> json) => RondaUser(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        namaLengkap: json['nama_lengkap'] as String,
        nomorWhatsapp: json['nomor_whatsapp'] as String,
        alamatRumah: json['alamat_rumah'] as String,
        role: UserRole.fromString(json['role'] as String),
        fcmToken: json['fcm_token'] as String?,
        passwordHash: json['password_hash'] as String? ?? '',
        salt: json['salt'] as String? ?? 'ronda_salt_its_kelompok_4',
      );
}

/// Status Jadwal Patroli Pos Checkpoint
enum CheckpointScheduleStatus {
  sebelum,
  saat,
  terlewat,
  selesai;

  String get label {
    switch (this) {
      case CheckpointScheduleStatus.sebelum:
        return 'Mendatang (Persiapan)';
      case CheckpointScheduleStatus.saat:
        return 'WAKTUNYA CHECK-IN!';
      case CheckpointScheduleStatus.terlewat:
        return 'TERLEWAT (Belum Scan)';
      case CheckpointScheduleStatus.selesai:
        return 'Selesai Terverifikasi';
    }
  }
}

/// Entitas Titik Checkpoint Pos Patroli Fisik
class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.rtId,
    required this.kodeTitik,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    this.radiusMeter = 25.0,
    required this.secretKey,
    this.targetWaktuCheckin = '22:30',
    this.windowMenitSebelum = 15,
    this.windowMenitSetelah = 30,
  });

  final String id;
  final String rtId;
  final String kodeTitik;
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final double radiusMeter;
  final String secretKey;
  final String targetWaktuCheckin;
  final int windowMenitSebelum;
  final int windowMenitSetelah;

  LatLng get coordinates => LatLng(latitude, longitude);

  /// Menghitung status jadwal checkpoint relatif terhadap jam patroli saat ini
  CheckpointScheduleStatus calculateStatus({
    DateTime? currentTime,
    bool hasCheckedIn = false,
    String? customTargetTime,
  }) {
    if (hasCheckedIn) return CheckpointScheduleStatus.selesai;

    final now = currentTime ?? DateTime.now();
    final timeStr = customTargetTime ?? targetWaktuCheckin;
    final parts = timeStr.split(':');
    final targetHour = int.tryParse(parts[0]) ?? 22;
    final targetMinute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final targetDateTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
    final windowStart = targetDateTime.subtract(Duration(minutes: windowMenitSebelum));
    final windowEnd = targetDateTime.add(Duration(minutes: windowMenitSetelah));

    if (now.isBefore(windowStart)) {
      return CheckpointScheduleStatus.sebelum;
    } else if (now.isAfter(windowEnd)) {
      return CheckpointScheduleStatus.terlewat;
    } else {
      return CheckpointScheduleStatus.saat;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'kode_titik': kodeTitik,
        'nama_lokasi': namaLokasi,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meter': radiusMeter,
        'secret_key': secretKey,
        'target_waktu_checkin': targetWaktuCheckin,
        'window_menit_sebelum': windowMenitSebelum,
        'window_menit_setelah': windowMenitSetelah,
      };

  factory Checkpoint.fromJson(Map<String, dynamic> json) => Checkpoint(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        kodeTitik: json['kode_titik'] as String,
        namaLokasi: json['nama_lokasi'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeter: (json['radius_meter'] as num?)?.toDouble() ?? 25.0,
        secretKey: json['secret_key'] as String,
        targetWaktuCheckin: json['target_waktu_checkin'] as String? ?? '22:30',
        windowMenitSebelum: (json['window_menit_sebelum'] as num?)?.toInt() ?? 15,
        windowMenitSetelah: (json['window_menit_setelah'] as num?)?.toInt() ?? 30,
      );
}

/// Entitas Catatan Check-in Patroli Petugas
class PatrolCheckin {
  PatrolCheckin({
    required this.id,
    required this.checkpointId,
    required this.userId,
    required this.scannedAt,
    required this.latitudeUser,
    required this.longitudeUser,
    required this.distanceMeter,
    this.accuracy,
    this.batteryLevel,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final String checkpointId;
  final String userId;
  final DateTime scannedAt;
  final double latitudeUser;
  final double longitudeUser;
  final double distanceMeter;
  final double? accuracy;
  final double? batteryLevel;
  SyncStatus syncStatus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'checkpoint_id': checkpointId,
        'user_id': userId,
        'scanned_at': scannedAt.toIso8601String(),
        'latitude_user': latitudeUser,
        'longitude_user': longitudeUser,
        'distance_meter': distanceMeter,
        'accuracy': accuracy,
        'battery_level': batteryLevel,
        'sync_status': syncStatus.name,
      };

  factory PatrolCheckin.fromJson(Map<String, dynamic> json) => PatrolCheckin(
        id: json['id'] as String,
        checkpointId: json['checkpoint_id'] as String,
        userId: json['user_id'] as String,
        scannedAt: DateTime.parse(json['scanned_at'] as String),
        latitudeUser: (json['latitude_user'] as num).toDouble(),
        longitudeUser: (json['longitude_user'] as num).toDouble(),
        distanceMeter: (json['distance_meter'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        batteryLevel: (json['battery_level'] as num?)?.toDouble(),
        syncStatus: SyncStatus.values.firstWhere(
          (s) => s.name == json['sync_status'],
          orElse: () => SyncStatus.synced,
        ),
      );
}

/// Entitas Jadwal Ronda Petugas
class PatrolSchedule {
  PatrolSchedule({
    required this.id,
    required this.rtId,
    required this.userId,
    required this.petugasName,
    required this.tanggalRonda,
    this.shiftName = 'Shift Malam (22:00 - 04:00)',
    this.jamMulai = '22:00',
    this.jamSelesai = '04:00',
    this.isCompleted = false,
    this.isLibur = false,
  });

  final String id;
  final String rtId;
  String userId;
  String petugasName;
  final DateTime tanggalRonda;
  final String shiftName;
  final String jamMulai;
  final String jamSelesai;
  bool isCompleted;
  bool isLibur;

  /// Memeriksa apakah waktu tertentu berada dalam rentang shift ini
  bool isTimeInShift(DateTime time) {
    if (isLibur) return false;
    final startParts = jamMulai.split(':');
    final endParts = jamSelesai.split(':');
    final sH = int.tryParse(startParts[0]) ?? 22;
    final sM = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;
    final eH = int.tryParse(endParts[0]) ?? 4;
    final eM = int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0;

    final startMinutes = sH * 60 + sM;
    final endMinutes = eH * 60 + eM;
    final currentMinutes = time.hour * 60 + time.minute;

    if (startMinutes <= endMinutes) {
      // Shift normal dalam 1 hari kalender (misal 16:00 - 22:00 atau 08:00 - 16:00)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Shift malam melintasi tengah malam (misal 22:00 - 04:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// Menghasilkan target jam checkpoint proporsional khusus shift ini
  String getTargetTimeForCheckpoint(int cpIndex, int totalCheckpoints) {
    final startParts = jamMulai.split(':');
    final endParts = jamSelesai.split(':');
    final sH = int.tryParse(startParts[0]) ?? 22;
    final sM = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;
    var eH = int.tryParse(endParts[0]) ?? 4;
    final eM = int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0;
    if (eH <= sH) eH += 24;

    final startMin = sH * 60 + sM;
    final endMin = eH * 60 + eM;
    final duration = endMin - startMin;

    final offsetMin = startMin + ((duration * (cpIndex + 1)) ~/ (totalCheckpoints + 1));
    final normalizedHour = (offsetMin ~/ 60) % 24;
    final normalizedMin = offsetMin % 60;
    return '${normalizedHour.toString().padLeft(2, '0')}:${normalizedMin.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'user_id': userId,
        'petugas_name': petugasName,
        'tanggal_ronda': tanggalRonda.toIso8601String(),
        'shift_name': shiftName,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'is_completed': isCompleted,
        'is_libur': isLibur,
      };

  factory PatrolSchedule.fromJson(Map<String, dynamic> json) => PatrolSchedule(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        userId: json['user_id'] as String,
        petugasName: json['petugas_name'] as String,
        tanggalRonda: DateTime.parse(json['tanggal_ronda'] as String),
        shiftName: json['shift_name'] as String? ?? 'Shift Malam (22:00 - 04:00)',
        jamMulai: json['jam_mulai'] as String? ?? '22:00',
        jamSelesai: json['jam_selesai'] as String? ?? '04:00',
        isCompleted: json['is_completed'] as bool? ?? false,
        isLibur: json['is_libur'] as bool? ?? false,
      );
}

/// Entitas Permintaan Pertukaran Shift Ronda
class ShiftSwapRequest {
  ShiftSwapRequest({
    required this.id,
    required this.scheduleId,
    required this.requesterId,
    required this.requesterName,
    required this.targetUserId,
    required this.targetUserName,
    required this.alasan,
    this.requesterShift = 'Shift Malam',
    this.targetDate,
    this.targetShift = 'Shift Malam',
    this.status = ShiftSwapStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String scheduleId;
  final String requesterId;
  final String requesterName;
  final String targetUserId;
  final String targetUserName;
  final String alasan;
  final String requesterShift;
  final DateTime? targetDate;
  final String targetShift;
  ShiftSwapStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_id': scheduleId,
        'requester_id': requesterId,
        'requester_name': requesterName,
        'target_user_id': targetUserId,
        'target_user_name': targetUserName,
        'alasan': alasan,
        'requester_shift': requesterShift,
        'target_date': targetDate?.toIso8601String(),
        'target_shift': targetShift,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShiftSwapRequest.fromJson(Map<String, dynamic> json) => ShiftSwapRequest(
        id: json['id'] as String,
        scheduleId: json['schedule_id'] as String,
        requesterId: json['requester_id'] as String,
        requesterName: json['requester_name'] as String,
        targetUserId: json['target_user_id'] as String,
        targetUserName: json['target_user_name'] as String,
        alasan: json['alasan'] as String,
        requesterShift: json['requester_shift'] as String? ?? 'Shift Malam',
        targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
        targetShift: json['target_shift'] as String? ?? 'Shift Malam',
        status: ShiftSwapStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ShiftSwapStatus.pending,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Tipe Notifikasi Ekosistem Ronda Digital
enum RondaNotificationType {
  sosEmergency,
  checkpointReminder,
  scheduleUpdate,
  systemAlert;
}

/// Entitas Notifikasi Internal Sistem
class RondaNotification {
  const RondaNotification({
    required this.id,
    required this.rtId,
    required this.title,
    required this.body,
    required this.type,
    this.targetUserId,
    this.includeOffDuty = false,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String rtId;
  final String title;
  final String body;
  final RondaNotificationType type;
  final String? targetUserId;
  final bool includeOffDuty;
  final DateTime createdAt;
  final bool isRead;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'title': title,
        'body': body,
        'type': type.name,
        'target_user_id': targetUserId,
        'include_off_duty': includeOffDuty,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  factory RondaNotification.fromJson(Map<String, dynamic> json) => RondaNotification(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: RondaNotificationType.values.firstWhere((t) => t.name == json['type']),
        targetUserId: json['target_user_id'] as String?,
        includeOffDuty: json['include_off_duty'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );
}

/// Entitas Notifikasi & Kejadian Darurat (SOS) dengan Siklus Multi-Status
class EmergencyEvent {
  EmergencyEvent({
    required this.id,
    required this.rtId,
    required this.userId,
    required this.userName,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
    this.catatan,
    this.status = EmergencyStatus.belumDitangani,
    required this.triggeredAt,
    this.respondedAt,
    this.respondedByUserId,
    this.respondedByUserName,
    this.resolvedAt,
    this.resolvedVia,
    this.resolutionPhotoPath,
    this.resolutionNotes,
    String? verificationQrToken,
    this.verifiedByAdminId,
    this.adminNotes,
  }) : verificationQrToken = verificationQrToken ?? 'QR-SOS-VERIFY-$id-$userId';

  final String id;
  final String rtId;
  final String userId;
  final String userName;
  final String userAddress;
  final double latitude;
  final double longitude;
  final String? catatan;
  EmergencyStatus status;
  final DateTime triggeredAt;
  DateTime? respondedAt;
  String? respondedByUserId;
  String? respondedByUserName;
  DateTime? resolvedAt;
  EmergencyResolutionType? resolvedVia;
  String? resolutionPhotoPath;
  String? resolutionNotes;
  final String verificationQrToken;
  String? verifiedByAdminId;
  String? adminNotes;

  bool get isActive => status != EmergencyStatus.selesai;
  bool get isBelumDitangani => status == EmergencyStatus.belumDitangani;
  bool get isOnGoing => status == EmergencyStatus.onGoing;
  bool get isMenungguVerifikasiRt => status == EmergencyStatus.menungguVerifikasiRt;
  bool get isSelesai => status == EmergencyStatus.selesai;

  Duration? get durationToResolve => resolvedAt?.difference(triggeredAt);
  Duration? get durationToRespond => respondedAt?.difference(triggeredAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'user_id': userId,
        'user_name': userName,
        'user_address': userAddress,
        'latitude': latitude,
        'longitude': longitude,
        'catatan': catatan,
        'status': status.name,
        'triggered_at': triggeredAt.toIso8601String(),
        'responded_at': respondedAt?.toIso8601String(),
        'responded_by_user_id': respondedByUserId,
        'responded_by_user_name': respondedByUserName,
        'resolved_at': resolvedAt?.toIso8601String(),
        'resolved_via': resolvedVia?.name,
        'resolution_photo_path': resolutionPhotoPath,
        'resolution_notes': resolutionNotes,
        'verification_qr_token': verificationQrToken,
        'verified_by_admin_id': verifiedByAdminId,
        'admin_notes': adminNotes,
      };

  factory EmergencyEvent.fromJson(Map<String, dynamic> json) => EmergencyEvent(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        userId: json['user_id'] as String,
        userName: json['user_name'] as String,
        userAddress: json['user_address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        catatan: json['catatan'] as String?,
        status: EmergencyStatus.fromString(json['status'] as String? ?? 'BELUM_DITANGANI'),
        triggeredAt: DateTime.parse(json['triggered_at'] as String),
        respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at'] as String) : null,
        respondedByUserId: json['responded_by_user_id'] as String?,
        respondedByUserName: json['responded_by_user_name'] as String?,
        resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
        resolvedVia: EmergencyResolutionType.fromString(json['resolved_via'] as String?),
        resolutionPhotoPath: json['resolution_photo_path'] as String?,
        resolutionNotes: json['resolution_notes'] as String?,
        verificationQrToken: json['verification_qr_token'] as String?,
        verifiedByAdminId: json['verified_by_admin_id'] as String?,
        adminNotes: json['admin_notes'] as String?,
      );
}

/// Entitas Laporan Insiden Berfoto
class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.rtId,
    required this.userId,
    required this.reporterName,
    required this.category,
    required this.keterangan,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    this.compass,
    required this.createdAt,
  });

  final String id;
  final String rtId;
  final String userId;
  final String reporterName;
  final IncidentCategory category;
  final String keterangan;
  final String photoPath;
  final double latitude;
  final double longitude;
  final double? compass;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'user_id': userId,
        'reporter_name': reporterName,
        'category': category.name,
        'keterangan': keterangan,
        'photo_path': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'compass': compass,
        'created_at': createdAt.toIso8601String(),
      };

  factory IncidentReport.fromJson(Map<String, dynamic> json) => IncidentReport(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        userId: json['user_id'] as String,
        reporterName: json['reporter_name'] as String,
        category: IncidentCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => IncidentCategory.lainnya,
        ),
        keterangan: json['keterangan'] as String,
        photoPath: json['photo_path'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        compass: (json['compass'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
