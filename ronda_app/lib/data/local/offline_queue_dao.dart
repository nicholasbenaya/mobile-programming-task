import 'dart:async';

import 'package:ronda_app/data/local/offline_database.dart';
import 'package:ronda_app/domain/models/checkin.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:sqflite/sqflite.dart';

/// Durable local SQLite row for an offline-queued patrol check-in.
class QueuedCheckinRecord {
  const QueuedCheckinRecord({
    required this.clientEventId,
    required this.siteId,
    required this.checkpointId,
    required this.officerId,
    required this.qrRawPayload,
    required this.localPhotoPath,
    required this.photoSha256,
    required this.capturedAtClient,
    required this.monotonicMs,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMocked,
    required this.officerNote,
    required this.syncState,
    required this.retryCount,
    required this.createdAt,
    this.scheduleId,
    this.deviceModel,
    this.checkpointName,
    this.nextRetryAt,
    this.lastError,
  });

  final String clientEventId;
  final String siteId;
  final String checkpointId;
  final String? scheduleId;
  final String officerId;
  final String qrRawPayload;
  final String localPhotoPath;
  final String photoSha256;
  final DateTime capturedAtClient;
  final int monotonicMs;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isMocked;
  final String? deviceModel;
  final String officerNote;
  final String? checkpointName;
  final OfflineSyncState syncState;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;

  String get storagePhotoPath =>
      '$siteId/checkins/$officerId/$clientEventId.jpg';

  OfflineQueueItem toOfflineQueueItem() {
    return OfflineQueueItem(
      clientEventId: clientEventId,
      siteId: siteId,
      checkpointId: checkpointId,
      localPhotoPath: localPhotoPath,
      photoSha256: photoSha256,
      capturedAtClient: capturedAtClient,
      syncState: syncState,
      retryCount: retryCount,
      lastError: lastError,
      checkpointName: checkpointName,
    );
  }

