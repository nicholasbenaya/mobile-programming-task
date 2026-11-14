import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Hasil Evaluasi QR Code Bertanda Waktu
class QrValidationResult {
  const QrValidationResult({
    required this.isValid,
    this.checkpointId,
    this.timestamp,
    this.rejectionReason,
  });

  final bool isValid;
  final String? checkpointId;
  final DateTime? timestamp;
  final String? rejectionReason;

  @override
  String toString() {
    if (isValid) {
      return 'QR VALID: Checkpoint $checkpointId, timestamp: $timestamp';
    }
    return 'QR INVALID: $rejectionReason';
  }
}

/// Mesin Pembuat & Verifikator Token QR Checkpoint Bertanda Waktu (Anti-Titip Absen)
class QrTokenVerifier {
  const QrTokenVerifier._();

  static const String prefixHeader = 'RONDA|v1';

  /// Batas toleransi usia QR dalam detik (default 180 detik = 3 menit)
  static const int defaultTimeWindowSeconds = 180;

  /// Menghasilkan payload QR terenkripsi yang bertanda waktu
  static String generateQrPayload({
    required String checkpointId,
    required String secretKey,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final epoch = now.millisecondsSinceEpoch ~/ 1000;
    final signature = _computeSignature(checkpointId, epoch, secretKey);

    return '$prefixHeader|$checkpointId|$epoch|$signature';
  }

  /// Memverifikasi keabsahan payload QR terhadap secretKey checkpoint dan waktu saat ini
  static QrValidationResult verifyPayload({
    required String payload,
    required String expectedCheckpointId,
    required String secretKey,
    DateTime? currentTime,
    int toleranceSeconds = defaultTimeWindowSeconds,
  }) {
    final parts = payload.split('|');

    if (parts.length != 5 || '${parts[0]}|${parts[1]}' != prefixHeader) {
      return const QrValidationResult(
        isValid: false,
        rejectionReason: 'Format QR Code tidak dikenali atau bukan QR resmi Ronda Digital.',
      );
    }

    final scannedCheckpointId = parts[2];
    final epochStr = parts[3];
    final scannedSignature = parts[4];

    // Cek kesesuaian checkpoint ID
    if (scannedCheckpointId != expectedCheckpointId) {
      return QrValidationResult(
        isValid: false,
        rejectionReason: 'QR Code ini milik pos/checkpoint lain ($scannedCheckpointId), bukan pos yang dituju ($expectedCheckpointId).',
      );
    }

    final epoch = int.tryParse(epochStr);
    if (epoch == null) {
      return const QrValidationResult(
        isValid: false,
        rejectionReason: 'Timestamp pada QR Code cacat atau tidak valid.',
      );
    }

    final qrTime = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    final now = currentTime ?? DateTime.now();
    final driftSeconds = (now.millisecondsSinceEpoch ~/ 1000 - epoch).abs();

    // Cek batas kedaluwarsa waktu
    if (driftSeconds > toleranceSeconds) {
      return QrValidationResult(
        isValid: false,
        rejectionReason: 'QR Code telah kadaluarsa ($driftSeconds detik lalu, batas toleransi: $toleranceSeconds detik). Silakan muat ulang QR.',
      );
    }

    // Cek integritas cryptographic signature
    final expectedSignature = _computeSignature(scannedCheckpointId, epoch, secretKey);
    if (scannedSignature != expectedSignature) {
      return const QrValidationResult(
        isValid: false,
        rejectionReason: 'Tanda tangan digital QR Code tidak valid (kemungkinan kode palsu atau telah dimodifikasi).',
      );
    }

    return QrValidationResult(
      isValid: true,
      checkpointId: scannedCheckpointId,
      timestamp: qrTime,
    );
  }

  static String _computeSignature(String checkpointId, int epoch, String secretKey) {
    final rawString = '$checkpointId:$epoch:$secretKey';
    final bytes = utf8.encode(rawString);
    return sha256.convert(bytes).toString();
  }
}
