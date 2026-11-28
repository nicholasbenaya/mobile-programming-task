import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/data/remote/dto_mappers.dart';
import 'package:ronda_app/data/remote/supabase_client_provider.dart';
import 'package:ronda_app/data/repositories/supabase_auth_site_repository.dart';
import 'package:ronda_app/data/repositories/supabase_checkpoint_repository.dart';
import 'package:ronda_app/domain/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthSiteDataSource implements AuthSiteDataSource {
  AuthSessionUser? user = const AuthSessionUser(
    id: 'user-admin',
    email: 'admin@rondadigital.id',
  );

  final authController = StreamController<AuthSessionUser?>.broadcast();
  final memberController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Map<String, dynamic>? lastCreateSiteParams;
  Map<String, dynamic>? lastJoinParams;
  Map<String, dynamic>? lastSiteUpdates;
  Map<String, dynamic>? lastMemberUpdates;
  String? lastDeletedMembershipId;
  Object? nextError;

  List<Map<String, dynamic>> mySitesRows = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> profileRows = <Map<String, dynamic>>[];

  void _throwIfConfigured() {
    final err = nextError;
    if (err != null) {
      nextError = null;
      throw err;
    }
  }

  @override
  AuthSessionUser? get currentUser => user;

  @override
  Stream<AuthSessionUser?> watchAuthState() => authController.stream;

  @override
  Future<AuthSessionUser> signIn({
    required String email,
    required String password,
  }) async {
    _throwIfConfigured();
    user = AuthSessionUser(id: 'user-admin', email: email);
    return user!;
  }

  @override
  Future<AuthSessionUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    _throwIfConfigured();
    user = AuthSessionUser(id: 'user-new', email: email);
    return user!;
  }

  @override
  Future<void> signOut() async {
    _throwIfConfigured();
    user = null;
  }

  @override
  Future<Map<String, dynamic>?> fetchProfileRow(String userId) async {
    _throwIfConfigured();
    return <String, dynamic>{
      'id': userId,
      'full_name': 'Budi Santoso',
      'phone_whatsapp': '081234567890',
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> upsertProfileRow({
    required String userId,
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    _throwIfConfigured();
    return <String, dynamic>{
      'id': userId,
      'full_name': fullName,
      'phone_whatsapp': phoneWhatsapp,
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyMembershipsWithSites(
    String userId,
  ) async {
    _throwIfConfigured();
    return mySitesRows;
  }

  @override
  Future<Map<String, dynamic>> rpcCreateSiteWithAdmin(
    Map<String, dynamic> params,
  ) async {
    _throwIfConfigured();
    lastCreateSiteParams = params;
    return <String, dynamic>{
      'id': 'site-1',
      'name': params['p_name'],
      'site_type': params['p_site_type'],
      'address_summary': params['p_address'],
      'invite_code': 'ABCD2345',
      'require_join_approval': true,
      'center_lat': params['p_center_lat'],
      'center_lng': params['p_center_lng'],
      'default_geofence_m': params['p_radius_m'],
      'sos_escalation_minutes': 3,
      'created_by': user!.id,
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> rpcJoinSiteByCode(
    Map<String, dynamic> params,
  ) async {
    _throwIfConfigured();
    lastJoinParams = params;
    return <String, dynamic>{
      'id': 'mem-1',
      'site_id': 'site-1',
      'user_id': user!.id,
      'role': 'resident',
      'status': 'pending',
      'unit_address': params['p_unit_address'],
      'joined_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> updateSiteRow({
    required String siteId,
    required Map<String, dynamic> updates,
  }) async {
    _throwIfConfigured();
    lastSiteUpdates = updates;
    return <String, dynamic>{
      'id': siteId,
      'name': updates['name'] ?? 'Perumahan Asri',
      'site_type': updates['site_type'] ?? 'perumahan',
      'address_summary': updates['address_summary'] ?? 'Surabaya',
      'invite_code': 'ABCD2345',
      'require_join_approval': updates['require_join_approval'] ?? true,
      'center_lat': updates['center_lat'] ?? -7.2575,
      'center_lng': updates['center_lng'] ?? 112.7521,
      'default_geofence_m': updates['default_geofence_m'] ?? 30,
      'sos_escalation_minutes': updates['sos_escalation_minutes'] ?? 3,
      'created_by': 'user-admin',
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> rpcRegenerateSiteInviteCode(
    String siteId,
  ) async {
    _throwIfConfigured();
    return <String, dynamic>{
      'id': siteId,
      'name': 'Perumahan Asri',
      'site_type': 'perumahan',
      'address_summary': 'Surabaya',
      'invite_code': 'WXYZ6789',
      'require_join_approval': true,
      'center_lat': -7.2575,
      'center_lng': 112.7521,
      'default_geofence_m': 30,
      'sos_escalation_minutes': 3,
      'created_by': 'user-admin',
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> rpcUpdateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  }) async {
    _throwIfConfigured();
    return <String, dynamic>{
      'id': 'mem-1',
      'site_id': siteId,
      'user_id': user!.id,
      'role': 'resident',
      'status': 'active',
      'unit_address': unitAddress,
      'joined_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Stream<List<Map<String, dynamic>>> streamMembershipRows(String siteId) =>
      memberController.stream;

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> userIds,
  ) async {
    _throwIfConfigured();
    return profileRows;
  }

  @override
  Future<Map<String, dynamic>> updateMembershipRow({
    required String membershipId,
    required Map<String, dynamic> updates,
  }) async {
    _throwIfConfigured();
    lastMemberUpdates = updates;
    return <String, dynamic>{
      'id': membershipId,
      'site_id': 'site-1',
      'user_id': 'user-2',
      'role': updates['role'] ?? 'officer',
      'status': updates['status'] ?? 'active',
      'unit_address': 'Blok B-03',
      'joined_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<void> deleteMembershipRow(String membershipId) async {
    _throwIfConfigured();
    lastDeletedMembershipId = membershipId;
  }
}

class _FakeCheckpointDataSource implements CheckpointDataSource {
  final checkpointController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Map<String, dynamic>? lastInsertPayload;
  Map<String, dynamic>? lastUpdatePayload;
  Object? nextError;

  void _throwIfConfigured() {
    final err = nextError;
    if (err != null) {
      nextError = null;
      throw err;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCheckpointRows(String siteId) =>
      checkpointController.stream;

  @override
  Future<Map<String, dynamic>> insertCheckpointRow(
    Map<String, dynamic> payload,
  ) async {
    _throwIfConfigured();
    lastInsertPayload = payload;
    return <String, dynamic>{
      'id': 'cp-1',
      'site_id': payload['site_id'],
      'code': payload['code'],
      'name': payload['name'],
      'description': payload['description'],
      'latitude': payload['latitude'],
      'longitude': payload['longitude'],
      'radius_m': payload['radius_m'],
      'sort_order': payload['sort_order'],
      'target_time_local': payload['target_time_local'],
      'qr_token_version': 1,
      'is_active': true,
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> updateCheckpointRow({
    required String checkpointId,
    required Map<String, dynamic> updates,
  }) async {
    _throwIfConfigured();
    lastUpdatePayload = updates;
    return <String, dynamic>{
      'id': checkpointId,
      'site_id': 'site-1',
      'code': updates['code'] ?? 'POS-01',
      'name': updates['name'] ?? 'Pos Gerbang',
      'description': updates['description'] ?? '',
      'latitude': updates['latitude'] ?? -7.2575,
      'longitude': updates['longitude'] ?? 112.7521,
      'radius_m': updates['radius_m'] ?? 30,
      'sort_order': updates['sort_order'] ?? 1,
      'target_time_local': updates.containsKey('target_time_local')
          ? updates['target_time_local']
          : '22:30',
      'qr_token_version': 1,
      'is_active': updates['is_active'] ?? true,
      'created_at': '2026-06-01T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> rpcGetCheckpointQrPayload(
    String checkpointId,
  ) async {
    _throwIfConfigured();
    return <String, dynamic>{
      'checkpoint_id': checkpointId,
      'site_id': 'site-1',
      'code': 'POS-01',
      'name': 'Pos Gerbang',
      'qr_token_version': 1,
      'qr_payload': 'RD1|site-1|$checkpointId|1|${'a' * 64}',
    };
  }

  @override
  Future<Map<String, dynamic>> rpcRegenerateCheckpointQr(
    String checkpointId,
  ) async {
    _throwIfConfigured();
    return <String, dynamic>{
      'checkpoint_id': checkpointId,
      'site_id': 'site-1',
      'code': 'POS-01',
      'name': 'Pos Gerbang',
      'qr_token_version': 2,
      'qr_payload': 'RD1|site-1|$checkpointId|2|${'b' * 64}',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> rpcGetSitePatrolSummary({
    required String siteId,
    DateTime? since,
  }) async {
    _throwIfConfigured();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'checkpoint_id': 'cp-1',
        'last_verified_at': '2026-06-01T15:30:00Z',
        'verified_count': 3,
      },
    ];
  }
}

void main() {
  group('mapSupabaseError & DtoMappers', () {
    test('maps custom PostgreSQL P0002 not-found code to NotFoundFailure', () {
      final failure = mapSupabaseError(
        const PostgrestException(
          message: 'Kode undangan tidak ditemukan.',
          code: 'P0002',
        ),
      );
      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, 'P0002');
    });

    test('maps PatrolCheckin, SosEvent, IncidentReport, and EmptyHouseWatch DTOs', () {
      final checkin = DtoMappers.patrolCheckinFromMap(<String, dynamic>{
        'id': 'chk-1',
        'client_event_id': 'evt-1',
        'site_id': 'site-1',
        'checkpoint_id': 'cp-1',
        'officer_id': 'off-1',
        'qr_token_version_scanned': 1,
        'photo_path': 'site-1/checkins/off-1/evt-1.jpg',
        'photo_sha256': 'a' * 64,
        'captured_at_client': '2026-06-01T15:00:00Z',
        'synced_at_server': '2026-06-01T15:00:10Z',
        'latitude': -7.2575,
        'longitude': 112.7521,
        'accuracy_m': 12.5,
        'distance_m': 6.4,
        'is_mocked': false,
        'is_offline_submission': false,
        'officer_note': 'Situasi aman',
        'auto_status': 'flagged_review',
        'flag_reasons': ['LOW_GPS_ACCURACY'],
        'manual_status': 'manual_approved',
        'effective_status': 'manual_approved',
        'created_at': '2026-06-01T15:00:10Z',
      });
      expect(checkin.effectiveStatus, EffectiveCheckinStatus.manualApproved);
      expect(checkin.flagReasons, equals([CheckinFlagReason.lowGpsAccuracy]));

      final sos = DtoMappers.sosEventFromMap(<String, dynamic>{
        'id': 'sos-1',
        'site_id': 'site-1',
        'reporter_id': 'res-1',
        'category': 'kebakaran',
        'latitude': -7.2575,
        'longitude': 112.7521,
        'address_note': 'Blok C-10',
        'note': 'Asap di gudang',
        'status': 'open',
        'triggered_at': '2026-06-01T16:00:00Z',
      });
      expect(sos.category, SosCategory.kebakaran);
      expect(sos.isActive, isTrue);

      final report = DtoMappers.incidentReportFromMap(<String, dynamic>{
        'id': 'rep-1',
        'site_id': 'site-1',
        'reporter_id': 'res-1',
        'category': 'lampu_mati',
        'title': 'Lampu jalan mati',
        'description': 'Lampu di depan Blok A padam sejak magrib.',
        'photo_path': 'site-1/incidents/res-1/photo.jpg',
        'latitude': -7.2575,
        'longitude': 112.7521,
        'status': 'open',
        'created_at': '2026-06-01T12:00:00Z',
        'updated_at': '2026-06-01T12:00:00Z',
      });
      expect(report.category, IncidentCategory.lampuMati);

      final watch = DtoMappers.emptyHouseWatchFromMap(<String, dynamic>{
        'id': 'watch-1',
        'site_id': 'site-1',
        'resident_id': 'res-1',
        'house_label': 'Blok D-07',
        'latitude': -7.2575,
        'longitude': 112.7521,
        'start_date': '2026-06-10',
        'end_date': '2026-06-15',
        'emergency_contact': '08123456789',
        'notes': 'Kunci dititipkan ke saudara',
        'status': 'active',
        'created_at': '2026-06-01T10:00:00Z',
      });
      expect(watch.status, EmptyHouseStatus.active);
    });
  });

  group('SupabaseAuthSiteRepository', () {
    late _FakeAuthSiteDataSource dataSource;
    late SupabaseAuthSiteRepository repo;

    setUp(() {
      dataSource = _FakeAuthSiteDataSource();
      repo = SupabaseAuthSiteRepository.withDataSource(dataSource);
    });

    tearDown(() async {
      await dataSource.authController.close();
      await dataSource.memberController.close();
    });

    test('normalizes email on signIn and validates blank credentials', () async {
      final session = await repo.signIn(
        email: '  Admin@RondaDigital.id ',
        password: 'secret-password',
      );
      expect(session.email, 'admin@rondadigital.id');

      await expectLater(
        repo.signIn(email: '   ', password: ''),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('validates signUp inputs and maps AuthException cleanly', () async {
      await expectLater(
        repo.signUp(
          email: 'bad-email',
          password: 'password123',
          fullName: 'Budi',
          phoneWhatsapp: '0812345678',
        ),
        throwsA(isA<ValidationFailure>()),
      );

      dataSource.nextError = const AuthException('Email sudah terdaftar', statusCode: '422');
      await expectLater(
        repo.signUp(
          email: 'budi@example.com',
          password: 'password123',
          fullName: 'Budi Santoso',
          phoneWhatsapp: '0812345678',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('createSite calls create_site_with_admin RPC and validates geofence range', () async {
      final site = await repo.createSite(
        name: '  Perumahan Griya Aman  ',
        siteType: SiteType.perumahan,
        addressSummary: 'Kec. Sukolilo',
        centerLat: -7.2825,
        centerLng: 112.7954,
        defaultGeofenceMeters: 40,
      );

      expect(site.name, 'Perumahan Griya Aman');
      expect(site.inviteCode, 'ABCD2345');
      expect(dataSource.lastCreateSiteParams?['p_site_type'], 'perumahan');
      expect(dataSource.lastCreateSiteParams?['p_radius_m'], 40);

      await expectLater(
        repo.createSite(
          name: 'Valid Site',
          siteType: SiteType.desa,
          centerLat: -7.2,
          centerLng: 112.7,
          defaultGeofenceMeters: 5,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('joinSiteByCode uppercases code, validates length, and maps P0002 to NotFoundFailure', () async {
      final membership = await repo.joinSiteByCode(
        inviteCode: '  abcd2345 ',
        unitAddress: 'Blok A-12',
      );
      expect(dataSource.lastJoinParams?['p_invite_code'], 'ABCD2345');
      expect(membership.status, MembershipStatus.pending);

      await expectLater(
        repo.joinSiteByCode(inviteCode: 'SHORT'),
        throwsA(isA<ValidationFailure>()),
      );

      dataSource.nextError = const PostgrestException(
        message: 'Kode undangan tidak ditemukan.',
        code: 'P0002',
      );
      await expectLater(
        repo.joinSiteByCode(inviteCode: 'ZZZZ9999'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('watchSiteMembers enriches profiles and sorts pending first, then admin/officer/resident', () async {
      dataSource.profileRows = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'u-res',
          'full_name': 'Warga A',
          'phone_whatsapp': '08111',
          'created_at': '2026-06-01T00:00:00Z',
        },
        <String, dynamic>{
          'id': 'u-admin',
          'full_name': 'Ketua RT',
          'phone_whatsapp': '08222',
          'created_at': '2026-06-01T00:00:00Z',
        },
        <String, dynamic>{
          'id': 'u-pend',
          'full_name': 'Calon Warga',
          'phone_whatsapp': '08333',
          'created_at': '2026-06-01T00:00:00Z',
        },
      ];

      final futureFirst = repo.watchSiteMembers('site-1').first;
      dataSource.memberController.add(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'm-1',
          'site_id': 'site-1',
          'user_id': 'u-res',
          'role': 'resident',
          'status': 'active',
          'unit_address': 'A1',
          'joined_at': '2026-06-01T00:00:00Z',
        },
        <String, dynamic>{
          'id': 'm-2',
          'site_id': 'site-1',
          'user_id': 'u-admin',
          'role': 'admin',
          'status': 'active',
          'unit_address': 'A0',
          'joined_at': '2026-06-01T00:00:00Z',
        },
        <String, dynamic>{
          'id': 'm-3',
          'site_id': 'site-1',
          'user_id': 'u-pend',
          'role': 'resident',
          'status': 'pending',
          'unit_address': 'B2',
          'joined_at': '2026-06-01T00:00:00Z',
        },
      ]);

      final members = await futureFirst;
      expect(members.map((m) => m.profile.fullName).toList(), [
        'Calon Warga',
        'Ketua RT',
        'Warga A',
      ]);
    });

    test('updateSiteSettings, updateMember, removeMember, and network error mapping work cleanly', () async {
      final updatedSite = await repo.updateSiteSettings(
        siteId: 'site-1',
        sosEscalationMinutes: 5,
        requireJoinApproval: false,
      );
      expect(updatedSite.sosEscalationMinutes, 5);
      expect(dataSource.lastSiteUpdates?['require_join_approval'], isFalse);

      final updatedMember = await repo.updateMember(
        membershipId: 'm-3',
        role: SiteRole.officer,
        status: MembershipStatus.active,
      );
      expect(updatedMember.role, SiteRole.officer);
      expect(dataSource.lastMemberUpdates?['status'], 'active');

      await repo.removeMember('m-3');
      expect(dataSource.lastDeletedMembershipId, 'm-3');

      dataSource.nextError = const SocketException('Offline');
      await expectLater(
        repo.regenerateInviteCode('site-1'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('SupabaseCheckpointRepository', () {
    late _FakeCheckpointDataSource dataSource;
    late SupabaseCheckpointRepository repo;

    setUp(() {
      dataSource = _FakeCheckpointDataSource();
      repo = SupabaseCheckpointRepository.withDataSource(dataSource);
    });

    tearDown(() async {
      await dataSource.checkpointController.close();
    });

    test('watchCheckpoints sorts by sortOrder/code and respects activeOnly', () async {
      final futureActive = repo.watchCheckpoints('site-1', activeOnly: true).first;
      dataSource.checkpointController.add(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'cp-2',
          'site_id': 'site-1',
          'code': 'POS-02',
          'name': 'Pos Belakang',
          'description': '',
          'latitude': -7.258,
          'longitude': 112.753,
          'radius_m': 30,
          'sort_order': 2,
          'qr_token_version': 1,
          'is_active': true,
          'created_at': '2026-06-01T00:00:00Z',
        },
        <String, dynamic>{
          'id': 'cp-3',
          'site_id': 'site-1',
          'code': 'POS-03',
          'name': 'Pos Lama',
          'description': '',
          'latitude': -7.259,
          'longitude': 112.754,
          'radius_m': 30,
          'sort_order': 1,
          'qr_token_version': 1,
          'is_active': false,
          'created_at': '2026-06-01T00:00:00Z',
        },
        <String, dynamic>{
          'id': 'cp-1',
          'site_id': 'site-1',
          'code': 'POS-01',
          'name': 'Pos Depan',
          'description': '',
          'latitude': -7.257,
          'longitude': 112.752,
          'radius_m': 30,
          'sort_order': 1,
          'qr_token_version': 1,
          'is_active': true,
          'created_at': '2026-06-01T00:00:00Z',
        },
      ]);

      final activeCheckpoints = await futureActive;
      expect(activeCheckpoints.map((c) => c.code).toList(), ['POS-01', 'POS-02']);
    });

    test('createCheckpoint and updateCheckpoint validate inputs and clear targetTimeLocal', () async {
      final created = await repo.createCheckpoint(
        siteId: 'site-1',
        code: ' pos-01 ',
        name: 'Pos Gerbang',
        latitude: -7.2575,
        longitude: 112.7521,
        radiusMeters: 35,
        targetTimeLocal: '22:30',
      );
      expect(created.code, 'POS-01');
      expect(dataSource.lastInsertPayload?['target_time_local'], '22:30');

      final updated = await repo.updateCheckpoint(
        checkpointId: 'cp-1',
        clearTargetTimeLocal: true,
      );
      expect(updated.targetTimeLocal, isNull);
      expect(dataSource.lastUpdatePayload?.containsKey('target_time_local'), isTrue);
      expect(dataSource.lastUpdatePayload?['target_time_local'], isNull);

      await expectLater(
        repo.createCheckpoint(
          siteId: 'site-1',
          code: 'POS-02',
          name: 'Pos Taman',
          latitude: -7.2575,
          longitude: 112.7521,
          targetTimeLocal: '25:99',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('handles QR payload RPCs, patrol summary, and maps RLS errors to PermissionFailure', () async {
      final qr = await repo.getAdminQrPayload('cp-1');
      expect(qr.qrTokenVersion, 1);

      final rotated = await repo.regenerateQrToken('cp-1');
      expect(rotated.qrTokenVersion, 2);

      final summary = await repo.fetchPatrolSummary(siteId: 'site-1');
      expect(summary, hasLength(1));
      expect(summary.first.verifiedCount, 3);

      await repo.deactivateCheckpoint('cp-1');
      expect(dataSource.lastUpdatePayload?['is_active'], isFalse);

      dataSource.nextError = const PostgrestException(
        message: 'Hanya admin wilayah yang dapat mengganti token QR pos.',
        code: '42501',
      );
      await expectLater(
        repo.regenerateQrToken('cp-1'),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });
}
