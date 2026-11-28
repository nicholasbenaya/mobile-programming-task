import 'dart:async';

import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/data/remote/dto_mappers.dart';
import 'package:ronda_app/data/remote/supabase_client_provider.dart';
import 'package:ronda_app/domain/models/checkpoint.dart';
import 'package:ronda_app/domain/repositories/checkpoint_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Explicit non-secret columns respecting column-level `qr_secret` revocation on `checkpoints`.
const String checkpointPublicColumns =
    'id, site_id, code, name, description, latitude, longitude, radius_m, '
    'sort_order, target_time_local, qr_token_version, is_active, created_at';

abstract interface class CheckpointDataSource {
  Stream<List<Map<String, dynamic>>> watchCheckpointRows(String siteId);

  Future<Map<String, dynamic>> insertCheckpointRow(
    Map<String, dynamic> payload,
  );

  Future<Map<String, dynamic>> updateCheckpointRow({
    required String checkpointId,
    required Map<String, dynamic> updates,
  });

  Future<Map<String, dynamic>> rpcGetCheckpointQrPayload(String checkpointId);

  Future<Map<String, dynamic>> rpcRegenerateCheckpointQr(String checkpointId);

  Future<List<Map<String, dynamic>>> rpcGetSitePatrolSummary({
    required String siteId,
    DateTime? since,
  });
}

