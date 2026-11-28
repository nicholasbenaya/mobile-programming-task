import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/data/local/offline_queue_dao.dart';
import 'package:ronda_app/data/repositories/offline_checkin_repository.dart';
import 'package:ronda_app/data/services/forensic_photo_service.dart';
import 'package:ronda_app/data/services/location_service.dart';
import 'package:ronda_app/data/services/sync_worker.dart';
import 'package:ronda_app/domain/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeLocationAdapter implements LocationAdapter {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  Position? positionToReturn;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permission = requestedPermission;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) async {
    return positionToReturn!;
  }

  @override
  Stream<Position> getPositionStream(LocationSettings settings) =>
      Stream<Position>.value(positionToReturn!);
}

class _InMemoryOfflineQueueStore implements OfflineQueueStore {
  final Map<String, QueuedCheckinRecord> _checkins =
      <String, QueuedCheckinRecord>{};
  final Map<String, QueuedReportRecord> _reports =
      <String, QueuedReportRecord>{};
  final Map<String, QueuedHandoverRecord> _handovers =
      <String, QueuedHandoverRecord>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  @override
  Future<void> enqueueCheckin(QueuedCheckinRecord record) async {
    _checkins[record.clientEventId] = record;
    _emit();
  }

  @override
  Future<List<QueuedCheckinRecord>> fetchPendingCheckins({
    String? siteId,
    DateTime? dueBefore,
  }) async {
    final items = _checkins.values.where((item) {
      if (item.syncState == OfflineSyncState.synced) {
        return false;
      }
      if (siteId != null && item.siteId != siteId) {
        return false;
      }
      if (dueBefore != null &&
          item.nextRetryAt != null &&
          item.nextRetryAt!.toUtc().isAfter(dueBefore.toUtc())) {
        return false;
      }
      return true;
    }).toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  @override
  Future<QueuedCheckinRecord?> fetchCheckinById(String clientEventId) async {
    return _checkins[clientEventId];
  }

  @override
  Future<void> updateCheckinState({
    required String clientEventId,
    required OfflineSyncState syncState,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    String? lastError,
    bool clearLastError = false,
  }) async {
    final existing = _checkins[clientEventId];
    if (existing == null) {
      return;
    }
    _checkins[clientEventId] = existing.copyWith(
      syncState: syncState,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      clearNextRetryAt: clearNextRetryAt,
      lastError: lastError,
      clearLastError: clearLastError,
    );
    _emit();
  }

  @override
  Future<void> deleteCheckin(String clientEventId) async {
    _checkins.remove(clientEventId);
    _emit();
  }

  @override
  Future<int> countPendingCheckins(String siteId) async {
    return _checkins.values
        .where(
          (i) => i.siteId == siteId && i.syncState != OfflineSyncState.synced,
        )
        .length;
  }

  @override
  Stream<int> watchPendingCheckinCount(String siteId) {
    late final StreamController<int> controller;
    StreamSubscription<void>? sub;

    Future<void> emitCount() async {
      if (!controller.isClosed) {
        controller.add(await countPendingCheckins(siteId));
      }
    }

    controller = StreamController<int>(
      onListen: () {
        emitCount();
        sub = _changes.stream.listen((_) => emitCount());
      },
      onCancel: () async => sub?.cancel(),
    );
    return controller.stream.distinct();
  }

  @override
  Future<void> enqueueReport(QueuedReportRecord record) async {
    _reports[record.clientEventId] = record;
  }

  @override
  Future<List<QueuedReportRecord>> fetchPendingReports({String? siteId}) async {
    return _reports.values
        .where((r) => siteId == null || r.siteId == siteId)
        .toList();
  }

  @override
  Future<void> deleteReport(String clientEventId) async {
    _reports.remove(clientEventId);
  }

  @override
  Future<void> enqueueHandover(QueuedHandoverRecord record) async {
    _handovers[record.clientEventId] = record;
  }

  @override
  Future<List<QueuedHandoverRecord>> fetchPendingHandovers({
    String? siteId,
  }) async {
    return _handovers.values
        .where((h) => siteId == null || h.siteId == siteId)
        .toList();
  }

  @override
  Future<void> deleteHandover(String clientEventId) async {
    _handovers.remove(clientEventId);
  }

  @override
  Future<void> dispose() async {
    await _changes.close();
  }
}

class _FakeConnectivityMonitor implements ConnectivityMonitor {
  bool online = true;
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> watchOnlineChanges() => controller.stream;
}

class _FakeCheckinRemoteDataSource implements CheckinRemoteDataSource {
  String? userId = 'officer-1';
  Object? nextUploadError;
  Object? nextRpcError;

