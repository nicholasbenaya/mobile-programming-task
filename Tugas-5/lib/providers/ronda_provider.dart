import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/mock/mock_backend.dart';
import '../data/mock/seed_data.dart';
import '../data/services/supabase_ronda_service.dart';
import '../domain/ronda/models/ronda_models.dart';
import '../domain/ronda/services/haversine_calculator.dart';
import '../domain/ronda/services/offline_sync_queue.dart';
import '../domain/ronda/services/qr_token_verifier.dart';

/// Provider Utama untuk Mengelola State Interaktif Ronda Digital di UI
/// Terkoneksi secara otomatis ke Cloud Supabase dengan Realtime Streaming
/// dan Fallback Aman ke Mock Backend jika Offline / Blank Spot.
class RondaProvider extends ChangeNotifier {
  RondaProvider({SupabaseRondaService? supabaseService, MockBackend? backend}) {
    _backend = backend ?? MockBackend();
    _supabase = supabaseService ?? SupabaseRondaService();
    _offlineQueue = OfflineSyncQueue();
    // Default state awal: Pengguna belum login untuk menjamin keamanan kredensial
    _currentUser = null;
    _checkpoints = SeedData.checkpoints;
  }

  late final MockBackend _backend;
  late final SupabaseRondaService _supabase;
  late final OfflineSyncQueue _offlineQueue;
  RondaUser? _currentUser;
  late List<Checkpoint> _checkpoints;
  final List<RondaUser> _cloudUsers = [];

  StreamSubscription<List<EmergencyEvent>>? _emergencySub;
  StreamSubscription<List<PatrolCheckin>>? _checkinSub;
  StreamSubscription<List<ShiftSwapRequest>>? _swapSub;
  StreamSubscription<List<PatrolSchedule>>? _scheduleSub;
  StreamSubscription<List<RondaNotification>>? _notifSub;

  Position? _currentGpsPosition;
  bool _isOfflineMode = false;
  bool _isManualDutyActive = false;
  bool _isLoadingGps = false;
  String? _lastErrorMessage;
  String? _lastSuccessMessage;

  // Getters Keamanan & Autentikasi
  bool get isAuthenticated => _currentUser != null;
  RondaUser? get currentUser => _currentUser;
  bool get isCloudConnected => _supabase.isAvailable;
  List<RondaUser> get availableUsers =>
      _cloudUsers.isNotEmpty ? _cloudUsers : SeedData.allUsers;
  List<Checkpoint> get checkpoints => _checkpoints;
  OfflineSyncQueue get offlineQueue => _offlineQueue;
  Position? get currentGpsPosition => _currentGpsPosition;
  bool get isOfflineMode => _isOfflineMode;
  bool get isManualDutyActive => _isManualDutyActive;
  bool get isLoadingGps => _isLoadingGps;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastSuccessMessage => _lastSuccessMessage;

  List<PatrolSchedule> get schedules =>
      _currentUser != null ? _backend.getSchedules(_currentUser!.rtId) : [];
  List<PatrolCheckin> get patrolLogs => _backend.patrolLogs;
  List<IncidentReport> get incidents => _backend.incidents;
  List<ShiftSwapRequest> get shiftSwaps => _backend.shiftSwaps;
  List<EmergencyEvent> get emergencyEvents => _backend.emergencyEvents;
  List<EmergencyEvent> get resolvedEmergencies => _backend.resolvedEmergencies;
  List<RondaNotification> get notifications => _backend.notifications;

  /// Permintaan tukar jadwal yang masuk (ditujukan kepada saya & masih pending)
  List<ShiftSwapRequest> get myIncomingSwapRequests {
    if (_currentUser == null) return [];
    return shiftSwaps
        .where((s) =>
            s.targetUserId == _currentUser!.id &&
            s.status == ShiftSwapStatus.pending)
        .toList();
  }

  /// Permintaan tukar jadwal yang diajukan oleh saya
  List<ShiftSwapRequest> get myOutgoingSwapRequests {
    if (_currentUser == null) return [];
    return shiftSwaps.where((s) => s.requesterId == _currentUser!.id).toList();
  }

