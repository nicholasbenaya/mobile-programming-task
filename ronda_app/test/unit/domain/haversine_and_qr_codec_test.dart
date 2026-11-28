import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/domain/models/checkpoint.dart';
import 'package:ronda_app/domain/services/haversine_calculator.dart';
import 'package:ronda_app/domain/services/qr_codec.dart';

void main() {
  const siteId = '11111111-1111-4111-8111-111111111111';
  const otherSiteId = '99999999-9999-4999-8999-999999999999';
  const checkpointId = '22222222-2222-4222-8222-222222222222';
  const secret = '0123456789abcdef0123456789abcdef';

  Checkpoint buildCheckpoint({int version = 1, bool isActive = true}) {
    return Checkpoint(
      id: checkpointId,
      siteId: siteId,
      code: 'POS-01',
      name: 'Gerbang Utama',
      description: 'Pos depan',
      latitude: -7.2575,
      longitude: 112.7521,
      radiusMeters: 30,
      sortOrder: 1,
      qrTokenVersion: version,
      isActive: isActive,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('HaversineCalculator', () {
    test('returns 0 for identical coordinates', () {
      expect(
        HaversineCalculator.distanceMeters(
          lat1: -7.2575,
          lng1: 112.7521,
          lat2: -7.2575,
          lng2: 112.7521,
        ),
        0.0,
      );
    });

    test('computes accurate great-circle distance and is symmetric', () {
      // ~0.001 deg latitude is approximately 111.19 meters.
      final ab = HaversineCalculator.distanceMeters(
        lat1: -7.2575,
        lng1: 112.7521,
        lat2: -7.2585,
        lng2: 112.7521,
      );
      final ba = HaversineCalculator.distanceMeters(
        lat1: -7.2585,
        lng1: 112.7521,
        lat2: -7.2575,
        lng2: 112.7521,
      );

      expect(ab, closeTo(111.19, 0.5));
      expect(ab, closeTo(ba, 0.0001));
    });

    test('computes extreme geofence limit as max(radius * 3, 150)', () {
      expect(HaversineCalculator.extremeGeofenceLimitMeters(30), 150.0);
      expect(HaversineCalculator.extremeGeofenceLimitMeters(50), 150.0);
      expect(HaversineCalculator.extremeGeofenceLimitMeters(70), 210.0);
    });

    test('throws RangeError for out-of-range or non-finite coordinates', () {
      expect(
        () => HaversineCalculator.distanceMeters(
          lat1: 91.0,
          lng1: 0.0,
          lat2: 0.0,
          lng2: 0.0,
        ),
        throwsRangeError,
      );
      expect(
        () => HaversineCalculator.distanceMeters(
          lat1: 0.0,
          lng1: -181.0,
          lat2: 0.0,
          lng2: 0.0,
        ),
        throwsRangeError,
      );
      expect(
        () => HaversineCalculator.distanceMeters(
          lat1: double.nan,
          lng1: 0.0,
          lat2: 0.0,
          lng2: 0.0,
        ),
        throwsRangeError,
      );
    });
  });

  group('QrCodec', () {
    test('encodes, parses, and verifies HMAC signature roundtrip', () {
      final raw = QrCodec.encode(
        siteId: siteId,
        checkpointId: checkpointId,
        tokenVersion: 2,
        secret: secret,
      );

      final parsed = QrCodec.tryParse('  $raw  ');
      expect(parsed, isNotNull);
      expect(parsed!.siteId, siteId);
      expect(parsed.checkpointId, checkpointId);
      expect(parsed.tokenVersion, 2);
      expect(parsed.signature.length, 64);

      expect(QrCodec.verifySignature(qr: parsed, secret: secret), isTrue);
      expect(QrCodec.verifySignature(qr: parsed, secret: 'wrong-secret'), isFalse);
      expect(QrCodec.verifySignature(qr: parsed, secret: ''), isFalse);
      expect(
        QrCodec.matchesCheckpoint(qr: parsed, checkpoint: buildCheckpoint(version: 2)),
        isTrue,
      );
    });

    test('rejects mismatched site, inactive checkpoint, or revoked token version', () {
      final raw = QrCodec.encode(
        siteId: siteId,
        checkpointId: checkpointId,
        tokenVersion: 1,
        secret: secret,
      );
      final parsed = QrCodec.tryParse(raw)!;

      expect(
        QrCodec.matchesCheckpoint(qr: parsed, checkpoint: buildCheckpoint(version: 2)),
        isFalse,
      );
      expect(
        QrCodec.matchesCheckpoint(
          qr: parsed,
          checkpoint: buildCheckpoint(version: 1, isActive: false),
        ),
        isFalse,
      );

      final otherSiteRaw = QrCodec.encode(
        siteId: otherSiteId,
        checkpointId: checkpointId,
        tokenVersion: 1,
        secret: secret,
      );
      expect(
        QrCodec.matchesCheckpoint(
          qr: QrCodec.tryParse(otherSiteRaw)!,
          checkpoint: buildCheckpoint(version: 1),
        ),
        isFalse,
      );
    });

    test('returns null on malformed payloads and extracts version safely', () {
      expect(QrCodec.tryParse(''), isNull);
      expect(QrCodec.tryParse('RD2|$siteId|$checkpointId|1|${'a' * 64}'), isNull);
      expect(QrCodec.tryParse('RD1|not-a-uuid|$checkpointId|1|${'a' * 64}'), isNull);
      expect(QrCodec.tryParse('RD1|$siteId|$checkpointId|0|${'a' * 64}'), isNull);
      expect(QrCodec.tryParse('RD1|$siteId|$checkpointId|1|short-sig'), isNull);

      expect(QrCodec.extractVersionOrZero('RD1|$siteId|$checkpointId|4|bad'), 4);
      expect(QrCodec.extractVersionOrZero('corrupt'), 0);
    });
  });
}