  final List<String> uploadedPaths = <String>[];
  final List<Map<String, dynamic>> submittedPayloads = <Map<String, dynamic>>[];
  int signedUrlCalls = 0;
  Map<String, dynamic>? lastReviewCall;

  @override
  String? get currentUserId => userId;

  @override
  Future<void> uploadEvidencePhoto({
    required String storagePath,
    required Uint8List bytes,
  }) async {
    final err = nextUploadError;
    if (err != null) {
      nextUploadError = null;
      throw err;
    }
    uploadedPaths.add(storagePath);
  }

  @override
  Future<PatrolCheckin> submitCheckinRpc(Map<String, dynamic> payload) async {
    final err = nextRpcError;
    if (err != null) {
      nextRpcError = null;
      throw err;
    }
    submittedPayloads.add(payload);
    return PatrolCheckin(
      id: 'chk-${payload['client_event_id']}',
      clientEventId: payload['client_event_id'] as String,
      siteId: payload['site_id'] as String,
      checkpointId: payload['checkpoint_id'] as String,
      officerId: userId!,
      qrTokenVersionScanned: 1,
      photoPath: payload['photo_path'] as String,
      photoSha256: payload['photo_sha256'] as String,
      capturedAtClient: DateTime.parse(payload['captured_at_client'] as String),
      syncedAtServer: DateTime.utc(2026, 6, 1, 16, 0, 5),
      latitude: (payload['latitude'] as num).toDouble(),
      longitude: (payload['longitude'] as num).toDouble(),
      accuracyMeters: (payload['accuracy_m'] as num).toDouble(),
      distanceMeters: 5.2,
      isMocked: payload['is_mocked'] as bool,
      isOfflineSubmission: payload['is_offline_submission'] as bool,
      officerNote: payload['officer_note'] as String,
      autoStatus: AutoVerificationStatus.autoVerified,
      flagReasons: const <CheckinFlagReason>[],
      effectiveStatus: EffectiveCheckinStatus.autoVerified,
      createdAt: DateTime.utc(2026, 6, 1, 16, 0, 5),
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchShiftCheckinRows({
    required String siteId,
    DateTime? since,
    String? officerId,
  }) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<List<Map<String, dynamic>>> fetchAuditQueueRows({
    required String siteId,
    required AuditQueueFilter filter,
  }) async {
    final err = nextRpcError;
    if (err != null) {
      nextRpcError = null;
      throw err;
    }
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'chk-1',
        'client_event_id': 'evt-1',
        'site_id': siteId,
        'checkpoint_id': 'cp-1',
        'officer_id': 'officer-1',
        'qr_token_version_scanned': 1,
        'photo_path': '$siteId/checkins/officer-1/evt-1.jpg',
        'photo_sha256': 'a' * 64,
        'captured_at_client': '2026-06-01T15:00:00Z',
        'synced_at_server': '2026-06-01T15:00:05Z',
        'latitude': -7.2575,
        'longitude': 112.7521,
        'accuracy_m': 42.0,
        'distance_m': 12.0,
        'is_mocked': false,
        'is_offline_submission': false,
        'officer_note': 'Hujan deras',
        'auto_status': 'flagged_review',
        'flag_reasons': ['LOW_GPS_ACCURACY'],
        'effective_status': 'flagged_review',
        'created_at': '2026-06-01T15:00:05Z',
      },
    ];
  }

  @override
  Future<String> createEvidenceSignedUrl({
    required String storagePath,
    required int expiresInSeconds,
  }) async {
    signedUrlCalls++;
    return 'https://signed.example.com/$storagePath?v=$signedUrlCalls';
  }