  /// Riwayat mutasi tukar jadwal yang telah disetujui rekan untuk audit RT
  List<ShiftSwapRequest> get completedSwapLogs {
    return shiftSwaps
        .where((s) =>
            s.status == ShiftSwapStatus.acceptedByTarget ||
            s.status == ShiftSwapStatus.approvedByAdmin)
        .toList();
  }

  /// Daftar petugas ronda yang terdaftar di RT
  List<RondaUser> get allOfficers =>
      availableUsers.where((u) => u.role == UserRole.petugasRonda).toList();

  /// Daftar petugas yang terjadwal piket ronda hari ini (tidak libur)
  List<RondaUser> get onDutyOfficersToday {
    final now = DateTime.now();
    final todaySchedules = schedules.where((s) =>
        !s.isLibur &&
        s.tanggalRonda.year == now.year &&
        s.tanggalRonda.month == now.month &&
        s.tanggalRonda.day == now.day);
    final userIds = todaySchedules.map((s) => s.userId).toSet();
    return availableUsers.where((u) => userIds.contains(u.id)).toList();
  }

  /// Cek apakah pengguna saat ini sedang aktif bertugas / berpatroli
  bool get isCurrentPetugasOnDuty {
    if (_currentUser == null) return false;
    if (_currentUser!.role != UserRole.petugasRonda) return false;
    return _backend.isPetugasOnDuty(_currentUser!.id) || _isManualDutyActive;
  }

  /// Jadwal shift pengguna saat ini hari ini
  PatrolSchedule? get myTodaySchedule {
    if (_currentUser == null) return null;
    final now = DateTime.now();
    return schedules
        .where((s) =>
            s.userId == _currentUser!.id &&
            s.tanggalRonda.year == now.year &&
            s.tanggalRonda.month == now.month &&
            s.tanggalRonda.day == now.day)
        .firstOrNull;
  }

  /// Ambil daftar jadwal untuk tanggal tertentu (Kalender Umum)
  List<PatrolSchedule> getSchedulesForDate(DateTime date) {
    return schedules
        .where((s) =>
            s.tanggalRonda.year == date.year &&
            s.tanggalRonda.month == date.month &&
            s.tanggalRonda.day == date.day)
        .toList();
  }

  /// Evaluasi status jadwal pos checkpoint untuk petugas tertentu (Default: currentUser)
  CheckpointScheduleStatus getOfficerCheckpointStatus(
    Checkpoint cp, {
    String? userId,
    DateTime? time,
  }) {
    final targetUserId = userId ?? _currentUser?.id;
    final now = time ?? DateTime.now();

    final hasCheckedIn = patrolLogs.any((log) =>
        log.checkpointId == cp.id &&
        (targetUserId == null || log.userId == targetUserId) &&
        log.scannedAt.year == now.year &&
        log.scannedAt.month == now.month &&
        log.scannedAt.day == now.day);

    // Cari jadwal shift petugas bersangkutan untuk menentukan target waktu checkpoint proporsional
    final userSched = schedules
        .where((s) =>
            s.userId == targetUserId &&
            !s.isLibur &&
            s.tanggalRonda.year == now.year &&
            s.tanggalRonda.month == now.month &&
            s.tanggalRonda.day == now.day)
        .firstOrNull;

    final cpIdx = _checkpoints.indexOf(cp);
    final targetTime = userSched?.getTargetTimeForCheckpoint(
          cpIdx >= 0 ? cpIdx : 0,
          _checkpoints.length,
        ) ??
        cp.targetWaktuCheckin;

    return cp.calculateStatus(
      currentTime: now,
      hasCheckedIn: hasCheckedIn,
      customTargetTime: targetTime,
    );
  }

  /// Evaluasi status jadwal pos checkpoint untuk petugas yang sedang aktif
  CheckpointScheduleStatus getCheckpointStatus(Checkpoint cp,
      [DateTime? time]) {
    return getOfficerCheckpointStatus(cp, time: time);
  }

  /// Daftar pos yang terlambat / terlewat belum dipindai
  List<Checkpoint> get overdueCheckpoints {
    return _checkpoints
        .where((cp) =>
            getCheckpointStatus(cp) == CheckpointScheduleStatus.terlewat)
        .toList();
  }

