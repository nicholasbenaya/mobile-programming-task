import 'dart:math' as math;

/// Hasil Evaluasi Geofencing Pos Checkpoint
class GeofenceValidationResult {
  const GeofenceValidationResult({
    required this.isValid,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    this.accuracyMeters,
    this.rejectionReason,
  });

  final bool isValid;
  final double distanceMeters;
  final double allowedRadiusMeters;
  final double? accuracyMeters;
  final String? rejectionReason;

  @override
  String toString() {
    if (isValid) {
      return 'Geofence VALID: jarak ${distanceMeters.toStringAsFixed(1)}m (radius max: ${allowedRadiusMeters.toStringAsFixed(1)}m)';
    }
    return 'Geofence INVALID: $rejectionReason (jarak: ${distanceMeters.toStringAsFixed(1)}m, radius max: ${allowedRadiusMeters.toStringAsFixed(1)}m)';
  }
}

/// Mesin Kalkulasi Jarak Berdasarkan Formula Haversine & Validasi Geofence
class HaversineCalculator {
  const HaversineCalculator._();

  /// Radius rata-rata bumi dalam meter (WGS-84)
  static const double earthRadiusMeters = 6371000.0;

  /// Ambang batas akurasi GPS maksimum yang diperbolehkan (mencegah GPS spoofing / sinyal lemah)
  static const double maxAcceptableAccuracyMeters = 35.0;

  /// Menghitung jarak lengkung lingkaran besar antara dua koordinat GPS (dalam meter)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Memverifikasi apakah koordinat pengguna berada dalam radius checkpoint yang diperbolehkan
  static GeofenceValidationResult verifyGeofence({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
    double radiusMeters = 25.0,
    double? accuracyMeters,
  }) {
    // 1. Cek validitas batas koordinat
    if (userLat < -90.0 || userLat > 90.0 || userLon < -180.0 || userLon > 180.0) {
      return GeofenceValidationResult(
        isValid: false,
        distanceMeters: double.infinity,
        allowedRadiusMeters: radiusMeters,
        accuracyMeters: accuracyMeters,
        rejectionReason: 'Koordinat GPS pengguna berada di luar rentang valid dunia.',
      );
    }

    // 2. Cek degradasi akurasi GPS (Anti Mock / Blind Spot)
    if (accuracyMeters != null && accuracyMeters > maxAcceptableAccuracyMeters) {
      final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
      return GeofenceValidationResult(
        isValid: false,
        distanceMeters: distance,
        allowedRadiusMeters: radiusMeters,
        accuracyMeters: accuracyMeters,
        rejectionReason: 'Akurasi GPS terlalu rendah (${accuracyMeters.toStringAsFixed(1)}m > max ${maxAcceptableAccuracyMeters}m). Harap tunggu sinyal GPS stabil.',
      );
    }

    // 3. Hitung jarak Haversine
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);

    if (distance <= radiusMeters) {
      return GeofenceValidationResult(
        isValid: true,
        distanceMeters: distance,
        allowedRadiusMeters: radiusMeters,
        accuracyMeters: accuracyMeters,
      );
    } else {
      final selisih = distance - radiusMeters;
      return GeofenceValidationResult(
        isValid: false,
        distanceMeters: distance,
        allowedRadiusMeters: radiusMeters,
        accuracyMeters: accuracyMeters,
        rejectionReason: 'Posisi Anda berada di luar radius pos (${selisih.toStringAsFixed(1)}m lebih jauh dari batas ${radiusMeters.toStringAsFixed(1)}m).',
      );
    }
  }

  static double _toRadians(double degree) => degree * (math.pi / 180.0);
}
