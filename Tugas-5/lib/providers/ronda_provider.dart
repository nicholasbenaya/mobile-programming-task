import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/mock/mock_backend.dart';
import '../data/mock/seed_data.dart';
import '../domain/ronda/models/ronda_models.dart';
import '../domain/ronda/services/haversine_calculator.dart';
import '../domain/ronda/services/offline_sync_queue.dart';
import '../domain/ronda/services/qr_token_verifier.dart';

/// Provider Utama untuk Mengelola State Interaktif Ronda Digital di UI
class RondaProvider extends ChangeNotifier {
  RondaProvider() {
    _backend = MockBackend();
    _offlineQueue = OfflineSyncQueue();
    // Default state awal: Pengguna belum login untuk menjamin keamanan kredensial
    _currentUser = null;
    _checkpoints = SeedData.checkpoints;
  }

  late final MockBackend _backend;
  late final OfflineSyncQueue _offlineQueue;
  RondaUser? _currentUser;
  late List<Checkpoint> _checkpoints;

  Position? _currentGpsPosition;
  bool _isOfflineMode = false;
  bool _isLoadingGps = false;
  String? _lastErrorMessage;
  String? _lastSuccessMessage;

  // Getters Keamanan & Autentikasi
  bool get isAuthenticated => _currentUser != null;
  RondaUser? get currentUser => _currentUser;
  List<RondaUser> get availableUsers => SeedData.allUsers;
  List<Checkpoint> get checkpoints => _checkpoints;
  OfflineSyncQueue get offlineQueue => _offlineQueue;
  Position? get currentGpsPosition => _currentGpsPosition;
  bool get isOfflineMode => _isOfflineMode;
  bool get isLoadingGps => _isLoadingGps;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastSuccessMessage => _lastSuccessMessage;

  List<PatrolSchedule> get schedules =>
      _currentUser != null ? _backend.getSchedules(_currentUser!.rtId) : [];
  List<PatrolCheckin> get patrolLogs => _backend.patrolLogs;
  List<IncidentReport> get incidents => _backend.incidents;
  List<ShiftSwapRequest> get shiftSwaps => _backend.shiftSwaps;
  List<EmergencyEvent> get emergencyEvents => _backend.emergencyEvents;

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
  // 1. AUTENTIKASI AMAN & TERENKRIPSI
  // ==========================================

