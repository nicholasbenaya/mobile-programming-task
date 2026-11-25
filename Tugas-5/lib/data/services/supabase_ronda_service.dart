import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/ronda/models/ronda_models.dart';
import '../repositories/ronda_photo_repository.dart';
import 'supabase_service.dart';

/// Layanan Komunikasi Data Cloud Supabase untuk Ekosistem Ronda Digital
/// Mendukung Realtime Streaming Postgres Changes & Sinkronisasi CRUD
class SupabaseRondaService {
  SupabaseRondaService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get client => _client ?? SupabaseService.clientOrNull;
  bool get isAvailable => client != null;

  static const rondaRtId = 'RT-04-RW-02-SUKOLILO';

  Future<RondaUser> signInRondaUser({
    required String whatsapp,
    required String password,
  }) async {
    final c = client;
    if (c == null) throw StateError('Supabase belum dikonfigurasi.');
    final response = await c.rpc('ronda_demo_login', params: {
      'p_whatsapp': whatsapp.replaceAll(RegExp(r'\D'), ''),
      'p_password': password,
    });
    if (response is! List || response.isEmpty) {
      throw StateError('Nomor WhatsApp atau kata sandi salah.');
    }
    return RondaUser.fromJson(Map<String, dynamic>.from(response.first));
  }

  RondaUser? get currentRondaUser => null;

  Future<void> signOutRondaUser() async {
    final c = client;
    if (c != null && c.auth.currentSession != null) await c.auth.signOut();
  }

  RondaPhotoRepository get _rondaPhotos {
    final c = client;
    if (c == null) throw StateError('Supabase belum dikonfigurasi.');
    return RondaPhotoRepository(c);
  }

  Future<String> uploadRondaPhoto(File photo, {required String rtId}) =>
      _rondaPhotos.upload(photo: photo, rtId: rtId);

  Future<String> createRondaPhotoUrl(String path) =>
      _rondaPhotos.signedUrl(path);

  Future<void> deleteRondaPhoto(String path) => _rondaPhotos.delete(path);

  // ==========================================
  // 1. DATA PENGGUNA & POS CHECKPOINT
  // ==========================================