  /// Toggle manual status bertugas (misal tugas darurat lapangan)
  void toggleManualDuty(bool value) {
    _isManualDutyActive = value;
    _lastSuccessMessage = _isManualDutyActive
        ? 'Status Bertugas DIAKTIFKAN: Anda kini siap merespons alarm darurat SOS.'
        : 'Status Bertugas DINONAKTIFKAN.';
    notifyListeners();
  }

  /// Insiden darurat aktif di lingkungan RT
  List<EmergencyEvent> get activeEmergencies =>
      _backend.emergencyEvents.where((e) => e.isActive).toList();

  EmergencyEvent? get latestActiveEmergency =>
      _backend.emergencyEvents.where((e) => e.isActive).firstOrNull;

  /// Insiden darurat yang dipicu oleh warga yang sedang login saat ini
  EmergencyEvent? get myActiveEmergency {
    if (_currentUser == null) return null;
    return _backend.emergencyEvents
        .where((e) => e.userId == _currentUser!.id && e.isActive)
        .firstOrNull;
  }

  // ==========================================
  // REAL-TIME SUPABASE SYNCHRONIZATION
  // ==========================================

  void _cancelSubscriptions() {
    _emergencySub?.cancel();
    _emergencySub = null;
    _checkinSub?.cancel();
    _checkinSub = null;
    _swapSub?.cancel();
    _swapSub = null;
    _scheduleSub?.cancel();
    _scheduleSub = null;
    _notifSub?.cancel();
    _notifSub = null;
  }

