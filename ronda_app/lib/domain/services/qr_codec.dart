import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ronda_app/domain/models/checkpoint.dart';

/// Parsed components of a RondaDigital v1 checkpoint QR payload.
class ParsedCheckpointQr {
  const ParsedCheckpointQr({
    required this.siteId,
    required this.checkpointId,
    required this.tokenVersion,
    required this.signature,
    required this.rawPayload,
  });

  final String siteId;
  final String checkpointId;
  final int tokenVersion;
  final String signature;
  final String rawPayload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedCheckpointQr &&
          other.siteId == siteId &&
          other.checkpointId == checkpointId &&
          other.tokenVersion == tokenVersion &&
          other.signature == signature &&
          other.rawPayload == rawPayload;

  @override
  int get hashCode =>
      Object.hash(siteId, checkpointId, tokenVersion, signature, rawPayload);
}

/// Codec for signed checkpoint QR strings:
/// `RD1|<site_id>|<checkpoint_id>|<token_version>|<hmac_sha256_hex>`.
abstract final class QrCodec {
  static const String prefix = 'RD1';
  static final RegExp _hex64Pattern = RegExp(r'^[0-9a-fA-F]{64}$');
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Computes lowercase hex HMAC-SHA256 matching `public.compute_checkpoint_qr_hmac`.
  static String computeSignature({
    required String siteId,
    required String checkpointId,
    required int tokenVersion,
    required String secret,
  }) {
    final signingInput = '$prefix|$siteId|$checkpointId|$tokenVersion';
    final hmacSha256 = Hmac(sha256, utf8.encode(secret));
    return hmacSha256.convert(utf8.encode(signingInput)).toString().toLowerCase();
  }

  static String encode({
    required String siteId,
    required String checkpointId,
    required int tokenVersion,
    required String secret,
  }) {
    if (tokenVersion < 1) {
      throw ArgumentError.value(
        tokenVersion,
        'tokenVersion',
        'Versi token QR minimal 1.',
      );
    }
    final signature = computeSignature(
      siteId: siteId,
      checkpointId: checkpointId,
      tokenVersion: tokenVersion,
      secret: secret,
    );
    return '$prefix|$siteId|$checkpointId|$tokenVersion|$signature';
  }

  /// Parses [rawPayload], returning `null` if format, UUIDs, version, or signature length is invalid.
  static ParsedCheckpointQr? tryParse(String rawPayload) {
    final trimmed = rawPayload.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parts = trimmed.split('|');
    if (parts.length != 5 || parts[0] != prefix) {
      return null;
    }

    final siteId = parts[1];
    final checkpointId = parts[2];
    final versionRaw = parts[3];
    final signature = parts[4];

    if (!_uuidPattern.hasMatch(siteId) || !_uuidPattern.hasMatch(checkpointId)) {
      return null;
    }

    final tokenVersion = int.tryParse(versionRaw);
    if (tokenVersion == null || tokenVersion < 1) {
      return null;
    }

    if (!_hex64Pattern.hasMatch(signature)) {
      return null;
    }

    return ParsedCheckpointQr(
      siteId: siteId.toLowerCase(),
      checkpointId: checkpointId.toLowerCase(),
      tokenVersion: tokenVersion,
      signature: signature.toLowerCase(),
      rawPayload: trimmed,
    );
  }

  /// Extracts a numeric token version even when the overall QR payload is malformed or revoked.
  static int extractVersionOrZero(String rawPayload) {
    final parts = rawPayload.trim().split('|');
    if (parts.length >= 4) {
      final parsed = int.tryParse(parts[3]);
      if (parsed != null && parsed >= 0) {
        return parsed;
      }
    }
    return 0;
  }

  /// Constant-time HMAC verification against [secret].
  static bool verifySignature({
    required ParsedCheckpointQr qr,
    required String secret,
  }) {
    if (secret.isEmpty) {
      return false;
    }
    final expected = computeSignature(
      siteId: qr.siteId,
      checkpointId: qr.checkpointId,
      tokenVersion: qr.tokenVersion,
      secret: secret,
    );
    return _constantTimeEquals(qr.signature.toLowerCase(), expected);
  }

  /// Verifies that [qr] matches an active [checkpoint]'s site, ID, and current token version.
  static bool matchesCheckpoint({
    required ParsedCheckpointQr qr,
    required Checkpoint checkpoint,
  }) {
    return checkpoint.isActive &&
        qr.siteId == checkpoint.siteId.toLowerCase() &&
        qr.checkpointId == checkpoint.id.toLowerCase() &&
        qr.tokenVersion == checkpoint.qrTokenVersion;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
