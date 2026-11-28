import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/data/local/offline_queue_dao.dart';
import 'package:ronda_app/data/remote/dto_mappers.dart';
import 'package:ronda_app/data/remote/supabase_client_provider.dart';
import 'package:ronda_app/data/services/sync_worker.dart';
import 'package:ronda_app/domain/models/checkin.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/repositories/checkin_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote Supabase abstraction for check-ins, admin audit queries, signed URLs, and reviews.
abstract interface class CheckinRemoteDataSource implements CheckinRemoteUploader {
  String? get currentUserId;

  Stream<List<Map<String, dynamic>>> watchShiftCheckinRows({
    required String siteId,
    DateTime? since,
    String? officerId,
  });

  Future<List<Map<String, dynamic>>> fetchAuditQueueRows({
    required String siteId,
    required AuditQueueFilter filter,
  });

  Future<String> createEvidenceSignedUrl({
    required String storagePath,
    required int expiresInSeconds,
  });

  Future<Map<String, dynamic>> rpcReviewPatrolCheckin({
    required String checkinId,
    required String decision,
    required String reviewNote,
  });

  Future<List<Map<String, dynamic>>> fetchCheckinAuditLogRows(String checkinId);
}

class _SupabaseCheckinRemoteDataSource implements CheckinRemoteDataSource {
  const _SupabaseCheckinRemoteDataSource(this._client);

