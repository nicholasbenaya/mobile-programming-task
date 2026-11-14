import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/domain/ronda/services/qr_token_verifier.dart';

void main() {
  group('QrTokenVerifier Tests (Validasi Token QR Bertanda Waktu)', () {
    const checkpointId = 'CP-POS-01';
    const secretKey = 'kunci-rahasia-pos-ronda-its-01';

    test('Payload QR valid terverifikasi dengan sukses', () {
      final now = DateTime.now();
      final payload = QrTokenVerifier.generateQrPayload(
        checkpointId: checkpointId,
        secretKey: secretKey,
        timestamp: now,
      );

      final result = QrTokenVerifier.verifyPayload(
        payload: payload,
        expectedCheckpointId: checkpointId,
        secretKey: secretKey,
        currentTime: now,
      );

      expect(result.isValid, isTrue);
      expect(result.checkpointId, equals(checkpointId));
      expect(result.rejectionReason, isNull);
    });

    test('Payload QR ditolak jika telah kadaluarsa (> 180 detik)', () {
      final pastTime = DateTime.now().subtract(const Duration(seconds: 300)); // 5 menit lalu
      final payload = QrTokenVerifier.generateQrPayload(
        checkpointId: checkpointId,
        secretKey: secretKey,
        timestamp: pastTime,
      );

      final result = QrTokenVerifier.verifyPayload(
        payload: payload,
        expectedCheckpointId: checkpointId,
        secretKey: secretKey,
        currentTime: DateTime.now(),
        toleranceSeconds: 180,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('kadaluarsa'));
    });

    test('Payload QR ditolak jika tanda tangan digital / signature dipalsukan', () {
      final now = DateTime.now();
      final validPayload = QrTokenVerifier.generateQrPayload(
        checkpointId: checkpointId,
        secretKey: secretKey,
        timestamp: now,
      );

      // Ubah satu karakter di signature
      final parts = validPayload.split('|');
      parts[4] = '0000000000000000000000000000000000000000000000000000000000000000';
      final tamperedPayload = parts.join('|');

      final result = QrTokenVerifier.verifyPayload(
        payload: tamperedPayload,
        expectedCheckpointId: checkpointId,
        secretKey: secretKey,
        currentTime: now,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('tidak valid'));
    });

    test('Payload QR ditolak jika discan untuk pos/checkpoint yang berbeda', () {
      final now = DateTime.now();
      final payloadPos1 = QrTokenVerifier.generateQrPayload(
        checkpointId: 'CP-POS-01',
        secretKey: secretKey,
        timestamp: now,
      );

      final result = QrTokenVerifier.verifyPayload(
        payload: payloadPos1,
        expectedCheckpointId: 'CP-POS-02', // Mengharapkan Pos 2
        secretKey: secretKey,
        currentTime: now,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('bukan pos yang dituju'));
    });

    test('Payload string sembarang ditolak sebagai format cacat', () {
      final result = QrTokenVerifier.verifyPayload(
        payload: 'https://example.com/qr-biasa',
        expectedCheckpointId: checkpointId,
        secretKey: secretKey,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('Format QR Code tidak dikenali'));
    });
  });
}