  @override
  Future<Map<String, dynamic>> rpcReviewPatrolCheckin({
    required String checkinId,
    required String decision,
    required String reviewNote,
  }) async {
    final err = nextRpcError;
    if (err != null) {
      nextRpcError = null;
      throw err;
    }
    lastReviewCall = <String, dynamic>{
      'checkinId': checkinId,
      'decision': decision,
      'reviewNote': reviewNote,
    };
    return <String, dynamic>{
      'id': checkinId,
      'client_event_id': 'evt-1',
      'site_id': 'site-1',
      'checkpoint_id': 'cp-1',
      'officer_id': 'officer-1',
      'qr_token_version_scanned': 1,
      'photo_path': 'site-1/checkins/officer-1/evt-1.jpg',
      'photo_sha256': 'a' * 64,
      'captured_at_client': '2026-06-01T15:00:00Z',
      'synced_at_server': '2026-06-01T15:00:05Z',
      'latitude': -7.2575,
      'longitude': 112.7521,
      'accuracy_m': 42.0,
      'distance_m': 12.0,
      'is_mocked': false,
      'is_offline_submission': false,
      'officer_note': 'Hujan deras',
      'auto_status': 'flagged_review',
      'flag_reasons': ['LOW_GPS_ACCURACY'],
      'manual_status': decision,
      'reviewed_by': 'admin-1',
      'reviewed_at': '2026-06-01T16:00:00Z',
      'review_note': reviewNote,
      'effective_status': decision,
      'created_at': '2026-06-01T15:00:05Z',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCheckinAuditLogRows(
    String checkinId,
  ) async {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'log-1',
        'checkin_id': checkinId,
        'site_id': 'site-1',
        'actor_id': null,
        'action': 'auto_evaluated',
        'previous_status': null,
        'new_status': 'flagged_review',
        'note': 'Evaluasi otomatis menandai: LOW_GPS_ACCURACY',
        'created_at': '2026-06-01T15:00:05Z',
      },
      <String, dynamic>{
        'id': 'log-2',
        'checkin_id': checkinId,
        'site_id': 'site-1',
        'actor_id': 'admin-1',
        'action': 'manual_approved',
        'previous_status': 'flagged_review',
        'new_status': 'manual_approved',
        'note': 'Foto jelas di Pos 1 saat hujan deras.',
        'created_at': '2026-06-01T16:00:00Z',
      },
    ];
  }
}

void main() {
  group('LocationService', () {
    test('captures high-accuracy reading including isMocked flag', () async {
      final adapter = _FakeLocationAdapter()
        ..positionToReturn = Position(
          longitude: 112.7521,
          latitude: -7.2575,
          timestamp: DateTime.utc(2026, 6, 1, 15, 0),
          accuracy: 8.5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
          isMocked: true,
        );
      final service = LocationService(
        adapter: adapter,
        clock: () => DateTime.utc(2026, 6, 1, 15, 0),
      );

      final reading = await service.getCurrentReading();
      expect(reading.latitude, -7.2575);
      expect(reading.accuracyMeters, 8.5);
      expect(reading.isMocked, isTrue);
    });

    test('throws PermissionFailure when GPS service is disabled or permission denied', () async {
      final adapter = _FakeLocationAdapter()..serviceEnabled = false;
      final service = LocationService(adapter: adapter);

      await expectLater(
        service.getCurrentReading(),
        throwsA(
          isA<PermissionFailure>().having(
            (f) => f.code,
            'code',
            'LOCATION_SERVICE_DISABLED',
          ),
        ),
      );

      adapter
        ..serviceEnabled = true
        ..permission = LocationPermission.denied
        ..requestedPermission = LocationPermission.deniedForever;

      await expectLater(
        service.getCurrentReading(),
        throwsA(
          isA<PermissionFailure>().having(
            (f) => f.code,
            'code',
            'LOCATION_PERMISSION_DENIED_FOREVER',
          ),
        ),
      );
    });
  });

  group('ForensicPhotoService', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('ronda_photo_test_');
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('compresses, writes durable JPEG copy, computes exact SHA-256, and cleans source', () async {
      final sourceFile = File('${tempRoot.path}/raw_camera.jpg');
      await sourceFile.writeAsBytes(Uint8List.fromList([1, 2, 3, 4, 5]));
      final compressedBytes = Uint8List.fromList([10, 20, 30, 40, 50, 60]);
      final evidenceDir = Directory('${tempRoot.path}/evidence');

      final service = ForensicPhotoService(
        compressor: ({
          required String sourcePath,
          required int maxDimension,
          required int quality,
        }) async {
          expect(maxDimension, ForensicPhotoService.maxLongestEdgePx);
          expect(quality, ForensicPhotoService.defaultJpegQuality);
          return compressedBytes;
        },
        directoryProvider: () async => evidenceDir,
        clock: () => DateTime.utc(2026, 6, 1, 15, 0),
      );

      final result = await service.processImageFile(
        sourceFilePath: sourceFile.path,
        clientEventId: 'evt-123',
        deleteSourceAfterCopy: true,
      );

      expect(result.sizeBytes, compressedBytes.length);
      expect(
        result.sha256Hex,
        ForensicPhotoService.computeSha256Hex(compressedBytes),
      );
      expect(result.sha256Hex.length, 64);
      expect(await File(result.localFilePath).exists(), isTrue);
      expect(await sourceFile.exists(), isFalse);
    });

    test('rejects photo exceeding 2 MB hard cap even after fallback compression', () async {
      final sourceFile = File('${tempRoot.path}/huge.jpg');
      await sourceFile.writeAsBytes(Uint8List(16));
      final oversized = Uint8List(ForensicPhotoService.hardMaxBytes + 1);

      final service = ForensicPhotoService(
        compressor: ({
          required String sourcePath,
          required int maxDimension,
          required int quality,
        }) async =>
            oversized,
        directoryProvider: () async => tempRoot,
      );

      await expectLater(
        service.processImageFile(
          sourceFilePath: sourceFile.path,
          clientEventId: 'evt-huge',
        ),
        throwsA(
          isA<ValidationFailure>().having((f) => f.code, 'code', 'PHOTO_TOO_LARGE'),
        ),
      );
    });
  });