  Future<List<RondaUser>> fetchUsers(String rtId) async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c.from('users').select().eq('rt_id', rtId);
      return (res as List).map((row) => RondaUser.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetchUsers: $e');
      return [];
    }
  }

  Future<List<Checkpoint>> fetchCheckpoints(String rtId) async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c.from('checkpoints').select().eq('rt_id', rtId);
      return (res as List).map((row) => Checkpoint.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetchCheckpoints: $e');
      return [];
    }
  }

  // ==========================================
  // 2. JADWAL PATROLI (PATROL SCHEDULES)
  // ==========================================

  Future<List<PatrolSchedule>> fetchSchedules(String rtId) async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c.from('patrol_schedules').select().eq('rt_id', rtId);
      return (res as List).map((row) => PatrolSchedule.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetchSchedules: $e');
      return [];
    }
  }

  Future<void> upsertSchedule(PatrolSchedule schedule) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('patrol_schedules').upsert(schedule.toJson());
    } catch (e) {
      debugPrint('Error upsertSchedule: $e');
    }
  }

  Future<void> upsertSchedules(List<PatrolSchedule> schedules) async {
    final c = client;
    if (c == null || schedules.isEmpty) return;
    try {
      final payload = schedules.map((s) => s.toJson()).toList();
      await c.from('patrol_schedules').upsert(payload);
    } catch (e) {
      debugPrint('Error upsertSchedules: $e');
    }
  }

  Future<void> upsertSchedulesOrThrow(List<PatrolSchedule> schedules) async {
    final c = client;
    if (c == null) throw StateError('Supabase belum dikonfigurasi.');
    if (schedules.isEmpty) return;
    final payload = schedules.map((s) => s.toJson()).toList();
    await c.from('patrol_schedules').upsert(payload);
  }

  Stream<List<PatrolSchedule>> streamSchedules(String rtId) {
    final c = client;
    if (c == null) return const Stream.empty();
    return c
        .from('patrol_schedules')
        .stream(primaryKey: ['id'])
        .eq('rt_id', rtId)
        .map((rows) => rows.map((r) => PatrolSchedule.fromJson(r)).toList());
  }

  // ==========================================
  // 3. LOG CHECK-IN POS
  // ==========================================

  Future<List<PatrolCheckin>> fetchPatrolLogs() async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c
          .from('patrol_checkins')
          .select()
          .order('scanned_at', ascending: false);
      return (res as List).map((row) => PatrolCheckin.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetchPatrolLogs: $e');
      return [];
    }
  }

  Future<void> insertCheckin(PatrolCheckin checkin) async {
    final c = client;
    if (c == null) return;
    try {
      final map = checkin.toJson();
      map.remove('sync_status'); // Kolom internal lokal
      await c.from('patrol_checkins').upsert(map);
    } catch (e) {
      debugPrint('Error insertCheckin: $e');
    }
  }

  Stream<List<PatrolCheckin>> streamCheckins() {
    final c = client;
    if (c == null) return const Stream.empty();
    return c.from('patrol_checkins').stream(primaryKey: ['id']).map(
        (rows) => rows.map((r) => PatrolCheckin.fromJson(r)).toList());
  }

  // ==========================================
  // 4. ALARM DARURAT SOS (EMERGENCY EVENTS)
  // ==========================================

  Future<List<EmergencyEvent>> fetchEmergencyEvents(String rtId) async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c
          .from('emergency_events')
          .select()
          .eq('rt_id', rtId)
          .order('triggered_at', ascending: false);
      return (res as List).map((row) => EmergencyEvent.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetchEmergencyEvents: $e');
      return [];
    }
  }

  Future<void> insertEmergency(EmergencyEvent event) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('emergency_events').insert(event.toJson());
    } catch (e) {
      debugPrint('Error insertEmergency: $e');
    }
  }

  Future<void> updateEmergency(EmergencyEvent event) async {
    final c = client;
    if (c == null) return;
    try {
      await c
          .from('emergency_events')
          .update(event.toJson())
          .eq('id', event.id);
    } catch (e) {
      debugPrint('Error updateEmergency: $e');
    }
  }

  Stream<List<EmergencyEvent>> streamEmergencies(String rtId) {
    final c = client;
    if (c == null) return const Stream.empty();
    return c
        .from('emergency_events')
        .stream(primaryKey: ['id'])
        .eq('rt_id', rtId)
        .map((rows) => rows.map((r) => EmergencyEvent.fromJson(r)).toList());
  }

  // ==========================================
  // 5. PERTUKARAN JADWAL (SHIFT SWAP)
  // ==========================================

  Future<List<ShiftSwapRequest>> fetchShiftSwaps(String rtId) async {
    final c = client;
    if (c == null) throw StateError('Supabase belum dikonfigurasi.');
    final res = await c
        .from('shift_swaps')
        .select()
        .eq('rt_id', rtId)
        .order('created_at', ascending: false);
    return (res as List).map((row) => ShiftSwapRequest.fromJson(row)).toList();
  }

  Future<void> insertShiftSwap(ShiftSwapRequest swap) async {
    final c = client;
    if (c == null) throw StateError('Supabase belum dikonfigurasi.');
    await c.from('shift_swaps').insert(swap.toJson());
  }

  Future<void> updateShiftSwap(ShiftSwapRequest swap) async {
    final c = client;
    if (c == null) throw StateError('Supabase belum dikonfigurasi.');
    await c
        .from('shift_swaps')
        .update(swap.toJson())
        .eq('id', swap.id)
        .eq('rt_id', swap.rtId);
  }

  Stream<List<ShiftSwapRequest>> streamShiftSwaps(String rtId) {
    final c = client;
    if (c == null) return const Stream.empty();
    return c
        .from('shift_swaps')
        .stream(primaryKey: ['id'])
        .eq('rt_id', rtId)
        .map((rows) => rows.map((r) => ShiftSwapRequest.fromJson(r)).toList());
  }

  // ==========================================
  // 6. LAPORAN TEMUAN NON-SOS (INCIDENT REPORTS)
  // ==========================================

  Future<List<IncidentReport>> fetchIncidents(String rtId) async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c
          .from('incident_reports')
          .select()
          .eq('rt_id', rtId)
          .order('created_at', ascending: false);
      return (res as List).map((row) => IncidentReport.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetchIncidents: $e');
      return [];
    }
  }

  Future<void> insertIncident(IncidentReport incident) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('incident_reports').insert(incident.toJson());
    } catch (e) {
      debugPrint('Error insertIncident: $e');
    }
  }

  // ==========================================
  // 7. NOTIFIKASI & PENGUMUMAN RT
  // ==========================================

  Future<List<RondaNotification>> fetchNotifications(String rtId) async {
    final c = client;
    if (c == null) return [];
    try {
      final res = await c
          .from('ronda_notifications')
          .select()
          .eq('rt_id', rtId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((row) => RondaNotification.fromJson(row))
          .toList();
    } catch (e) {
      debugPrint('Error fetchNotifications: $e');
      return [];
    }
  }

  Future<void> insertNotification(RondaNotification notif) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('ronda_notifications').insert(notif.toJson());
    } catch (e) {
      debugPrint('Error insertNotification: $e');
    }
  }

  Stream<List<RondaNotification>> streamNotifications(String rtId) {
    final c = client;
    if (c == null) return const Stream.empty();
    return c
        .from('ronda_notifications')
        .stream(primaryKey: ['id'])
        .eq('rt_id', rtId)
        .map((rows) => rows.map((r) => RondaNotification.fromJson(r)).toList());
  }
}