  static const String _checkinSelect =
      '*, checkpoints(code, name), officer:profiles!patrol_checkins_officer_id_fkey(full_name)';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> uploadEvidencePhoto({
    required String storagePath,
    required Uint8List bytes,
  }) async {
    await _client.storage
        .from(SupabaseCheckinRemoteUploader.patrolEvidenceBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
  }

  @override
  Future<PatrolCheckin> submitCheckinRpc(Map<String, dynamic> payload) async {
    final result = await _client.rpc(
      'submit_patrol_checkin',
      params: <String, dynamic>{'p_payload': payload},
    );
    return DtoMappers.patrolCheckinFromMap(
      Map<String, dynamic>.from(result as Map),
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchShiftCheckinRows({
    required String siteId,
    DateTime? since,
    String? officerId,
  }) {
    late final StreamController<List<Map<String, dynamic>>> controller;
    RealtimeChannel? channel;

    Future<void> emitLatest() async {
      try {
        var query = _client
            .from('patrol_checkins')
            .select(_checkinSelect)
            .eq('site_id', siteId);

        if (since != null) {
          query = query.gte(
            'captured_at_client',
            since.toUtc().toIso8601String(),
          );
        }
        if (officerId != null) {
          query = query.eq('officer_id', officerId);
        }

        final rows = await query.order('captured_at_client', ascending: false);
        if (!controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(rows));
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(mapSupabaseError(error, stackTrace), stackTrace);
        }
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        emitLatest();
        channel = _client
            .channel('patrol_checkins:$siteId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'patrol_checkins',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'site_id',
                value: siteId,
              ),
              callback: (_) => emitLatest(),
            )
            .subscribe();
      },
      onCancel: () async {
        final active = channel;
        if (active != null) {
          await _client.removeChannel(active);
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAuditQueueRows({
    required String siteId,
    required AuditQueueFilter filter,
  }) async {
    var query = _client
        .from('patrol_checkins')
        .select(_checkinSelect)
        .eq('site_id', siteId);

    final effectiveStatuses = filter.effectiveStatuses;
    if (effectiveStatuses != null && effectiveStatuses.isNotEmpty) {
      query = query.inFilter(
        'effective_status',
        effectiveStatuses.map((s) => s.value).toList(growable: false),
      );
    }
    if (filter.autoStatus != null) {
      query = query.eq('auto_status', filter.autoStatus!.value);
    }
    if (filter.manualStatus != null) {
      query = query.eq('manual_status', filter.manualStatus!.value);
    }
    if (filter.officerId != null) {
      query = query.eq('officer_id', filter.officerId!);
    }
    if (filter.checkpointId != null) {
      query = query.eq('checkpoint_id', filter.checkpointId!);
    }
    if (filter.fromDate != null) {
      query = query.gte(
        'captured_at_client',
        filter.fromDate!.toUtc().toIso8601String(),
      );
    }
    if (filter.toDate != null) {
      query = query.lte(
        'captured_at_client',
        filter.toDate!.toUtc().toIso8601String(),
      );
    }

    final rows = await query
        .order('captured_at_client', ascending: false)
        .limit(filter.limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<String> createEvidenceSignedUrl({
    required String storagePath,
    required int expiresInSeconds,
  }) {
    return _client.storage
        .from(SupabaseCheckinRemoteUploader.patrolEvidenceBucket)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  @override
  Future<Map<String, dynamic>> rpcReviewPatrolCheckin({
    required String checkinId,
    required String decision,
    required String reviewNote,
  }) async {
    final result = await _client.rpc(
      'review_patrol_checkin',
      params: <String, dynamic>{
        'p_checkin_id': checkinId,
        'p_decision': decision,
        'p_review_note': reviewNote,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCheckinAuditLogRows(
    String checkinId,
  ) async {
    final rows = await _client
        .from('checkin_audit_logs')
        .select('*, profiles(full_name)')
        .eq('checkin_id', checkinId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
}

class _CachedSignedUrl {
  const _CachedSignedUrl({required this.url, required this.expiresAtUtc});

  final String url;
  final DateTime expiresAtUtc;
}

/// Offline-first [CheckinRepository] combining Supabase RPCs, SQLite queue fallback,
/// signed evidence URL caching, and Admin manual audit override.
class OfflineCheckinRepository implements CheckinRepository {
  OfflineCheckinRepository({
    required SupabaseClient client,
    required OfflineQueueStore queueStore,
    required SyncWorker syncWorker,
    ConnectivityMonitor? connectivityMonitor,
    LocalPhotoReader? photoReader,
    LocalPhotoDeleter? photoDeleter,
    DateTime Function()? clock,
  }) : this.withDataSource(
          remoteDataSource: _SupabaseCheckinRemoteDataSource(client),
          queueStore: queueStore,
          syncWorker: syncWorker,
          connectivityMonitor: connectivityMonitor,
          photoReader: photoReader,
          photoDeleter: photoDeleter,
          clock: clock,
        );

  OfflineCheckinRepository.withDataSource({
    required CheckinRemoteDataSource remoteDataSource,
    required this._queueStore,
    required this._syncWorker,
    ConnectivityMonitor? connectivityMonitor,
    LocalPhotoReader? photoReader,
    LocalPhotoDeleter? photoDeleter,
    DateTime Function()? clock,
  })  : _remote = remoteDataSource,
        _connectivityMonitor = connectivityMonitor ?? ConnectivityPlusMonitor(),
        _photoReader = photoReader ?? _defaultReadPhoto,
        _photoDeleter = photoDeleter ?? _defaultDeletePhoto,
        _clock = clock ?? _defaultUtcClock;

  final CheckinRemoteDataSource _remote;
  final OfflineQueueStore _queueStore;
  final SyncWorker _syncWorker;
  final ConnectivityMonitor _connectivityMonitor;
  final LocalPhotoReader _photoReader;
  final LocalPhotoDeleter _photoDeleter;
  final DateTime Function() _clock;
  final Map<String, _CachedSignedUrl> _signedUrlCache =
      <String, _CachedSignedUrl>{};

  static DateTime _defaultUtcClock() => DateTime.now().toUtc();

  static Future<Uint8List> _defaultReadPhoto(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const StorageFailure(
        message: 'Foto bukti tidak ditemukan di perangkat.',
        code: 'LOCAL_PHOTO_MISSING',
      );
    }
    return file.readAsBytes();
  }

  static Future<void> _defaultDeletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup after server confirmation.
    }
  }

  @override
  Future<CheckinSubmitOutcome> submitCheckin(
    CheckinSubmissionDraft draft,
  ) async {
    final officerId = _remote.currentUserId;
    if (officerId == null || officerId.isEmpty) {
      throw const AuthFailure(
        message: 'Silakan masuk terlebih dahulu sebelum mengirim check-in.',
        code: 'AUTH_REQUIRED',
      );
    }

    final storagePath =
        '${draft.siteId}/checkins/$officerId/${draft.clientEventId}.jpg';
    final isOnline = await _connectivityMonitor.isOnline();

    if (!isOnline) {
      return _enqueueOffline(draft: draft, officerId: officerId);
    }

    try {
      final photoBytes = await _photoReader(draft.localPhotoPath);
      await _remote.uploadEvidencePhoto(
        storagePath: storagePath,
        bytes: photoBytes,
      );

      final synced = await _remote.submitCheckinRpc(<String, dynamic>{
        'client_event_id': draft.clientEventId,
        'site_id': draft.siteId,
        'checkpoint_id': draft.checkpointId,
        if (draft.scheduleId != null) 'schedule_id': draft.scheduleId,
        'qr_raw_payload': draft.qrRawPayload,
        'photo_path': storagePath,
        'photo_sha256': draft.photoSha256,
        'captured_at_client': draft.capturedAtClient.toUtc().toIso8601String(),
        'latitude': draft.latitude,
        'longitude': draft.longitude,
        'accuracy_m': draft.accuracyMeters,
        'is_mocked': draft.isMocked,
        'is_offline_submission': false,
        if (draft.deviceModel != null) 'device_model': draft.deviceModel,
        'officer_note': draft.officerNote.trim(),
      });

      await _photoDeleter(draft.localPhotoPath);
      return CheckinSubmitOutcome(syncedCheckin: synced);
    } catch (error, stackTrace) {
      final failure = mapSupabaseError(error, stackTrace);
      if (failure is NetworkFailure) {
        return _enqueueOffline(
          draft: draft,
          officerId: officerId,
          lastError: failure.message,
        );
      }
      throw failure;
    }
  }

  Future<CheckinSubmitOutcome> _enqueueOffline({
    required CheckinSubmissionDraft draft,
    required String officerId,
    String? lastError,
  }) async {
    final record = QueuedCheckinRecord(
      clientEventId: draft.clientEventId,
      siteId: draft.siteId,
      checkpointId: draft.checkpointId,
      scheduleId: draft.scheduleId,
      officerId: officerId,
      qrRawPayload: draft.qrRawPayload,
      localPhotoPath: draft.localPhotoPath,
      photoSha256: draft.photoSha256,
      capturedAtClient: draft.capturedAtClient.toUtc(),
      monotonicMs: draft.monotonicMs,
      latitude: draft.latitude,
      longitude: draft.longitude,
      accuracyMeters: draft.accuracyMeters,
      isMocked: draft.isMocked,
      deviceModel: draft.deviceModel,
      officerNote: draft.officerNote.trim(),
      syncState: OfflineSyncState.pending,
      retryCount: 0,
      lastError: lastError,
      createdAt: _clock().toUtc(),
    );
    await _queueStore.enqueueCheckin(record);
    return CheckinSubmitOutcome(queuedItem: record.toOfflineQueueItem());
  }

  @override
  Stream<List<PatrolCheckin>> watchShiftCheckins({
    required String siteId,
    DateTime? since,
    String? officerId,
  }) {
    return _remote
        .watchShiftCheckinRows(
          siteId: siteId,
          since: since,
          officerId: officerId,
        )
        .map(
          (rows) => rows
              .map(DtoMappers.patrolCheckinFromMap)
              .toList(growable: false),
        );
  }

  @override
  Stream<int> watchPendingOfflineCount(String siteId) {
    return _queueStore.watchPendingCheckinCount(siteId);
  }

  @override
  Future<List<OfflineQueueItem>> fetchPendingOfflineItems(String siteId) async {
    final records = await _queueStore.fetchPendingCheckins(siteId: siteId);
    return records
        .map((r) => r.toOfflineQueueItem())
        .toList(growable: false);
  }

  @override
  Future<SyncRunSummary> syncNow() {
    return _syncWorker.syncNow(ignoreBackoff: true);
  }

  @override
  Future<List<PatrolCheckin>> fetchAuditQueue({
    required String siteId,
    AuditQueueFilter filter = const AuditQueueFilter(),
  }) async {
    try {
      final rows = await _remote.fetchAuditQueueRows(
        siteId: siteId,
        filter: filter,
      );
      return rows
          .map(DtoMappers.patrolCheckinFromMap)
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<String> getEvidenceSignedUrl(
    String storagePath, {
    Duration expiresIn = const Duration(minutes: 15),
  }) async {
    final normalizedPath = storagePath.trim();
    if (normalizedPath.isEmpty) {
      throw const ValidationFailure(
        message: 'Path foto bukti tidak valid.',
        code: 'INVALID_STORAGE_PATH',
      );
    }

    final now = _clock().toUtc();
    final cached = _signedUrlCache[normalizedPath];
    // Reuse cached signed URL while at least 60 seconds remain before expiry.
    if (cached != null &&
        cached.expiresAtUtc.isAfter(now.add(const Duration(seconds: 60)))) {
      return cached.url;
    }

    try {
      final seconds = expiresIn.inSeconds.clamp(60, 86400);
      final signedUrl = await _remote.createEvidenceSignedUrl(
        storagePath: normalizedPath,
        expiresInSeconds: seconds,
      );
      _signedUrlCache[normalizedPath] = _CachedSignedUrl(
        url: signedUrl,
        expiresAtUtc: now.add(Duration(seconds: seconds)),
      );
      return signedUrl;
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<PatrolCheckin> reviewCheckinManual({
    required String checkinId,
    required ManualReviewStatus decision,
    required String reviewNote,
  }) async {
    final trimmedNote = reviewNote.trim();
    if (trimmedNote.length < 5) {
      throw const ValidationFailure(
        message: 'Catatan audit manual minimal 5 karakter.',
        code: 'REVIEW_NOTE_TOO_SHORT',
      );
    }

    try {
      final row = await _remote.rpcReviewPatrolCheckin(
        checkinId: checkinId,
        decision: decision.value,
        reviewNote: trimmedNote,
      );
      return DtoMappers.patrolCheckinFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<List<CheckinAuditLog>> fetchCheckinAuditLogs(String checkinId) async {
    try {
      final rows = await _remote.fetchCheckinAuditLogRows(checkinId);
      return rows
          .map(DtoMappers.checkinAuditLogFromMap)
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}
