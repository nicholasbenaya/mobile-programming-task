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

/// Kategori Insiden / Temuan Patroli
enum IncidentCategory {
  pencurian,
  kebakaran,
  keributan,
  orangMencurigakan,
  fasilitasRusak,
  lainnya;

  String get label {
    switch (this) {
      case IncidentCategory.pencurian:
        return 'Pencurian / Pembobolan';
      case IncidentCategory.kebakaran:
        return 'Kebakaran / Korsleting';
      case IncidentCategory.keributan:
        return 'Keributan / Tawuran';
      case IncidentCategory.orangMencurigakan:
        return 'Orang Mencurigakan';
      case IncidentCategory.fasilitasRusak:
        return 'Kerusakan Fasilitas Umum';
      case IncidentCategory.lainnya:
        return 'Lainnya';
    }
  }
}

/// Status Pengajuan Pertukaran Jadwal (Shift Swap State Machine)
enum ShiftSwapStatus {
  pending,
  acceptedByTarget,
  rejected,
  approvedByAdmin;

  String get label {
    switch (this) {
      case ShiftSwapStatus.pending:
        return 'Menunggu Persetujuan Pengganti';
      case ShiftSwapStatus.acceptedByTarget:
        return 'Disetujui Pengganti (Menunggu Ketua RT)';
      case ShiftSwapStatus.rejected:
        return 'Ditolak';
      case ShiftSwapStatus.approvedByAdmin:
        return 'Resmi Disetujui (Jadwal Berpindah)';
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
  });

  final String id;
  final String rtId;
  final String kodeTitik;
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final double radiusMeter;
  final String secretKey;

  LatLng get coordinates => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'kode_titik': kodeTitik,
        'nama_lokasi': namaLokasi,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meter': radiusMeter,
        'secret_key': secretKey,
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
    this.jamMulai = '22:00',
    this.jamSelesai = '04:00',
    this.isCompleted = false,
  });

  final String id;
  final String rtId;
  String userId;
  String petugasName;
  final DateTime tanggalRonda;
  final String jamMulai;
  final String jamSelesai;
  bool isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rt_id': rtId,
        'user_id': userId,
        'petugas_name': petugasName,
        'tanggal_ronda': tanggalRonda.toIso8601String(),
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'is_completed': isCompleted,
      };

  factory PatrolSchedule.fromJson(Map<String, dynamic> json) => PatrolSchedule(
        id: json['id'] as String,
        rtId: json['rt_id'] as String,
        userId: json['user_id'] as String,
        petugasName: json['petugas_name'] as String,
        tanggalRonda: DateTime.parse(json['tanggal_ronda'] as String),
        jamMulai: json['jam_mulai'] as String? ?? '22:00',
        jamSelesai: json['jam_selesai'] as String? ?? '04:00',
        isCompleted: json['is_completed'] as bool? ?? false,
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
        status: ShiftSwapStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ShiftSwapStatus.pending,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
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
