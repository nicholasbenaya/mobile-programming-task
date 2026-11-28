import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ronda_app/core/errors/app_failure.dart';

/// Forensic evidence photo persisted locally after compression and SHA-256 hashing.
class ProcessedForensicPhoto {
  const ProcessedForensicPhoto({
    required this.localFilePath,
    required this.sha256Hex,
    required this.sizeBytes,
    required this.capturedAtUtc,
    required this.monotonicMs,
  });

  final String localFilePath;
  final String sha256Hex;
  final int sizeBytes;
  final DateTime capturedAtUtc;
  final int monotonicMs;
}

typedef ImageBytesCompressor = Future<Uint8List?> Function({
  required String sourcePath,
  required int maxDimension,
  required int quality,
});

typedef EvidenceDirectoryProvider = Future<Directory> Function();

/// Captures live camera photos, compresses JPEG <= 1600px / q78 (<= 2 MB),
/// persists to durable offline storage, and computes SHA-256 digest before upload.
class ForensicPhotoService {
  ForensicPhotoService({
    ImagePicker? imagePicker,
    ImageBytesCompressor? compressor,
    EvidenceDirectoryProvider? directoryProvider,
    DateTime Function()? clock,
    Stopwatch? monotonicClock,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _compressor = compressor ?? _defaultCompress,
        _directoryProvider = directoryProvider ?? _defaultEvidenceDirectory,
        _clock = clock ?? _defaultUtcClock,
        _stopwatch = monotonicClock ?? (Stopwatch()..start());

  static const int maxLongestEdgePx = 1600;
  static const int defaultJpegQuality = 78;
  static const int fallbackLongestEdgePx = 1280;
  static const int fallbackJpegQuality = 60;
  static const int hardMaxBytes = 2 * 1024 * 1024;

  final ImagePicker _imagePicker;
  final ImageBytesCompressor _compressor;
  final EvidenceDirectoryProvider _directoryProvider;
  final DateTime Function() _clock;
  final Stopwatch _stopwatch;

  static DateTime _defaultUtcClock() => DateTime.now().toUtc();

  static Future<Uint8List?> _defaultCompress({
    required String sourcePath,
    required int maxDimension,
    required int quality,
  }) {
    return FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
  }

  static Future<Directory> _defaultEvidenceDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory(p.join(appDir.path, 'ronda_offline_evidence'));
    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }
    return evidenceDir;
  }

  /// Computes lowercase 64-character hex SHA-256 digest over raw bytes.
  static String computeSha256Hex(Uint8List bytes) {
    return sha256.convert(bytes).toString().toLowerCase();
  }

  /// Opens the live device camera exclusively (gallery import disabled for patrol check-ins).
  /// Returns `null` if the officer cancels camera capture.
  Future<ProcessedForensicPhoto?> captureLivePhotoAndProcess({
    required String clientEventId,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 92,
      );
      if (picked == null) {
        return null;
      }
      return await processImageFile(
        sourceFilePath: picked.path,
        clientEventId: clientEventId,
        deleteSourceAfterCopy: true,
      );
    } catch (error, stackTrace) {
      if (error is AppFailure) {
        rethrow;
      }
      throw StorageFailure(
        message: 'Gagal mengambil foto bukti dari kamera perangkat.',
        code: 'CAMERA_CAPTURE_FAILED',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Compresses [sourceFilePath], enforces the 2 MB hard cap, persists durably,
  /// and computes SHA-256 over the final compressed JPEG bytes.
  Future<ProcessedForensicPhoto> processImageFile({
    required String sourceFilePath,
    required String clientEventId,
    bool deleteSourceAfterCopy = false,
  }) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw const StorageFailure(
        message: 'Berkas foto bukti tidak ditemukan di perangkat.',
        code: 'PHOTO_SOURCE_MISSING',
      );
    }

    try {
      var compressed = await _compressor(
        sourcePath: sourceFilePath,
        maxDimension: maxLongestEdgePx,
        quality: defaultJpegQuality,
      );

      if (compressed == null || compressed.isEmpty) {
        compressed = await sourceFile.readAsBytes();
      }

      if (compressed.length > hardMaxBytes) {
        final fallback = await _compressor(
          sourcePath: sourceFilePath,
          maxDimension: fallbackLongestEdgePx,
          quality: fallbackJpegQuality,
        );
        if (fallback != null && fallback.isNotEmpty) {
          compressed = fallback;
        }
      }

      if (compressed.isEmpty) {
        throw const ValidationFailure(
          message: 'Foto bukti kosong atau rusak. Ambil ulang foto patroli.',
          code: 'PHOTO_EMPTY',
        );
      }

      if (compressed.length > hardMaxBytes) {
        throw const ValidationFailure(
          message:
              'Ukuran foto melebihi batas maksimal 2 MB setelah kompresi. Ambil ulang foto dengan pencahayaan lebih jelas.',
          code: 'PHOTO_TOO_LARGE',
        );
      }

      final evidenceDir = await _directoryProvider();
      if (!await evidenceDir.exists()) {
        await evidenceDir.create(recursive: true);
      }

      final safeId = clientEventId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetPath = p.join(evidenceDir.path, '$safeId.jpg');
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(compressed, flush: true);

      final digestHex = computeSha256Hex(compressed);
      final capturedAt = _clock().toUtc();
      final monotonicMs = _stopwatch.elapsedMilliseconds;

      if (deleteSourceAfterCopy && p.normalize(sourceFilePath) != p.normalize(targetPath)) {
        await deleteLocalPhoto(sourceFilePath);
      }

      return ProcessedForensicPhoto(
        localFilePath: targetPath,
        sha256Hex: digestHex,
        sizeBytes: compressed.length,
        capturedAtUtc: capturedAt,
        monotonicMs: monotonicMs,
      );
    } catch (error, stackTrace) {
      if (error is AppFailure) {
        rethrow;
      }
      throw StorageFailure(
        message: 'Gagal memproses dan menyimpan foto bukti secara lokal.',
        code: 'PHOTO_PROCESS_FAILED',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Best-effort cleanup of a temporary local photo once server persistence succeeds.
  Future<void> deleteLocalPhoto(String path) async {
    if (path.trim().isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Non-fatal: stale local files should not fail a confirmed server sync.
    }
  }
}