  Future<void> _initSupabaseRealtime(String rtId) async {
    if (!_supabase.isAvailable) return;
    _cancelSubscriptions();

    try {
      // 1. Sinkronisasi Data Awal dari Supabase Cloud
      final cloudUsers = await _supabase.fetchUsers(rtId);
      if (cloudUsers.isNotEmpty) {
        _cloudUsers.clear();
        _cloudUsers.addAll(cloudUsers);
      }

      final cloudCheckpoints = await _supabase.fetchCheckpoints(rtId);
      if (cloudCheckpoints.isNotEmpty) {
        _checkpoints = cloudCheckpoints;
      }

      final cloudEmergencies = await _supabase.fetchEmergencyEvents(rtId);
      if (cloudEmergencies.isNotEmpty) {
        _backend.syncEmergencies(cloudEmergencies);
      }

      final cloudCheckins = await _supabase.fetchPatrolLogs();
      if (cloudCheckins.isNotEmpty) {
        _backend.syncPatrolLogs(cloudCheckins);
      }

      final cloudSchedules = await _supabase.fetchSchedules(rtId);
      if (cloudSchedules.isNotEmpty) {
        _backend.syncSchedules(cloudSchedules);
      }

      final cloudSwaps = await _supabase.fetchShiftSwaps();
      if (cloudSwaps.isNotEmpty) {
        _backend.syncShiftSwaps(cloudSwaps);
      }

      final cloudNotifs = await _supabase.fetchNotifications(rtId);
      if (cloudNotifs.isNotEmpty) {
        _backend.syncNotifications(cloudNotifs);
      }

      final cloudIncidents = await _supabase.fetchIncidents(rtId);
      if (cloudIncidents.isNotEmpty) {
        _backend.syncIncidents(cloudIncidents);
      }

      notifyListeners();

      // 2. Berlangganan Real-Time Stream (Postgres Changes)
      _emergencySub = _supabase.streamEmergencies(rtId).listen((items) {
        if (items.isNotEmpty) {
          _backend.syncEmergencies(items);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('Realtime Emergency Error: $e'));

      _checkinSub = _supabase.streamCheckins().listen((items) {
        if (items.isNotEmpty) {
          _backend.syncPatrolLogs(items);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('Realtime Checkin Error: $e'));

      _swapSub = _supabase.streamShiftSwaps().listen((items) {
        if (items.isNotEmpty) {
          _backend.syncShiftSwaps(items);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('Realtime Swap Error: $e'));

      _scheduleSub = _supabase.streamSchedules(rtId).listen((items) {
        if (items.isNotEmpty) {
          _backend.syncSchedules(items);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('Realtime Schedule Error: $e'));

      _notifSub = _supabase.streamNotifications(rtId).listen((items) {
        if (items.isNotEmpty) {
          _backend.syncNotifications(items);
          notifyListeners();
        }
      }, onError: (e) => debugPrint('Realtime Notif Error: $e'));
    } catch (e) {
      debugPrint('Supabase initial sync warning: $e');
    }
  }

  // ==========================================
  // 1. AUTENTIKASI AMAN & TERENKRIPSI
  // ==========================================

  /// Login resmi dengan nomor WhatsApp dan kata sandi terenkripsi
  Future<bool> login(
      {required String whatsapp, required String password}) async {
    _lastErrorMessage = null;
    _lastSuccessMessage = null;

    try {
      final user = _backend.login(whatsapp: whatsapp, password: password);
      _currentUser = user;
      _checkpoints = _backend.getCheckpoints(user.rtId);
      _lastSuccessMessage =
          'Login Berhasil: Selamat datang, ${user.namaLengkap}!';
      notifyListeners();

      // Inisialisasi Realtime & Sinkronisasi Cloud jika Supabase terhubung
      unawaited(_initSupabaseRealtime(user.rtId));
      return true;
    } catch (e) {
      _lastErrorMessage = e
          .toString()
          .replaceAll('StateError: ', '')
          .replaceAll('ArgumentError: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Autologin cepat untuk penguji / evaluator (memasukkan kredensial otomatis)
  Future<bool> quickLogin(RondaUser user) async {
    return login(
        whatsapp: user.nomorWhatsapp, password: SeedData.defaultDemoPassword);
  }

  /// Keluar dari sesi pengguna
  void logout() {
    _cancelSubscriptions();
    _currentUser = null;
    _lastErrorMessage = null;
    _lastSuccessMessage = 'Sesi telah berakhir. Silakan login kembali.';
    notifyListeners();
  }

  void clearMessages() {
    _lastErrorMessage = null;
    _lastSuccessMessage = null;
    notifyListeners();
  }

  // ==========================================
  // 2. CHECK-IN PATROLI FISIK & GPS
  // ==========================================

  /// Toggle simulasi patroli di area blank spot
  void setOfflineMode(bool value) async {
    _isOfflineMode = value;
    if (!_isOfflineMode && _offlineQueue.pendingCount > 0) {
      // Sinkronisasi otomatis saat kembali online
      final count = await _offlineQueue.processQueue((item) async {
        final cp = _checkpoints.firstWhere((c) => c.id == item.checkpointId);
        final qrPayload = QrTokenVerifier.generateQrPayload(
          checkpointId: cp.id,
          secretKey: cp.secretKey,
          timestamp: item.scannedAt,
        );
        final checkin = _backend.submitCheckin(
          checkinId: item.id,
          checkpointId: item.checkpointId,
          userId: item.userId,
          qrPayload: qrPayload,
          userLat: item.latitudeUser,
          userLon: item.longitudeUser,
          accuracy: item.accuracy,
          batteryLevel: item.batteryLevel,
          scanTime: item.scannedAt,
          forceDutyOverride: true,
        );

        if (_supabase.isAvailable) {
          unawaited(_supabase.insertCheckin(checkin));
        }
        return true;
      });
      _lastSuccessMessage =
          'Koneksi Pulih! $count rekaman offline berhasil disinkronkan ke server & cloud.';
    }
    notifyListeners();
  }

  /// Membaca koordinat GPS langsung dari perangkat
  Future<void> fetchLiveLocation() async {
    _isLoadingGps = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentGpsPosition = null;
        _lastErrorMessage =
            'Aktifkan layanan lokasi perangkat untuk melakukan check-in.';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentGpsPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } else {
        _currentGpsPosition = null;
        _lastErrorMessage = permission == LocationPermission.deniedForever
            ? 'Izin lokasi ditolak permanen. Aktifkan izin lokasi melalui Pengaturan perangkat.'
            : 'Izin lokasi diperlukan untuk melakukan check-in.';
      }
    } catch (e) {
      _currentGpsPosition = null;
      _lastErrorMessage =
          'Lokasi perangkat tidak dapat diperoleh. Coba lagi di area terbuka.';
    } finally {
      _isLoadingGps = false;
      notifyListeners();
    }
  }

  /// Melakukan Check-in pos patroli dengan verifikasi QR fisik dan Geofence GPS
  Future<bool> checkinCheckpoint({
    required Checkpoint checkpoint,
    String? scannedQrPayload,
    bool simulateProximity = false,
  }) async {
    if (_currentUser == null) return false;
    _lastErrorMessage = null;
    _lastSuccessMessage = null;

    final double lat;
    final double lon;
    final double accuracy;

    if (simulateProximity) {
      // Simulasi petugas berada 5 meter di dekat pos fisik
      lat = checkpoint.latitude + 0.00003;
      lon = checkpoint.longitude + 0.00003;
      accuracy = 4.0;
    } else {
      await fetchLiveLocation();
      final position = _currentGpsPosition;
      if (position == null) {
        _lastErrorMessage ??=
            'Lokasi GPS belum tersedia. Check-in belum disimpan.';
        notifyListeners();
        return false;
      }
      lat = position.latitude;
      lon = position.longitude;
      accuracy = position.accuracy;
    }

    // Proteksi Anti-Mock Location (GPS Spoofing)
    if (!simulateProximity && _currentGpsPosition?.isMocked == true) {
      _lastErrorMessage =
          'Validasi Keamanan Gagal: Terdeteksi penggunaan lokasi palsu (Mock Location / Fake GPS). Harap matikan aplikasi pemalsu lokasi untuk melakukan check-in resmi.';
      notifyListeners();
      return false;
    }

    // Check-in operasional wajib membawa QR pos yang benar-benar dipindai.
    final qrPayload = simulateProximity
        ? QrTokenVerifier.generateQrPayload(
            checkpointId: checkpoint.id,
            secretKey: checkpoint.secretKey,
          )
        : scannedQrPayload?.trim();
    if (qrPayload == null || qrPayload.isEmpty) {
      _lastErrorMessage = 'Pindai QR fisik pos terlebih dahulu.';
      notifyListeners();
      return false;
    }

    final qrResult = QrTokenVerifier.verifyPayload(
      payload: qrPayload,
      expectedCheckpointId: checkpoint.id,
      secretKey: checkpoint.secretKey,
    );
    if (!qrResult.isValid) {
      _lastErrorMessage = qrResult.rejectionReason ?? 'QR pos tidak valid.';
      notifyListeners();
      return false;
    }

    // 2. Evaluasi Geofence terlebih dahulu
    final geofence = HaversineCalculator.verifyGeofence(
      userLat: lat,
      userLon: lon,
      targetLat: checkpoint.latitude,
      targetLon: checkpoint.longitude,
      radiusMeters: checkpoint.radiusMeter,
      accuracyMeters: accuracy,
    );

    if (!geofence.isValid) {
      _lastErrorMessage = geofence.rejectionReason;
      notifyListeners();
      return false;
    }

    final checkinId = 'chk-${DateTime.now().millisecondsSinceEpoch}';

    // 3. Simpan ke Offline Queue atau Langsung ke Backend & Cloud
    if (_isOfflineMode) {
      final offlineItem = PatrolCheckin(
        id: checkinId,
        checkpointId: checkpoint.id,
        userId: _currentUser!.id,
        scannedAt: DateTime.now(),
        latitudeUser: lat,
        longitudeUser: lon,
        distanceMeter: geofence.distanceMeters,
        accuracy: accuracy,
        batteryLevel: 85.0,
      );
      _offlineQueue.enqueue(offlineItem);
      _lastSuccessMessage =
          'Blank spot: Check-in ${checkpoint.namaLokasi} disimpan di antrean lokal.';
    } else {
      try {
        final checkin = _backend.submitCheckin(
          checkinId: checkinId,
          checkpointId: checkpoint.id,
          userId: _currentUser!.id,
          qrPayload: qrPayload,
          userLat: lat,
          userLon: lon,
          accuracy: accuracy,
          batteryLevel: 85.0,
          forceDutyOverride: _isManualDutyActive,
        );

        if (_supabase.isAvailable) {
          unawaited(_supabase.insertCheckin(checkin));
        }

        _lastSuccessMessage =
            'Berhasil! Check-in terverifikasi di ${checkpoint.namaLokasi} (Jarak GPS: ${geofence.distanceMeters.toStringAsFixed(1)}m)';
      } catch (e) {
        _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
        notifyListeners();
        return false;
      }
    }

    notifyListeners();
    return true;
  }

  // ==========================================
  // 3. SIKLUS INSIDEN DARURAT (SOS LIFECYCLE)
  // ==========================================

  /// Memicu Tombol Panik / SOS Darurat oleh Warga
  EmergencyEvent? triggerPanic({String? catatan}) {
    if (_currentUser == null) return null;
    _lastErrorMessage = null;
    _lastSuccessMessage = null;

    final lat = _currentGpsPosition?.latitude ?? -7.281970;
    final lon = _currentGpsPosition?.longitude ?? 112.795323;

    try {
      final event = _backend.triggerPanic(
        eventId: 'sos-${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        latitude: lat,
        longitude: lon,
        catatan: catatan ?? 'Warga membunyikan alarm darurat siskamling!',
      );

      if (_supabase.isAvailable) {
        unawaited(_supabase.insertEmergency(event));
      }

      _lastSuccessMessage =
          'ALARM DARURAT DIAKTIFKAN! Notifikasi sirine dipancarkan ke seluruh petugas.';
      notifyListeners();
      return event;
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Petugas merespons insiden (Status beralih ke: ON-GOING)
  /// Hanya petugas yang terjadwal/sedang bertugas yang berhak merespons.
  void respondEmergency(String eventId, {bool forceDutyOverride = false}) {
    if (_currentUser == null) return;
    try {
      _backend.respondEmergency(
        eventId: eventId,
        responderId: _currentUser!.id,
        forceDutyOverride: forceDutyOverride || _isManualDutyActive,
      );

      if (_supabase.isAvailable) {
        final event =
            _backend.emergencyEvents.firstWhere((e) => e.id == eventId);
        unawaited(_supabase.updateEmergency(event));
      }

      _lastSuccessMessage =
          'Anda telah menyatakan merespons insiden. Segera menuju ke lokasi warga.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
      notifyListeners();
    }
  }

  /// Petugas menyelesaikan insiden via Scan QR Warga Pelapor (Status beralih ke: SELESAI)
  bool resolveEmergencyWithQr({
    required String eventId,
    required String scannedQrPayload,
  }) {
    if (_currentUser == null) return false;
    _lastErrorMessage = null;
    try {
      _backend.resolveEmergencyWithQr(
        eventId: eventId,
        scannedQrPayload: scannedQrPayload,
        responderId: _currentUser!.id,
      );

      if (_supabase.isAvailable) {
        final event =
            _backend.emergencyEvents.firstWhere((e) => e.id == eventId);
        unawaited(_supabase.updateEmergency(event));
      }

      _lastSuccessMessage =
          'Validasi QR Berhasil! Status darurat resmi dinyatakan SELESAI.';
      notifyListeners();
      return true;
    } catch (e) {
      _lastErrorMessage = e
          .toString()
          .replaceAll('ArgumentError: ', '')
          .replaceAll('StateError: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Petugas menyelesaikan insiden via Foto Bukti (Status beralih ke: MENUNGGU VERIFIKASI RT)
  bool resolveEmergencyWithPhoto({
    required String eventId,
    required String photoPath,
    required String notes,
  }) {
    if (_currentUser == null) return false;
    _lastErrorMessage = null;
    try {
      _backend.resolveEmergencyWithPhoto(
        eventId: eventId,
        photoPath: photoPath,
        notes: notes,
        responderId: _currentUser!.id,
      );

      if (_supabase.isAvailable) {
        final event =
            _backend.emergencyEvents.firstWhere((e) => e.id == eventId);
        unawaited(_supabase.updateEmergency(event));
      }

      _lastSuccessMessage =
          'Bukti foto terkirim! Status saat ini: MENUNGGU VERIFIKASI KETUA RT.';
      notifyListeners();
      return true;
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('ArgumentError: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Ketua RT memverifikasi foto bukti penanganan insiden
  void adminVerifyEmergency({
    required String eventId,
    required bool isApproved,
    String? adminNotes,
  }) {
    if (_currentUser == null || _currentUser!.role != UserRole.adminRt) {
      _lastErrorMessage = 'Hanya Ketua RT yang memiliki akses verifikasi.';
      notifyListeners();
      return;
    }
    try {
      _backend.adminVerifyEmergency(
        eventId: eventId,
        adminId: _currentUser!.id,
        isApproved: isApproved,
        adminNotes: adminNotes,
      );

      if (_supabase.isAvailable) {
        final event =
            _backend.emergencyEvents.firstWhere((e) => e.id == eventId);
        unawaited(_supabase.updateEmergency(event));
      }

      _lastSuccessMessage = isApproved
          ? 'Laporan disetujui! Status darurat resmi ditutup (SELESAI).'
          : 'Laporan ditolak. Status dikembalikan ke ON-GOING untuk investigasi lanjut.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
      notifyListeners();
    }
  }

  /// Batalkan / selesaikan darurat langsung (misal salah tekan oleh pelapor)
  void cancelMyEmergency(String eventId, {String? reason}) {
    if (_currentUser == null) return;
    try {
      _backend.cancelEmergency(
        eventId: eventId,
        userId: _currentUser!.id,
        reason: reason,
      );

      if (_supabase.isAvailable) {
        final event =
            _backend.emergencyEvents.firstWhere((e) => e.id == eventId);
        unawaited(_supabase.updateEmergency(event));
      }

      _lastSuccessMessage =
          'Alarm darurat telah dibatalkan secara mandiri oleh pelapor.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
      notifyListeners();
    }
  }

  // ==========================================
  // 4. LAPORAN TEMUAN INSIDEN BERFOTO
  // ==========================================

  void reportIncident({
    required IncidentCategory category,
    required String keterangan,
    required String photoPath,
  }) {
    if (_currentUser == null) return;
    final lat = _currentGpsPosition?.latitude ?? -7.281970;
    final lon = _currentGpsPosition?.longitude ?? 112.795323;

    final report = _backend.reportIncident(
      incidentId: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      category: category,
      keterangan: keterangan,
      photoPath: photoPath,
      latitude: lat,
      longitude: lon,
      compass: 90.0,
    );

    if (_supabase.isAvailable) {
      unawaited(_supabase.insertIncident(report));
    }

    _lastSuccessMessage =
        'Laporan insiden berhasil dikirim ke Linimasa Keamanan RT.';
    notifyListeners();
  }

  // ==========================================
  // 5. TUKAR JADWAL (SHIFT SWAP) LENGKAP
  // ==========================================

  void requestShiftSwap({
    required String scheduleId,
    required String targetUserId,
    required String alasan,
    String? requesterShift,
    DateTime? targetDate,
    String? targetShift,
  }) {
    if (_currentUser == null) return;
    try {
      final swap = _backend.requestShiftSwap(
        requestId: 'swp-${DateTime.now().millisecondsSinceEpoch}',
        scheduleId: scheduleId,
        requesterId: _currentUser!.id,
        targetUserId: targetUserId,
        alasan: alasan,
        requesterShift: requesterShift,
        targetDate: targetDate,
        targetShift: targetShift,
      );

      if (_supabase.isAvailable) {
        unawaited(_supabase.insertShiftSwap(swap));
      }

      _lastSuccessMessage =
          'Permintaan tukar jadwal terkirim ke petugas pengganti.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  void respondShiftSwap({required String requestId, required bool isAccepted}) {
    if (_currentUser == null) return;
    try {
      _backend.respondShiftSwap(
        requestId: requestId,
        responderId: _currentUser!.id,
        isAccepted: isAccepted,
      );

      if (_supabase.isAvailable) {
        final swap = _backend.shiftSwaps.firstWhere((s) => s.id == requestId);
        unawaited(_supabase.updateShiftSwap(swap));
        if (isAccepted && _currentUser != null) {
          unawaited(_supabase
              .upsertSchedules(_backend.getSchedules(_currentUser!.rtId)));
        }
      }

      _lastSuccessMessage = isAccepted
          ? 'Pertukaran jadwal berhasil disetujui! Jadwal ronda Anda dan rekan otomatis diperbarui.'
          : 'Pertukaran jadwal telah ditolak.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  void approveShiftSwap({required String requestId, required bool isApproved}) {
    if (_currentUser == null || _currentUser!.role != UserRole.adminRt) return;
    try {
      _backend.approveShiftSwap(
        requestId: requestId,
        approverRole: _currentUser!.role,
        isApproved: isApproved,
      );

      if (_supabase.isAvailable) {
        final swap = _backend.shiftSwaps.firstWhere((s) => s.id == requestId);
        unawaited(_supabase.updateShiftSwap(swap));
        if (isApproved && _currentUser != null) {
          unawaited(_supabase
              .upsertSchedules(_backend.getSchedules(_currentUser!.rtId)));
        }
      }

      _lastSuccessMessage = isApproved
          ? 'Perpindahan jadwal resmi disetujui. Jadwal patroli telah diperbarui.'
          : 'Pengajuan perpindahan jadwal ditolak.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  // ==========================================
  // 6. MANAJEMEN JADWAL & BROADCAST KETUA RT
  // ==========================================

  /// Menugaskan jadwal secara manual oleh Ketua RT
  void assignScheduleManual({
    required String userId,
    required DateTime date,
    required String shiftName,
    required String jamMulai,
    required String jamSelesai,
    bool isLibur = false,
  }) {
    if (_currentUser == null || _currentUser!.role != UserRole.adminRt) {
      _lastErrorMessage =
          'Hanya Ketua RT yang memiliki akses manajemen jadwal.';
      notifyListeners();
      return;
    }

    try {
      final sched = _backend.assignScheduleManual(
        rtId: _currentUser!.rtId,
        userId: userId,
        date: date,
        shiftName: shiftName,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        isLibur: isLibur,
      );

      if (_supabase.isAvailable) {
        unawaited(_supabase.upsertSchedule(sched));
      }

      _lastSuccessMessage =
          'Jadwal berhasil ditetapkan untuk petugas terpilih.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Membuat jadwal bergilir otomatis (5 hari ronda + 1 hari libur)
  void generateAutoRoster({DateTime? startDate, int daysCount = 30}) {
    if (_currentUser == null || _currentUser!.role != UserRole.adminRt) {
      _lastErrorMessage = 'Hanya Ketua RT yang dapat mengatur jadwal otomatis.';
      notifyListeners();
      return;
    }

    try {
      final list = _backend.generateAutoRoster(
        rtId: _currentUser!.rtId,
        startDate: startDate,
        daysCount: daysCount,
      );

      if (_supabase.isAvailable) {
        unawaited(_supabase.upsertSchedules(list));
      }

      _lastSuccessMessage =
          'Berhasil membentuk ${list.length} entri jadwal (rotasi 5 hari dinas + 1 libur) untuk $daysCount hari ke depan!';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
      notifyListeners();
    }
  }

  /// Ketua RT mengirim panggilan siaga darurat ke seluruh petugas (berjaga maupun off-duty)
  void broadcastSosToOfficers({
    required String eventId,
    required bool includeOffDuty,
    String? customMessage,
  }) {
    if (_currentUser == null || _currentUser!.role != UserRole.adminRt) return;
    try {
      _backend.broadcastSosAlert(
        rtId: _currentUser!.rtId,
        eventId: eventId,
        includeOffDuty: includeOffDuty,
        customMessage: customMessage,
      );

      if (_supabase.isAvailable && _backend.notifications.isNotEmpty) {
        unawaited(_supabase.insertNotification(_backend.notifications.first));
      }

      _lastSuccessMessage = includeOffDuty
          ? 'Peringatan Darurat dipancarkan ke SELURUH petugas ronda (piket dan cadangan)!'
          : 'Peringatan Darurat dikirimkan ke petugas yang sedang piket.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Ketua RT mengirim peringatan manual untuk pos patroli yang belum di-scan
  void notifyCheckpointReminder({
    required String checkpointId,
    String? targetUserId,
    String? message,
  }) {
    if (_currentUser == null || _currentUser!.role != UserRole.adminRt) return;
    try {
      _backend.notifyCheckpointReminder(
        rtId: _currentUser!.rtId,
        checkpointId: checkpointId,
        targetUserId: targetUserId,
        customMessage: message,
      );

      if (_supabase.isAvailable && _backend.notifications.isNotEmpty) {
        unawaited(_supabase.insertNotification(_backend.notifications.first));
      }

      _lastSuccessMessage =
          'Pemberitahuan peringatan check-in telah terkirim ke petugas patroli.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  void refreshData() {
    if (_currentUser != null && _supabase.isAvailable) {
      unawaited(_initSupabaseRealtime(_currentUser!.rtId));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