  QueuedCheckinRecord copyWith({
    OfflineSyncState? syncState,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return QueuedCheckinRecord(
      clientEventId: clientEventId,
      siteId: siteId,
      checkpointId: checkpointId,
      scheduleId: scheduleId,
      officerId: officerId,
      qrRawPayload: qrRawPayload,
      localPhotoPath: localPhotoPath,
      photoSha256: photoSha256,
      capturedAtClient: capturedAtClient,
      monotonicMs: monotonicMs,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      isMocked: isMocked,
      deviceModel: deviceModel,
      officerNote: officerNote,
      checkpointName: checkpointName,
      syncState: syncState ?? this.syncState,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt:
          clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'client_event_id': clientEventId,
      'site_id': siteId,
      'checkpoint_id': checkpointId,
      'schedule_id': scheduleId,
      'officer_id': officerId,
      'qr_raw_payload': qrRawPayload,
      'local_photo_path': localPhotoPath,
      'photo_sha256': photoSha256,
      'captured_at_client': capturedAtClient.toUtc().toIso8601String(),
      'monotonic_ms': monotonicMs,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_m': accuracyMeters,
      'is_mocked': isMocked ? 1 : 0,
      'device_model': deviceModel,
      'officer_note': officerNote,
      'checkpoint_name': checkpointName,
      'sync_state': syncState.value,
      'retry_count': retryCount,
      'next_retry_at': nextRetryAt?.toUtc().toIso8601String(),
      'last_error': lastError,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  static QueuedCheckinRecord fromMap(Map<String, Object?> map) {
    final rawNextRetry = map['next_retry_at'] as String?;
    return QueuedCheckinRecord(
      clientEventId: map['client_event_id'] as String,
      siteId: map['site_id'] as String,
      checkpointId: map['checkpoint_id'] as String,
      scheduleId: map['schedule_id'] as String?,
      officerId: map['officer_id'] as String,
      qrRawPayload: map['qr_raw_payload'] as String,
      localPhotoPath: map['local_photo_path'] as String,
      photoSha256: map['photo_sha256'] as String,
      capturedAtClient: DateTime.parse(map['captured_at_client'] as String),
      monotonicMs: (map['monotonic_ms'] as num).toInt(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracyMeters: (map['accuracy_m'] as num).toDouble(),
      isMocked: ((map['is_mocked'] as num?)?.toInt() ?? 0) == 1,
      deviceModel: map['device_model'] as String?,
      officerNote: (map['officer_note'] as String?) ?? '',
      checkpointName: map['checkpoint_name'] as String?,
      syncState: OfflineSyncState.fromValue(map['sync_state'] as String),
      retryCount: (map['retry_count'] as num).toInt(),
      nextRetryAt:
          rawNextRetry != null ? DateTime.tryParse(rawNextRetry) : null,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Durable local SQLite row for an offline-queued incident report.
class QueuedReportRecord {
  const QueuedReportRecord({
    required this.clientEventId,
    required this.siteId,
    required this.reporterId,
    required this.category,
    required this.title,
    required this.description,
    required this.localPhotoPath,
    required this.latitude,
    required this.longitude,
    required this.syncState,
    required this.retryCount,
    required this.createdAt,
    this.nextRetryAt,
    this.lastError,
  });

  final String clientEventId;
  final String siteId;
  final String reporterId;
  final IncidentCategory category;
  final String title;
  final String description;
  final String localPhotoPath;
  final double latitude;
  final double longitude;
  final OfflineSyncState syncState;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'client_event_id': clientEventId,
        'site_id': siteId,
        'reporter_id': reporterId,
        'category': category.value,
        'title': title,
        'description': description,
        'local_photo_path': localPhotoPath,
        'latitude': latitude,
        'longitude': longitude,
        'sync_state': syncState.value,
        'retry_count': retryCount,
        'next_retry_at': nextRetryAt?.toUtc().toIso8601String(),
        'last_error': lastError,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  static QueuedReportRecord fromMap(Map<String, Object?> map) {
    final rawNextRetry = map['next_retry_at'] as String?;
    return QueuedReportRecord(
      clientEventId: map['client_event_id'] as String,
      siteId: map['site_id'] as String,
      reporterId: map['reporter_id'] as String,
      category: IncidentCategory.fromValue(map['category'] as String),
      title: map['title'] as String,
      description: map['description'] as String,
      localPhotoPath: map['local_photo_path'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      syncState: OfflineSyncState.fromValue(map['sync_state'] as String),
      retryCount: (map['retry_count'] as num).toInt(),
      nextRetryAt:
          rawNextRetry != null ? DateTime.tryParse(rawNextRetry) : null,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Durable local SQLite row for an offline-queued Buku Mutasi handover.
class QueuedHandoverRecord {
  const QueuedHandoverRecord({
    required this.clientEventId,
    required this.siteId,
    required this.authorId,
    required this.summary,
    required this.assetStatus,
    required this.syncState,
    required this.retryCount,
    required this.createdAt,
    this.fromScheduleId,
    this.localPhotoPath,
    this.nextRetryAt,
    this.lastError,
  });

  final String clientEventId;
  final String siteId;
  final String? fromScheduleId;
  final String authorId;
  final String summary;
  final String assetStatus;
  final String? localPhotoPath;
  final OfflineSyncState syncState;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'client_event_id': clientEventId,
        'site_id': siteId,
        'from_schedule_id': fromScheduleId,
        'author_id': authorId,
        'summary': summary,
        'asset_status': assetStatus,
        'local_photo_path': localPhotoPath,
        'sync_state': syncState.value,
        'retry_count': retryCount,
        'next_retry_at': nextRetryAt?.toUtc().toIso8601String(),
        'last_error': lastError,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  static QueuedHandoverRecord fromMap(Map<String, Object?> map) {
    final rawNextRetry = map['next_retry_at'] as String?;
    return QueuedHandoverRecord(
      clientEventId: map['client_event_id'] as String,
      siteId: map['site_id'] as String,
      fromScheduleId: map['from_schedule_id'] as String?,
      authorId: map['author_id'] as String,
      summary: map['summary'] as String,
      assetStatus: (map['asset_status'] as String?) ?? '',
      localPhotoPath: map['local_photo_path'] as String?,
      syncState: OfflineSyncState.fromValue(map['sync_state'] as String),
      retryCount: (map['retry_count'] as num).toInt(),
      nextRetryAt:
          rawNextRetry != null ? DateTime.tryParse(rawNextRetry) : null,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Abstract queue store implemented by [SqfliteOfflineQueueDao] for SQLite persistence.
abstract interface class OfflineQueueStore {
  Future<void> enqueueCheckin(QueuedCheckinRecord record);

  Future<List<QueuedCheckinRecord>> fetchPendingCheckins({
    String? siteId,
    DateTime? dueBefore,
  });

  Future<QueuedCheckinRecord?> fetchCheckinById(String clientEventId);

  Future<void> updateCheckinState({
    required String clientEventId,
    required OfflineSyncState syncState,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    String? lastError,
    bool clearLastError = false,
  });

  Future<void> deleteCheckin(String clientEventId);

  Future<int> countPendingCheckins(String siteId);

  Stream<int> watchPendingCheckinCount(String siteId);

  Future<void> enqueueReport(QueuedReportRecord record);
  Future<List<QueuedReportRecord>> fetchPendingReports({String? siteId});
  Future<void> deleteReport(String clientEventId);

  Future<void> enqueueHandover(QueuedHandoverRecord record);
  Future<List<QueuedHandoverRecord>> fetchPendingHandovers({String? siteId});
  Future<void> deleteHandover(String clientEventId);

  Future<void> dispose();
}

/// `sqflite` DAO backing offline check-in, incident report, and handover queues.
class SqfliteOfflineQueueDao implements OfflineQueueStore {
  SqfliteOfflineQueueDao(this._offlineDatabase);

  final OfflineDatabase _offlineDatabase;
  final StreamController<String?> _changeSignal =
      StreamController<String?>.broadcast();

  void _notifyChanged([String? siteId]) {
    if (!_changeSignal.isClosed) {
      _changeSignal.add(siteId);
    }
  }

  @override
  Future<void> enqueueCheckin(QueuedCheckinRecord record) async {
    final db = await _offlineDatabase.database;
    await db.insert(
      OfflineDatabase.checkinQueueTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChanged(record.siteId);
  }

  @override
  Future<List<QueuedCheckinRecord>> fetchPendingCheckins({
    String? siteId,
    DateTime? dueBefore,
  }) async {
    final db = await _offlineDatabase.database;
    final whereClauses = <String>['sync_state != ?'];
    final whereArgs = <Object?>[OfflineSyncState.synced.value];

    if (siteId != null) {
      whereClauses.add('site_id = ?');
      whereArgs.add(siteId);
    }
    if (dueBefore != null) {
      whereClauses.add('(next_retry_at IS NULL OR next_retry_at <= ?)');
      whereArgs.add(dueBefore.toUtc().toIso8601String());
    }

    final rows = await db.query(
      OfflineDatabase.checkinQueueTable,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );
    return rows.map(QueuedCheckinRecord.fromMap).toList(growable: false);
  }

  @override
  Future<QueuedCheckinRecord?> fetchCheckinById(String clientEventId) async {
    final db = await _offlineDatabase.database;
    final rows = await db.query(
      OfflineDatabase.checkinQueueTable,
      where: 'client_event_id = ?',
      whereArgs: <Object?>[clientEventId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return QueuedCheckinRecord.fromMap(rows.first);
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
    final db = await _offlineDatabase.database;
    final updates = <String, Object?>{
      'sync_state': syncState.value,
      'retry_count': ?retryCount,
      if (clearNextRetryAt)
        'next_retry_at': null
      else if (nextRetryAt != null)
        'next_retry_at': nextRetryAt.toUtc().toIso8601String(),
      if (clearLastError) 'last_error': null else 'last_error': ?lastError,
    };
    await db.update(
      OfflineDatabase.checkinQueueTable,
      updates,
      where: 'client_event_id = ?',
      whereArgs: <Object?>[clientEventId],
    );
    _notifyChanged();
  }

  @override
  Future<void> deleteCheckin(String clientEventId) async {
    final db = await _offlineDatabase.database;
    await db.delete(
      OfflineDatabase.checkinQueueTable,
      where: 'client_event_id = ?',
      whereArgs: <Object?>[clientEventId],
    );
    _notifyChanged();
  }

  @override
  Future<int> countPendingCheckins(String siteId) async {
    final db = await _offlineDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${OfflineDatabase.checkinQueueTable} '
      'WHERE site_id = ? AND sync_state != ?',
      <Object?>[siteId, OfflineSyncState.synced.value],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Stream<int> watchPendingCheckinCount(String siteId) {
    late final StreamController<int> controller;
    StreamSubscription<String?>? sub;

    Future<void> emitCount() async {
      try {
        final count = await countPendingCheckins(siteId);
        if (!controller.isClosed) {
          controller.add(count);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<int>(
      onListen: () {
        emitCount();
        sub = _changeSignal.stream.listen((changedSiteId) {
          if (changedSiteId == null || changedSiteId == siteId) {
            emitCount();
          }
        });
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );

    return controller.stream.distinct();
  }

  @override
  Future<void> enqueueReport(QueuedReportRecord record) async {
    final db = await _offlineDatabase.database;
    await db.insert(
      OfflineDatabase.reportQueueTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<QueuedReportRecord>> fetchPendingReports({String? siteId}) async {
    final db = await _offlineDatabase.database;
    final whereClauses = <String>['sync_state != ?'];
    final whereArgs = <Object?>[OfflineSyncState.synced.value];
    if (siteId != null) {
      whereClauses.add('site_id = ?');
      whereArgs.add(siteId);
    }
    final rows = await db.query(
      OfflineDatabase.reportQueueTable,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );
    return rows.map(QueuedReportRecord.fromMap).toList(growable: false);
  }

  @override
  Future<void> deleteReport(String clientEventId) async {
    final db = await _offlineDatabase.database;
    await db.delete(
      OfflineDatabase.reportQueueTable,
      where: 'client_event_id = ?',
      whereArgs: <Object?>[clientEventId],
    );
  }

  @override
  Future<void> enqueueHandover(QueuedHandoverRecord record) async {
    final db = await _offlineDatabase.database;
    await db.insert(
      OfflineDatabase.handoverQueueTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<QueuedHandoverRecord>> fetchPendingHandovers({
    String? siteId,
  }) async {
    final db = await _offlineDatabase.database;
    final whereClauses = <String>['sync_state != ?'];
    final whereArgs = <Object?>[OfflineSyncState.synced.value];
    if (siteId != null) {
      whereClauses.add('site_id = ?');
      whereArgs.add(siteId);
    }
    final rows = await db.query(
      OfflineDatabase.handoverQueueTable,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );
    return rows.map(QueuedHandoverRecord.fromMap).toList(growable: false);
  }

  @override
  Future<void> deleteHandover(String clientEventId) async {
    final db = await _offlineDatabase.database;
    await db.delete(
      OfflineDatabase.handoverQueueTable,
      where: 'client_event_id = ?',
      whereArgs: <Object?>[clientEventId],
    );
  }

  @override
  Future<void> dispose() async {
    await _changeSignal.close();
  }
}
