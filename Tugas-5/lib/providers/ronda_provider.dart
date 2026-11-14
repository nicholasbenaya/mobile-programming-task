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
    _currentUser = SeedData.petugasJordi; // Default peran awal: Petugas Ronda
    _checkpoints = _backend.getCheckpoints(_currentUser.rtId);
    _offlineQueue = OfflineSyncQueue();
    refreshData();
  }

  late final MockBackend _backend;
  late RondaUser _currentUser;
  late List<Checkpoint> _checkpoints;
  late final OfflineSyncQueue _offlineQueue;

  Position? _currentGpsPosition;
  bool _isOfflineMode = false;
  bool _isLoadingGps = false;
  String? _lastErrorMessage;
  String? _lastSuccessMessage;

  // Getters
  RondaUser get currentUser => _currentUser;
  List<RondaUser> get availableUsers => SeedData.allUsers;
  List<Checkpoint> get checkpoints => _checkpoints;
  OfflineSyncQueue get offlineQueue => _offlineQueue;
  Position? get currentGpsPosition => _currentGpsPosition;
  bool get isOfflineMode => _isOfflineMode;
  bool get isLoadingGps => _isLoadingGps;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastSuccessMessage => _lastSuccessMessage;

  List<PatrolSchedule> get schedules => _backend.getSchedules(_currentUser.rtId);
  List<PatrolCheckin> get patrolLogs => _backend.patrolLogs;
  List<IncidentReport> get incidents => _backend.incidents;
  List<EmergencyEvent> get emergencyEvents => _backend.emergencyEvents;
  EmergencyEvent? get activeEmergency =>
      _backend.emergencyEvents.where((e) => e.isActive).lastOrNull;

  /// Mengganti peran pengguna secara instan di UI
  void switchUser(RondaUser user) {
    _currentUser = user;
    _lastErrorMessage = null;
    _lastSuccessMessage = 'Beralih ke pengguna: ${user.namaLengkap} (${user.role.label})';
    notifyListeners();
  }

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

  /// Melakukan Check-in pos patroli (dengan opsi simulasi jarak dekat untuk penguji)
  Future<bool> checkinCheckpoint({
    required Checkpoint checkpoint,
    bool simulateProximity = false,
  }) async {
    _lastErrorMessage = null;
    _lastSuccessMessage = null;

    final double lat;
    final double lon;
    final double accuracy;

    if (simulateProximity) {
      // Simulasi penguji berada 5 meter di dekat pos
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

    // 1. Generate QR Payload bertanda waktu
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
        userId: _currentUser.id,
        scannedAt: DateTime.now(),
        latitudeUser: lat,
        longitudeUser: lon,
        distanceMeter: geofence.distanceMeters,
        accuracy: accuracy,
        batteryLevel: 85.0,
      );
      _offlineQueue.enqueue(offlineItem);
      _lastSuccessMessage = 'Sinyal offline: Check-in ${checkpoint.namaLokasi} disimpan di antrean lokal.';
    } else {
      try {
        _backend.submitCheckin(
          checkinId: checkinId,
          checkpointId: checkpoint.id,
          userId: _currentUser.id,
          qrPayload: qrPayload,
          userLat: lat,
          userLon: lon,
          accuracy: accuracy,
          batteryLevel: 85.0,
        );
        _lastSuccessMessage = 'Berhasil! Check-in terverifikasi di ${checkpoint.namaLokasi} (Jarak: ${geofence.distanceMeters.toStringAsFixed(1)}m)';
      } catch (e) {
        _lastErrorMessage = e.toString();
        notifyListeners();
        return false;
      }
    }

    notifyListeners();
    return true;
  }

  /// Memicu Tombol Panik / SOS Darurat
  EmergencyEvent triggerPanic({String? catatan}) {
    final lat = _currentGpsPosition?.latitude ?? -7.281970;
    final lon = _currentGpsPosition?.longitude ?? 112.795323;

    final event = _backend.triggerPanic(
      eventId: 'sos-${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser.id,
      latitude: lat,
      longitude: lon,
      catatan: catatan ?? 'Warga membunyikan alarm darurat siskamling!',
    );

    _lastSuccessMessage = 'ALARM DARURAT AKTIF! Sinyal dipancarkan ke seluruh smartphone RT.';
    notifyListeners();
    return event;
  }

  /// Menyelesaikan status darurat
  void resolveEmergency(String eventId) {
    _backend.resolveEmergency(eventId);
    _lastSuccessMessage = 'Status darurat telah diselesaikan (RESOLVED).';
    notifyListeners();
  }

  /// Membuat laporan kejadian insiden berfoto
  void reportIncident({
    required IncidentCategory category,
    required String keterangan,
    required String photoPath,
  }) {
    final lat = _currentGpsPosition?.latitude ?? -7.281970;
    final lon = _currentGpsPosition?.longitude ?? 112.795323;

    _backend.reportIncident(
      incidentId: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser.id,
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

  void refreshData() {
    notifyListeners();
  }
}
