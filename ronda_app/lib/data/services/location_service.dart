import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:ronda_app/core/errors/app_failure.dart';

/// Immutable GPS reading including accuracy and mock-location anti-spoofing flag.
class LocationReading {
  const LocationReading({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMocked,
    required this.capturedAtUtc,
    required this.monotonicMs,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isMocked;
  final DateTime capturedAtUtc;
  final int monotonicMs;
}

/// Platform adapter over `geolocator` so [LocationService] can be unit tested cleanly.
abstract interface class LocationAdapter {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition(LocationSettings settings);
  Stream<Position> getPositionStream(LocationSettings settings);
}

class _GeolocatorAdapter implements LocationAdapter {
  const _GeolocatorAdapter();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) =>
      Geolocator.getCurrentPosition(locationSettings: settings);

  @override
  Stream<Position> getPositionStream(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings);
}

/// High-accuracy GPS service with permission handling and mock-location detection.
class LocationService {
  LocationService({
    LocationAdapter? adapter,
    DateTime Function()? clock,
    Stopwatch? monotonicClock,
  })  : _adapter = adapter ?? const _GeolocatorAdapter(),
        _clock = clock ?? _defaultUtcClock,
        _stopwatch = monotonicClock ?? (Stopwatch()..start());

  final LocationAdapter _adapter;
  final DateTime Function() _clock;
  final Stopwatch _stopwatch;

  static DateTime _defaultUtcClock() => DateTime.now().toUtc();

  Future<void> ensureLocationReady() async {
    final serviceEnabled = await _adapter.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const PermissionFailure(
        message:
            'Layanan lokasi GPS perangkat tidak aktif. Aktifkan GPS untuk melanjutkan patroli.',
        code: 'LOCATION_SERVICE_DISABLED',
      );
    }

    var permission = await _adapter.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _adapter.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const PermissionFailure(
        message:
            'Izin lokasi diperlukan untuk memverifikasi jarak check-in patroli.',
        code: 'LOCATION_PERMISSION_DENIED',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionFailure(
        message:
            'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi untuk mengaktifkan akses lokasi.',
        code: 'LOCATION_PERMISSION_DENIED_FOREVER',
      );
    }
  }

  /// Captures a single high-accuracy GPS reading with `isMocked` anti-spoofing flag.
  Future<LocationReading> getCurrentReading({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      await ensureLocationReady();
      final position = await _adapter.getCurrentPosition(
        LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return _toReading(position);
    } catch (error, stackTrace) {
      throw _mapLocationError(error, stackTrace);
    }
  }

  /// Streams continuous high-accuracy GPS readings for patrol map and camera preview strips.
  Stream<LocationReading> watchReadings({
    int distanceFilterMeters = 5,
  }) async* {
    try {
      await ensureLocationReady();
      yield* _adapter
          .getPositionStream(
            LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: distanceFilterMeters,
            ),
          )
          .map(_toReading)
          .handleError((Object error, StackTrace stackTrace) {
        throw _mapLocationError(error, stackTrace);
      });
    } catch (error, stackTrace) {
      throw _mapLocationError(error, stackTrace);
    }
  }

  LocationReading _toReading(Position position) {
    return LocationReading(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy.isFinite && position.accuracy >= 0
          ? position.accuracy
          : 999.0,
      isMocked: position.isMocked,
      capturedAtUtc: _clock().toUtc(),
      monotonicMs: _stopwatch.elapsedMilliseconds,
    );
  }

  AppFailure _mapLocationError(Object error, StackTrace stackTrace) {
    if (error is AppFailure) {
      return error;
    }
    if (error is LocationServiceDisabledException) {
      return PermissionFailure(
        message: 'Layanan lokasi GPS tidak aktif.',
        code: 'LOCATION_SERVICE_DISABLED',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is PermissionDeniedException) {
      return PermissionFailure(
        message: 'Izin lokasi ditolak oleh sistem.',
        code: 'LOCATION_PERMISSION_DENIED',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is TimeoutException) {
      return NetworkFailure(
        message:
            'Sinyal GPS belum terkunci dalam batas waktu. Pindah ke area terbuka lalu coba lagi.',
        code: 'LOCATION_TIMEOUT',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AppFailure.fromException(error, stackTrace);
  }
}
