import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/data/local/offline_queue_dao.dart';
import 'package:ronda_app/data/remote/dto_mappers.dart';
import 'package:ronda_app/data/remote/supabase_client_provider.dart';
import 'package:ronda_app/domain/models/checkin.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connectivity abstraction for automatic sync triggering on network restoration.
abstract interface class ConnectivityMonitor {
  Future<bool> isOnline();
  Stream<bool> watchOnlineChanges();
}

class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> watchOnlineChanges() {
    return _connectivity.onConnectivityChanged.map(_hasConnection).distinct();
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}

/// Remote uploader contract used by [SyncWorker] to flush queued check-ins idempotently.
abstract interface class CheckinRemoteUploader {
  Future<void> uploadEvidencePhoto({
    required String storagePath,
    required Uint8List bytes,
  });

  Future<PatrolCheckin> submitCheckinRpc(Map<String, dynamic> payload);
}

class SupabaseCheckinRemoteUploader implements CheckinRemoteUploader {
  const SupabaseCheckinRemoteUploader(this._client);

  static const String patrolEvidenceBucket = 'patrol-evidence';

  final SupabaseClient _client;

  @override
  Future<void> uploadEvidencePhoto({
    required String storagePath,
    required Uint8List bytes,
  }) async {
    try {
      await _client.storage.from(patrolEvidenceBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<PatrolCheckin> submitCheckinRpc(Map<String, dynamic> payload) async {
    try {
      final result = await _client.rpc(
        'submit_patrol_checkin',
        params: <String, dynamic>{'p_payload': payload},
      );
      return DtoMappers.patrolCheckinFromMap(
        Map<String, dynamic>.from(result as Map),
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}

typedef LocalPhotoReader = Future<Uint8List> Function(String path);
typedef LocalPhotoDeleter = Future<void> Function(String path);

/// FIFO offline sync worker with connectivity listener, idempotent photo/RPC upload,
/// and exponential backoff (5s, 15s, 45s, max 5m).
class SyncWorker {
  SyncWorker({
    required this._queueStore,
    required this._uploader,
    ConnectivityMonitor? connectivityMonitor,
    LocalPhotoReader? photoReader,
    LocalPhotoDeleter? photoDeleter,
    DateTime Function()? clock,
  })  : _connectivityMonitor = connectivityMonitor ?? ConnectivityPlusMonitor(),
        _photoReader = photoReader ?? _defaultReadFile,
        _photoDeleter = photoDeleter ?? _defaultDeleteFile,
        _clock = clock ?? _defaultUtcClock;

  final OfflineQueueStore _queueStore;
  final CheckinRemoteUploader _uploader;
  final ConnectivityMonitor _connectivityMonitor;
  final LocalPhotoReader _photoReader;
  final LocalPhotoDeleter _photoDeleter;
  final DateTime Function() _clock;

  StreamSubscription<bool>? _connectivitySubscription;
  Future<SyncRunSummary>? _activeRun;

  static DateTime _defaultUtcClock() => DateTime.now().toUtc();

  static Future<Uint8List> _defaultReadFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const StorageFailure(
        message: 'Foto bukti lokal tidak ditemukan untuk disinkronkan.',
        code: 'OFFLINE_PHOTO_MISSING',
      );
    }
    return file.readAsBytes();
  }

  static Future<void> _defaultDeleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup after server confirmation.
    }
  }

  /// Exponential retry delay: 5s -> 15s -> 45s -> capped at 5 minutes (300s).
  static Duration backoffForRetry(int retryCount) {
    if (retryCount <= 1) {
      return const Duration(seconds: 5);
    }
    if (retryCount == 2) {
      return const Duration(seconds: 15);
    }
    if (retryCount == 3) {
      return const Duration(seconds: 45);
    }
    return const Duration(minutes: 5);
  }

  /// Starts watching connectivity changes and flushes queued records automatically when online.
  void start() {
    if (_connectivitySubscription != null) {
      return;
    }
    _connectivitySubscription =
        _connectivityMonitor.watchOnlineChanges().listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });
  }

  /// Processes queued offline check-ins FIFO. Deduplicates concurrent sync invocations.
  Future<SyncRunSummary> syncNow({bool ignoreBackoff = false}) {
    final ongoing = _activeRun;
    if (ongoing != null) {
      return ongoing;
    }
    final run = _executeSync(ignoreBackoff: ignoreBackoff);
    _activeRun = run;
    return run.whenComplete(() {
      _activeRun = null;
    });
  }

  Future<SyncRunSummary> _executeSync({required bool ignoreBackoff}) async {
    final now = _clock().toUtc();
    final dueItems = await _queueStore.fetchPendingCheckins(
      dueBefore: ignoreBackoff ? null : now,
    );

    if (dueItems.isEmpty) {
      final remaining = await _queueStore.fetchPendingCheckins();
      return SyncRunSummary(
        syncedCount: 0,
        failedCount: 0,
        remainingCount: remaining.length,
      );
    }

    var syncedCount = 0;
    var failedCount = 0;

    for (final item in dueItems) {
      try {
        await _queueStore.updateCheckinState(
          clientEventId: item.clientEventId,
          syncState: OfflineSyncState.uploadingPhoto,
          clearLastError: true,
        );

        final photoBytes = await _photoReader(item.localPhotoPath);
        final storagePath = item.storagePhotoPath;

        await _uploader.uploadEvidencePhoto(
          storagePath: storagePath,
          bytes: photoBytes,
        );

        await _queueStore.updateCheckinState(
          clientEventId: item.clientEventId,
          syncState: OfflineSyncState.submitting,
        );

        await _uploader.submitCheckinRpc(<String, dynamic>{
          'client_event_id': item.clientEventId,
          'site_id': item.siteId,
          'checkpoint_id': item.checkpointId,
          if (item.scheduleId != null) 'schedule_id': item.scheduleId,
          'qr_raw_payload': item.qrRawPayload,
          'photo_path': storagePath,
          'photo_sha256': item.photoSha256,
          'captured_at_client': item.capturedAtClient.toUtc().toIso8601String(),
          'latitude': item.latitude,
          'longitude': item.longitude,
          'accuracy_m': item.accuracyMeters,
          'is_mocked': item.isMocked,
          'is_offline_submission': true,
          if (item.deviceModel != null) 'device_model': item.deviceModel,
          'officer_note': item.officerNote,
        });

        await _queueStore.updateCheckinState(
          clientEventId: item.clientEventId,
          syncState: OfflineSyncState.synced,
          clearNextRetryAt: true,
          clearLastError: true,
        );
        // Delete local temporary photo strictly after server confirms 200.
        await _photoDeleter(item.localPhotoPath);
        syncedCount++;
      } catch (error, stackTrace) {
        final failure = mapSupabaseError(error, stackTrace);
        final nextRetryCount = item.retryCount + 1;
        final nextRetryAt =
            _clock().toUtc().add(backoffForRetry(nextRetryCount));

        await _queueStore.updateCheckinState(
          clientEventId: item.clientEventId,
          syncState: OfflineSyncState.failed,
          retryCount: nextRetryCount,
          nextRetryAt: nextRetryAt,
          lastError: failure.message,
        );
        failedCount++;
      }
    }

    final remaining = await _queueStore.fetchPendingCheckins();
    return SyncRunSummary(
      syncedCount: syncedCount,
      failedCount: failedCount,
      remainingCount: remaining.length,
    );
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