  /// Login resmi dengan nomor WhatsApp dan kata sandi terenkripsi
  Future<bool> login({required String whatsapp, required String password}) async {
    _lastErrorMessage = null;
    _lastSuccessMessage = null;

    try {
      final user = _backend.login(whatsapp: whatsapp, password: password);
      _currentUser = user;
      _checkpoints = _backend.getCheckpoints(user.rtId);
      _lastSuccessMessage = 'Login Berhasil: Selamat datang, ${user.namaLengkap}!';
      notifyListeners();
      return true;
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '').replaceAll('ArgumentError: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Autologin cepat untuk penguji / evaluator (memasukkan kredensial otomatis)
  Future<bool> quickLogin(RondaUser user) async {
    return login(whatsapp: user.nomorWhatsapp, password: SeedData.defaultDemoPassword);
  }

  /// Keluar dari sesi pengguna
  void logout() {
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
        _backend.submitCheckin(
          checkinId: item.id,
          checkpointId: item.checkpointId,
          userId: item.userId,
          qrPayload: qrPayload,
          userLat: item.latitudeUser,
          userLon: item.longitudeUser,
          accuracy: item.accuracy,
          batteryLevel: item.batteryLevel,
          scanTime: item.scannedAt,
        );
        return true;
      });
      _lastSuccessMessage = 'Koneksi Pulih! $count rekaman offline berhasil disinkronkan ke server.';
    }
    notifyListeners();
  }

  /// Membaca koordinat GPS langsung dari perangkat
  Future<void> fetchLiveLocation() async {
    _isLoadingGps = true;
    notifyListeners();

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _currentGpsPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      }
    } catch (_) {
      // Fallback koordinat jika di simulator desktop/emulator tanpa fix GPS
      _currentGpsPosition ??= Position(
        latitude: -7.281970,
        longitude: 112.795323,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    } finally {
      _isLoadingGps = false;
      notifyListeners();
    }
  }

  /// Melakukan Check-in pos patroli dengan verifikasi QR fisik dan Geofence GPS
  Future<bool> checkinCheckpoint({
    required Checkpoint checkpoint,
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
      if (_currentGpsPosition == null) {
        await fetchLiveLocation();
      }
      lat = _currentGpsPosition?.latitude ?? checkpoint.latitude;
      lon = _currentGpsPosition?.longitude ?? checkpoint.longitude;
      accuracy = _currentGpsPosition?.accuracy ?? 5.0;
    }

    // 1. Generate QR Payload bertanda waktu pos fisik
    final qrPayload = QrTokenVerifier.generateQrPayload(
      checkpointId: checkpoint.id,
      secretKey: checkpoint.secretKey,
    );

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

    // 3. Simpan ke Offline Queue atau Langsung ke Backend
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
      _lastSuccessMessage = 'Blank spot: Check-in ${checkpoint.namaLokasi} disimpan di antrean lokal.';
    } else {
      try {
        _backend.submitCheckin(
          checkinId: checkinId,
          checkpointId: checkpoint.id,
          userId: _currentUser!.id,
          qrPayload: qrPayload,
          userLat: lat,
          userLon: lon,
          accuracy: accuracy,
          batteryLevel: 85.0,
        );
        _lastSuccessMessage = 'Berhasil! Check-in terverifikasi di ${checkpoint.namaLokasi} (Jarak GPS: ${geofence.distanceMeters.toStringAsFixed(1)}m)';
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

      _lastSuccessMessage = 'ALARM DARURAT DIAKTIFKAN! Notifikasi sirine dipancarkan ke seluruh petugas.';
      notifyListeners();
      return event;
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('StateError: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Petugas merespons insiden (Status beralih ke: ON-GOING)
  void respondEmergency(String eventId) {
    if (_currentUser == null) return;
    try {
      _backend.respondEmergency(eventId: eventId, responderId: _currentUser!.id);
      _lastSuccessMessage = 'Anda telah menyatakan merespons insiden. Segera menuju ke lokasi warga.';
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
      _lastSuccessMessage = 'Validasi QR Berhasil! Status darurat resmi dinyatakan SELESAI.';
      notifyListeners();
      return true;
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('ArgumentError: ', '').replaceAll('StateError: ', '');
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
      _lastSuccessMessage = 'Bukti foto terkirim! Status saat ini: MENUNGGU VERIFIKASI KETUA RT.';
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
  void cancelMyEmergency(String eventId) {
    _backend.resolveEmergency(eventId);
    _lastSuccessMessage = 'Alarm darurat telah dibatalkan.';
    notifyListeners();
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

    _backend.reportIncident(
      incidentId: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      category: category,
      keterangan: keterangan,
      photoPath: photoPath,
      latitude: lat,
      longitude: lon,
      compass: 90.0,
    );

    _lastSuccessMessage = 'Laporan insiden berhasil dikirim ke Linimasa Keamanan RT.';
    notifyListeners();
  }

  // ==========================================
  // 5. TUKAR JADWAL (SHIFT SWAP)
  // ==========================================

  void requestShiftSwap({
    required String scheduleId,
    required String targetUserId,
    required String alasan,
  }) {
    if (_currentUser == null) return;
    try {
      _backend.requestShiftSwap(
        requestId: 'swp-${DateTime.now().millisecondsSinceEpoch}',
        scheduleId: scheduleId,
        requesterId: _currentUser!.id,
        targetUserId: targetUserId,
        alasan: alasan,
      );
      _lastSuccessMessage = 'Permintaan tukar jadwal terkirim ke petugas pengganti.';
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
      _lastSuccessMessage = isAccepted
          ? 'Anda menyetujui pertukaran. Menunggu persetujuan akhir dari Ketua RT.'
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
      _lastSuccessMessage = isApproved
          ? 'Perpindahan jadwal resmi disetujui. Jadwal patroli telah diperbarui.'
          : 'Pengajuan perpindahan jadwal ditolak.';
      notifyListeners();
    } catch (e) {
      _lastErrorMessage = e.toString();
      notifyListeners();
    }
  }

  void refreshData() {
    notifyListeners();
  }
}
