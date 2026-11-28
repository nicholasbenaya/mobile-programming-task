import 'dart:math' as math;

/// Pure-Dart Haversine distance calculator mirroring `public.compute_haversine_m`.
abstract final class HaversineCalculator {
  static const double earthRadiusMeters = 6371000.0;
  static const double minExtremeGeofenceMeters = 150.0;
  static const double extremeGeofenceMultiplier = 3.0;

  /// Returns great-circle distance in meters between two WGS-84 coordinates.
  static double distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    _validateLatitude(lat1, 'lat1');
    _validateLongitude(lng1, 'lng1');
    _validateLatitude(lat2, 'lat2');
    _validateLongitude(lng2, 'lng2');

    if (lat1 == lat2 && lng1 == lng2) {
      return 0.0;
    }

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final sinHalfLat = math.sin(dLat / 2.0);
    final sinHalfLng = math.sin(dLng / 2.0);

    final a = (sinHalfLat * sinHalfLat) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            (sinHalfLng * sinHalfLng);
    final clampedA = a.clamp(0.0, 1.0);
    final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));
    return earthRadiusMeters * c;
  }

  static bool isWithinGeofence({
    required double distanceMeters,
    required int radiusMeters,
  }) {
    return distanceMeters <= radiusMeters;
  }

  /// Extreme geofence threshold beyond which check-ins hard-fail: max(radius * 3, 150 m).
  static double extremeGeofenceLimitMeters(int radiusMeters) {
    return math.max(
      radiusMeters * extremeGeofenceMultiplier,
      minExtremeGeofenceMeters,
    );
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  static void _validateLatitude(double value, String label) {
    if (!value.isFinite || value < -90.0 || value > 90.0) {
      throw RangeError('$label harus berada di antara -90 dan 90: $value');
    }
  }

  static void _validateLongitude(double value, String label) {
    if (!value.isFinite || value < -180.0 || value > 180.0) {
      throw RangeError('$label harus berada di antara -180 dan 180: $value');
    }
  }
}