  group('OfflineQueueRecord serialization', () {
    test('roundtrips QueuedCheckinRecord, QueuedReportRecord, and QueuedHandoverRecord maps', () {
      final checkin = QueuedCheckinRecord(
        clientEventId: 'evt-1',
        siteId: 'site-1',
        checkpointId: 'cp-1',
        scheduleId: 'sched-1',
        officerId: 'off-1',
        qrRawPayload: 'RD1|site-1|cp-1|1|${'a' * 64}',
        localPhotoPath: '/tmp/evt-1.jpg',
        photoSha256: 'a' * 64,
        capturedAtClient: DateTime.utc(2026, 6, 1, 15, 0),
        monotonicMs: 12345,
        latitude: -7.2575,
        longitude: 112.7521,
        accuracyMeters: 11.5,
        isMocked: false,
        deviceModel: 'Pixel',
        officerNote: 'Aman',
        checkpointName: 'Pos 1',
        syncState: OfflineSyncState.pending,
        retryCount: 1,
        nextRetryAt: DateTime.utc(2026, 6, 1, 15, 1),
        lastError: 'Offline',
        createdAt: DateTime.utc(2026, 6, 1, 15, 0),
      );

      final restored = QueuedCheckinRecord.fromMap(checkin.toMap());
      expect(restored.clientEventId, checkin.clientEventId);
      expect(restored.storagePhotoPath, 'site-1/checkins/off-1/evt-1.jpg');
      expect(restored.retryCount, 1);
      expect(restored.isMocked, isFalse);

      final report = QueuedReportRecord(
        clientEventId: 'rep-evt-1',
        siteId: 'site-1',
        reporterId: 'res-1',
        category: IncidentCategory.lampuMati,
        title: 'Lampu mati',
        description: 'Padam di depan gerbang',
        localPhotoPath: '/tmp/rep.jpg',
        latitude: -7.25,
        longitude: 112.75,
        syncState: OfflineSyncState.pending,
        retryCount: 0,
        createdAt: DateTime.utc(2026, 6, 1, 15, 0),
      );
      expect(
        QueuedReportRecord.fromMap(report.toMap()).category,
        IncidentCategory.lampuMati,
      );

      final handover = QueuedHandoverRecord(
        clientEventId: 'ho-evt-1',
        siteId: 'site-1',
        authorId: 'off-1',
        summary: 'Semua gerbang terkunci',
        assetStatus: 'Kunci lengkap',
        syncState: OfflineSyncState.pending,
        retryCount: 0,
        createdAt: DateTime.utc(2026, 6, 1, 15, 0),
      );
      expect(
        QueuedHandoverRecord.fromMap(handover.toMap()).summary,
        'Semua gerbang terkunci',
      );
    });
  });