class _SupabaseCheckpointDataSource implements CheckpointDataSource {
  const _SupabaseCheckpointDataSource(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> watchCheckpointRows(String siteId) {
    late final StreamController<List<Map<String, dynamic>>> controller;
    RealtimeChannel? channel;

    Future<void> emitLatest() async {
      try {
        final rows = await _client
            .from('checkpoints')
            .select(checkpointPublicColumns)
            .eq('site_id', siteId)
            .order('sort_order', ascending: true)
            .order('code', ascending: true);
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
            .channel('checkpoints:$siteId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'checkpoints',
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
        final activeChannel = channel;
        if (activeChannel != null) {
          await _client.removeChannel(activeChannel);
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> insertCheckpointRow(
    Map<String, dynamic> payload,
  ) {
    return _client
        .from('checkpoints')
        .insert(payload)
        .select(checkpointPublicColumns)
        .single();
  }

  @override
  Future<Map<String, dynamic>> updateCheckpointRow({
    required String checkpointId,
    required Map<String, dynamic> updates,
  }) {
    return _client
        .from('checkpoints')
        .update(updates)
        .eq('id', checkpointId)
        .select(checkpointPublicColumns)
        .single();
  }

  @override
  Future<Map<String, dynamic>> rpcGetCheckpointQrPayload(
    String checkpointId,
  ) async {
    final result = await _client.rpc(
      'get_checkpoint_qr_payload',
      params: <String, dynamic>{'p_checkpoint_id': checkpointId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>> rpcRegenerateCheckpointQr(
    String checkpointId,
  ) async {
    final result = await _client.rpc(
      'regenerate_checkpoint_qr',
      params: <String, dynamic>{'p_checkpoint_id': checkpointId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> rpcGetSitePatrolSummary({
    required String siteId,
    DateTime? since,
  }) async {
    final result = await _client.rpc(
      'get_site_patrol_summary',
      params: <String, dynamic>{
        'p_site_id': siteId,
        if (since != null) 'p_since': since.toUtc().toIso8601String(),
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }
}

/// Supabase-backed implementation of [CheckpointRepository] that never selects `qr_secret`.
class SupabaseCheckpointRepository implements CheckpointRepository {
  SupabaseCheckpointRepository(SupabaseClient client)
      : _dataSource = _SupabaseCheckpointDataSource(client);

  SupabaseCheckpointRepository.withDataSource(CheckpointDataSource dataSource)
      : _dataSource = dataSource;

  static final RegExp _targetTimePattern = RegExp(
    r'^([01][0-9]|2[0-3]):[0-5][0-9]$',
  );

  final CheckpointDataSource _dataSource;

  @override
  Stream<List<Checkpoint>> watchCheckpoints(
    String siteId, {
    bool activeOnly = false,
  }) {
    return _dataSource.watchCheckpointRows(siteId).map((rows) {
      final items = rows
          .map(DtoMappers.checkpointFromMap)
          .where((cp) => !activeOnly || cp.isActive)
          .toList(growable: false);
      items.sort(_compareCheckpoints);
      return items;
    });
  }

  @override
  Future<Checkpoint> createCheckpoint({
    required String siteId,
    required String code,
    required String name,
    String description = '',
    required double latitude,
    required double longitude,
    int radiusMeters = 30,
    int sortOrder = 0,
    String? targetTimeLocal,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final trimmedName = name.trim();
    final normalizedTargetTime = _validateTargetTime(targetTimeLocal);

    if (normalizedCode.isEmpty) {
      throw const ValidationFailure(
        message: 'Kode pos patroli wajib diisi.',
        code: 'CHECKPOINT_INVALID_CODE',
      );
    }
    if (trimmedName.length < 2) {
      throw const ValidationFailure(
        message: 'Nama pos patroli minimal 2 karakter.',
        code: 'CHECKPOINT_INVALID_NAME',
      );
    }
    _validateCoordinates(latitude: latitude, longitude: longitude);
    _validateRadius(radiusMeters);

    try {
      final row = await _dataSource.insertCheckpointRow(<String, dynamic>{
        'site_id': siteId,
        'code': normalizedCode,
        'name': trimmedName,
        'description': description.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'radius_m': radiusMeters,
        'sort_order': sortOrder,
        'target_time_local': normalizedTargetTime,
        'is_active': true,
      });
      return DtoMappers.checkpointFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<Checkpoint> updateCheckpoint({
    required String checkpointId,
    String? code,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    int? sortOrder,
    String? targetTimeLocal,
    bool clearTargetTimeLocal = false,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};

    if (code != null) {
      final normalized = code.trim().toUpperCase();
      if (normalized.isEmpty) {
        throw const ValidationFailure(
          message: 'Kode pos patroli tidak boleh kosong.',
          code: 'CHECKPOINT_INVALID_CODE',
        );
      }
      updates['code'] = normalized;
    }
    if (name != null) {
      final trimmed = name.trim();
      if (trimmed.length < 2) {
        throw const ValidationFailure(
          message: 'Nama pos patroli minimal 2 karakter.',
          code: 'CHECKPOINT_INVALID_NAME',
        );
      }
      updates['name'] = trimmed;
    }
    if (description != null) {
      updates['description'] = description.trim();
    }
    if (latitude != null || longitude != null) {
      if (latitude != null && (!latitude.isFinite || latitude < -90 || latitude > 90)) {
        throw const ValidationFailure(
          message: 'Koordinat lintang tidak valid.',
          code: 'CHECKPOINT_INVALID_COORDS',
        );
      }
      if (longitude != null &&
          (!longitude.isFinite || longitude < -180 || longitude > 180)) {
        throw const ValidationFailure(
          message: 'Koordinat bujur tidak valid.',
          code: 'CHECKPOINT_INVALID_COORDS',
        );
      }
      if (latitude != null) {
        updates['latitude'] = latitude;
      }
      if (longitude != null) {
        updates['longitude'] = longitude;
      }
    }
    if (radiusMeters != null) {
      _validateRadius(radiusMeters);
      updates['radius_m'] = radiusMeters;
    }
    if (sortOrder != null) {
      updates['sort_order'] = sortOrder;
    }
    if (clearTargetTimeLocal) {
      updates['target_time_local'] = null;
    } else if (targetTimeLocal != null) {
      updates['target_time_local'] = _validateTargetTime(targetTimeLocal);
    }
    if (isActive != null) {
      updates['is_active'] = isActive;
    }

    if (updates.isEmpty) {
      throw const ValidationFailure(
        message: 'Tidak ada perubahan data pos patroli yang dikirim.',
        code: 'CHECKPOINT_NO_UPDATES',
      );
    }

    try {
      final row = await _dataSource.updateCheckpointRow(
        checkpointId: checkpointId,
        updates: updates,
      );
      return DtoMappers.checkpointFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<void> deactivateCheckpoint(String checkpointId) async {
    try {
      await _dataSource.updateCheckpointRow(
        checkpointId: checkpointId,
        updates: const <String, dynamic>{'is_active': false},
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<CheckpointQrPayload> getAdminQrPayload(String checkpointId) async {
    try {
      final row = await _dataSource.rpcGetCheckpointQrPayload(checkpointId);
      return DtoMappers.checkpointQrPayloadFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<CheckpointQrPayload> regenerateQrToken(String checkpointId) async {
    try {
      final row = await _dataSource.rpcRegenerateCheckpointQr(checkpointId);
      return DtoMappers.checkpointQrPayloadFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<List<CheckpointPatrolSummary>> fetchPatrolSummary({
    required String siteId,
    DateTime? since,
  }) async {
    try {
      final rows = await _dataSource.rpcGetSitePatrolSummary(
        siteId: siteId,
        since: since,
      );
      return rows
          .map(DtoMappers.checkpointPatrolSummaryFromMap)
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  static void _validateCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw const ValidationFailure(
        message: 'Koordinat lokasi pos patroli tidak valid.',
        code: 'CHECKPOINT_INVALID_COORDS',
      );
    }
  }

  static void _validateRadius(int radiusMeters) {
    if (radiusMeters < 10 || radiusMeters > 200) {
      throw const ValidationFailure(
        message: 'Radius geofence pos harus di antara 10 hingga 200 meter.',
        code: 'CHECKPOINT_INVALID_RADIUS',
      );
    }
  }

  static String? _validateTargetTime(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (!_targetTimePattern.hasMatch(trimmed)) {
      throw const ValidationFailure(
        message: 'Format jam target harus HH:mm (contoh: 22:30).',
        code: 'CHECKPOINT_INVALID_TARGET_TIME',
      );
    }
    return trimmed;
  }

  static int _compareCheckpoints(Checkpoint a, Checkpoint b) {
    final orderDiff = a.sortOrder.compareTo(b.sortOrder);
    if (orderDiff != 0) {
      return orderDiff;
    }
    return a.code.compareTo(b.code);
  }
}
