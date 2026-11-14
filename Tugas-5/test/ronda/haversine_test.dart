import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/services/haversine_calculator.dart';

void main() {
  group('HaversineCalculator Tests', () {
    // Pos Ronda Utama (ITS Sukolilo, Surabaya)
    const posLat = -7.281970;
    const posLon = 112.795323;

    test('Jarak ke titik yang sama bernilai 0.0 meter', () {
      final distance = HaversineCalculator.calculateDistance(posLat, posLon, posLat, posLon);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('Jarak bersifat simetris A->B sama dengan B->A', () {
      const userLat = -7.282100;
      const userLon = 112.795400;

      final distAB = HaversineCalculator.calculateDistance(posLat, posLon, userLat, userLon);
      final distBA = HaversineCalculator.calculateDistance(userLat, userLon, posLat, posLon);

      expect(distAB, equals(distBA));
      expect(distAB, greaterThan(10.0));
    });

    test('Geofence VALID jika berada dalam radius 25 meter', () {
      // Titik berjarak ~15 meter dari pos
      const userLat = -7.282050;
      const userLon = 112.795380;

      final result = HaversineCalculator.verifyGeofence(
        userLat: userLat,
        userLon: userLon,
        targetLat: posLat,
        targetLon: posLon,
        radiusMeters: 25.0,
        accuracyMeters: 5.0,
      );

      expect(result.isValid, isTrue);
      expect(result.distanceMeters, lessThanOrEqualTo(25.0));
      expect(result.rejectionReason, isNull);
    });

    test('Geofence INVALID jika berada di luar radius 25 meter', () {
      // Titik berjarak ~150 meter dari pos
      const userLat = -7.283300;
      const userLon = 112.795323;

      final result = HaversineCalculator.verifyGeofence(
        userLat: userLat,
        userLon: userLon,
        targetLat: posLat,
        targetLon: posLon,
        radiusMeters: 25.0,
        accuracyMeters: 5.0,
      );

      expect(result.isValid, isFalse);
      expect(result.distanceMeters, greaterThan(25.0));
      expect(result.rejectionReason, contains('di luar radius pos'));
    });

    test('Geofence INVALID jika akurasi GPS terlalu buruk (> 35 meter)', () {
      // Titik dekat (10 meter), tapi akurasi GPS drop menjadi 50 meter
      const userLat = -7.282020;
      const userLon = 112.795350;

      final result = HaversineCalculator.verifyGeofence(
        userLat: userLat,
        userLon: userLon,
        targetLat: posLat,
        targetLon: posLon,
        radiusMeters: 25.0,
        accuracyMeters: 50.0, // > 35m
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('Akurasi GPS terlalu rendah'));
    });

    test('Geofence INVALID jika koordinat GPS di luar rentang dunia (-90..90, -180..180)', () {
      final result = HaversineCalculator.verifyGeofence(
        userLat: 95.0, // Invalid lat
        userLon: 112.795323,
        targetLat: posLat,
        targetLon: posLon,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('di luar rentang valid'));
    });
  });
}