  group('SyncWorker & OfflineCheckinRepository', () {
    late _InMemoryOfflineQueueStore queueStore;
    late _FakeConnectivityMonitor connectivity;
    late _FakeCheckinRemoteDataSource remote;
    late List<String> deletedPhotos;
    late DateTime currentNow;
    late SyncWorker syncWorker;
    late OfflineCheckinRepository repo;

    CheckinSubmissionDraft buildDraft(String eventId) {
      return CheckinSubmissionDraft(
        clientEventId: eventId,
        siteId: 'site-1',
        checkpointId: 'cp-1',
        qrRawPayload: 'RD1|site-1|cp-1|1|${'a' * 64}',
        localPhotoPath: '/local/$eventId.jpg',
        photoSha256: 'a' * 64,
        capturedAtClient: DateTime.utc(2026, 6, 1, 15, 0),
        monotonicMs: 5000,
        latitude: -7.2575,
        longitude: 112.7521,
        accuracyMeters: 10.0,
        isMocked: false,
        officerNote: 'Kondisi aman',
      );
    }

    setUp(() {
      queueStore = _InMemoryOfflineQueueStore();
      connectivity = _FakeConnectivityMonitor();
      remote = _FakeCheckinRemoteDataSource();
      deletedPhotos = <String>[];
      currentNow = DateTime.utc(2026, 6, 1, 15, 1, 0);

      syncWorker = SyncWorker(
        queueStore: queueStore,
        uploader: remote,
        connectivityMonitor: connectivity,
        photoReader: (_) async => Uint8List.fromList([1, 2, 3]),
        photoDeleter: (path) async => deletedPhotos.add(path),
        clock: () => currentNow,
      );

      repo = OfflineCheckinRepository.withDataSource(
        remoteDataSource: remote,
        queueStore: queueStore,
        syncWorker: syncWorker,
        connectivityMonitor: connectivity,
        photoReader: (_) async => Uint8List.fromList([1, 2, 3]),
        photoDeleter: (path) async => deletedPhotos.add(path),
        clock: () => currentNow,
      );
    });

    tearDown(() async {
      await syncWorker.dispose();
      await connectivity.controller.close();
      await queueStore.dispose();
    });

    test('computes exponential backoff schedule (5s, 15s, 45s, capped at 5m)', () {
      expect(SyncWorker.backoffForRetry(1), const Duration(seconds: 5));
      expect(SyncWorker.backoffForRetry(2), const Duration(seconds: 15));
      expect(SyncWorker.backoffForRetry(3), const Duration(seconds: 45));
      expect(SyncWorker.backoffForRetry(4), const Duration(minutes: 5));
      expect(SyncWorker.backoffForRetry(10), const Duration(minutes: 5));
    });

    test('submits directly online and deletes temp photo after confirmation', () async {
      final outcome = await repo.submitCheckin(buildDraft('evt-online'));

      expect(outcome.isQueuedOffline, isFalse);
      expect(outcome.syncedCheckin?.clientEventId, 'evt-online');
      expect(remote.uploadedPaths, ['site-1/checkins/officer-1/evt-online.jpg']);
      expect(remote.submittedPayloads.single['is_offline_submission'], isFalse);
      expect(deletedPhotos, ['/local/evt-online.jpg']);
    });

    test('queues offline check-in when disconnected, preserves photo, and syncs FIFO on recovery', () async {
      connectivity.online = false;
      final counts = <int>[];
      final sub = repo.watchPendingOfflineCount('site-1').listen(counts.add);

      final outcome = await repo.submitCheckin(buildDraft('evt-off-1'));
      expect(outcome.isQueuedOffline, isTrue);
      expect(deletedPhotos, isEmpty);

      final pending = await repo.fetchPendingOfflineItems('site-1');
      expect(pending, hasLength(1));

      // Simulate transient network failure on first sync attempt.
      remote.nextUploadError = const SocketException('Temporary drop');
      final failedSummary = await syncWorker.syncNow();
      expect(failedSummary.syncedCount, 0);
      expect(failedSummary.failedCount, 1);
      expect(failedSummary.remainingCount, 1);
      expect(deletedPhotos, isEmpty);

      final afterFail = await queueStore.fetchCheckinById('evt-off-1');
      expect(afterFail?.syncState, OfflineSyncState.failed);
      expect(afterFail?.retryCount, 1);
      expect(afterFail?.nextRetryAt, currentNow.add(const Duration(seconds: 5)));

      // Respects backoff window when ignoreBackoff is false.
      final skippedSummary = await syncWorker.syncNow(ignoreBackoff: false);
      expect(skippedSummary.syncedCount, 0);
      expect(skippedSummary.remainingCount, 1);

      // Manual retry (ignoreBackoff: true) succeeds and deletes local temp photo only after 200.
      final successSummary = await repo.syncNow();
      expect(successSummary.syncedCount, 1);
      expect(successSummary.failedCount, 0);
      expect(successSummary.remainingCount, 0);
      expect(remote.submittedPayloads.single['is_offline_submission'], isTrue);
      expect(deletedPhotos, ['/local/evt-off-1.jpg']);

      await Future<void>.delayed(Duration.zero);
      expect(counts, containsAllInOrder([0, 1, 0]));
      await sub.cancel();
    });

    test('caches signed evidence URLs within TTL and refreshes near expiry', () async {
      final url1 = await repo.getEvidenceSignedUrl(
        'site-1/checkins/officer-1/evt-1.jpg',
        expiresIn: const Duration(minutes: 15),
      );
      final url2 = await repo.getEvidenceSignedUrl(
        'site-1/checkins/officer-1/evt-1.jpg',
        expiresIn: const Duration(minutes: 15),
      );
      expect(url1, url2);
      expect(remote.signedUrlCalls, 1);

      // Advance clock to within 30 seconds of expiry -> triggers refresh.
      currentNow = currentNow.add(const Duration(minutes: 14, seconds: 30));
      final url3 = await repo.getEvidenceSignedUrl(
        'site-1/checkins/officer-1/evt-1.jpg',
        expiresIn: const Duration(minutes: 15),
      );
      expect(url3, isNot(url1));
      expect(remote.signedUrlCalls, 2);
    });

    test('reviewCheckinManual validates note length, invokes RPC, and fetches audit logs', () async {
      await expectLater(
        repo.reviewCheckinManual(
          checkinId: 'chk-1',
          decision: ManualReviewStatus.manualApproved,
          reviewNote: 'ok',
        ),
        throwsA(isA<ValidationFailure>()),
      );

      final reviewed = await repo.reviewCheckinManual(
        checkinId: 'chk-1',
        decision: ManualReviewStatus.manualApproved,
        reviewNote: 'Foto jelas di Pos 1 saat hujan deras.',
      );
      expect(reviewed.effectiveStatus, EffectiveCheckinStatus.manualApproved);
      expect(remote.lastReviewCall?['decision'], 'manual_approved');

      final auditQueue = await repo.fetchAuditQueue(siteId: 'site-1');
      expect(auditQueue, hasLength(1));

      final logs = await repo.fetchCheckinAuditLogs('chk-1');
      expect(logs, hasLength(2));
      expect(logs.first.action, AuditAction.autoEvaluated);
      expect(logs.last.action, AuditAction.manualApproved);

      remote.nextRpcError = const PostgrestException(
        message: 'Hanya admin wilayah',
        code: '42501',
      );
      await expectLater(
        repo.reviewCheckinManual(
          checkinId: 'chk-1',
          decision: ManualReviewStatus.manualRejected,
          reviewNote: 'Foto gelap tidak valid.',
        ),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });
}
