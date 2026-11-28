import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/data/remote/dto_mappers.dart';
import 'package:ronda_app/data/remote/supabase_client_provider.dart';
import 'package:ronda_app/domain/models/models.dart';
import 'package:ronda_app/domain/repositories/auth_site_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Low-level data source abstraction allowing unit tests to exercise repository logic
/// without opening real Supabase sockets.
abstract interface class AuthSiteDataSource {
  Stream<AuthSessionUser?> watchAuthState();
  AuthSessionUser? get currentUser;

  Future<AuthSessionUser> signIn({
    required String email,
    required String password,
  });

  Future<AuthSessionUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  });

  Future<void> signOut();

  Future<Map<String, dynamic>?> fetchProfileRow(String userId);

  Future<Map<String, dynamic>> upsertProfileRow({
    required String userId,
    required String fullName,
    required String phoneWhatsapp,
  });

  Future<List<Map<String, dynamic>>> fetchMyMembershipsWithSites(String userId);

  Future<Map<String, dynamic>> rpcCreateSiteWithAdmin(
    Map<String, dynamic> params,
  );

  Future<Map<String, dynamic>> rpcJoinSiteByCode(Map<String, dynamic> params);

  Future<Map<String, dynamic>> updateSiteRow({
    required String siteId,
    required Map<String, dynamic> updates,
  });

  Future<Map<String, dynamic>> rpcRegenerateSiteInviteCode(String siteId);

  Future<Map<String, dynamic>> rpcUpdateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  });

  Stream<List<Map<String, dynamic>>> streamMembershipRows(String siteId);

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> userIds);

  Future<Map<String, dynamic>> updateMembershipRow({
    required String membershipId,
    required Map<String, dynamic> updates,
  });

  Future<void> deleteMembershipRow(String membershipId);
}

class _SupabaseAuthSiteDataSource implements AuthSiteDataSource {
  const _SupabaseAuthSiteDataSource(this._client);

  final SupabaseClient _client;

  @override
  AuthSessionUser? get currentUser => _toSessionUser(_client.auth.currentUser);

  @override
  Stream<AuthSessionUser?> watchAuthState() {
    return _client.auth.onAuthStateChange.map(
      (event) => _toSessionUser(event.session?.user),
    );
  }

  @override
  Future<AuthSessionUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = _toSessionUser(response.user);
    if (user == null) {
      throw const AuthFailure(
        message: 'Sesi masuk tidak berhasil dibuat. Silakan coba lagi.',
        code: 'AUTH_NO_USER',
      );
    }
    return user;
  }

  @override
  Future<AuthSessionUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{
        'full_name': fullName,
        'phone_whatsapp': phoneWhatsapp,
      },
    );
    final user = _toSessionUser(response.user);
    if (user == null) {
      throw const AuthFailure(
        message: 'Pendaftaran akun tidak mengembalikan data pengguna.',
        code: 'AUTH_SIGNUP_NO_USER',
      );
    }
    if (response.session != null) {
      await upsertProfileRow(
        userId: user.id,
        fullName: fullName,
        phoneWhatsapp: phoneWhatsapp,
      );
    }
    return user;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<Map<String, dynamic>?> fetchProfileRow(String userId) {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> upsertProfileRow({
    required String userId,
    required String fullName,
    required String phoneWhatsapp,
  }) {
    return _client
        .from('profiles')
        .upsert(<String, dynamic>{
          'id': userId,
          'full_name': fullName,
          'phone_whatsapp': phoneWhatsapp,
        })
        .select()
        .single();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyMembershipsWithSites(
    String userId,
  ) async {
    final rows = await _client
        .from('site_memberships')
        .select('*, sites!inner(*)')
        .eq('user_id', userId)
        .order('joined_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<Map<String, dynamic>> rpcCreateSiteWithAdmin(
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc('create_site_with_admin', params: params);
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>> rpcJoinSiteByCode(
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc('join_site_by_code', params: params);
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>> updateSiteRow({
    required String siteId,
    required Map<String, dynamic> updates,
  }) {
    return _client
        .from('sites')
        .update(updates)
        .eq('id', siteId)
        .select()
        .single();
  }

  @override
  Future<Map<String, dynamic>> rpcRegenerateSiteInviteCode(
    String siteId,
  ) async {
    final result = await _client.rpc(
      'regenerate_site_invite_code',
      params: <String, dynamic>{'p_site_id': siteId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>> rpcUpdateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  }) async {
    final result = await _client.rpc(
      'update_my_unit_address',
      params: <String, dynamic>{
        'p_site_id': siteId,
        'p_unit_address': unitAddress,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamMembershipRows(String siteId) {
    return _client
        .from('site_memberships')
        .stream(primaryKey: const ['id'])
        .eq('site_id', siteId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final rows =
        await _client.from('profiles').select().inFilter('id', userIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<Map<String, dynamic>> updateMembershipRow({
    required String membershipId,
    required Map<String, dynamic> updates,
  }) {
    return _client
        .from('site_memberships')
        .update(updates)
        .eq('id', membershipId)
        .select()
        .single();
  }

  @override
  Future<void> deleteMembershipRow(String membershipId) async {
    await _client.from('site_memberships').delete().eq('id', membershipId);
  }

  static AuthSessionUser? _toSessionUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthSessionUser(
      id: user.id,
      email: user.email ?? '',
    );
  }
}

/// Supabase-backed implementation of [AuthSiteRepository] with typed [AppFailure] mapping.
class SupabaseAuthSiteRepository implements AuthSiteRepository {
  SupabaseAuthSiteRepository(SupabaseClient client)
      : _dataSource = _SupabaseAuthSiteDataSource(client);

  SupabaseAuthSiteRepository.withDataSource(AuthSiteDataSource dataSource)
      : _dataSource = dataSource;

  final AuthSiteDataSource _dataSource;

  @override
  AuthSessionUser? get currentUser => _dataSource.currentUser;

  @override
  Stream<AuthSessionUser?> watchAuthState() => _dataSource.watchAuthState();

  @override
  Future<AuthSessionUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const ValidationFailure(
        message: 'Email dan kata sandi wajib diisi.',
        code: 'AUTH_EMPTY_CREDENTIALS',
      );
    }

    try {
      return await _dataSource.signIn(
        email: normalizedEmail,
        password: password,
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<AuthSessionUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = fullName.trim();
    final trimmedPhone = phoneWhatsapp.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const ValidationFailure(
        message: 'Masukkan alamat email yang valid.',
        code: 'AUTH_INVALID_EMAIL',
      );
    }
    if (password.length < 6) {
      throw const ValidationFailure(
        message: 'Kata sandi minimal 6 karakter.',
        code: 'AUTH_WEAK_PASSWORD',
      );
    }
    if (trimmedName.length < 2) {
      throw const ValidationFailure(
        message: 'Nama lengkap minimal 2 karakter.',
        code: 'PROFILE_INVALID_NAME',
      );
    }

    try {
      return await _dataSource.signUp(
        email: normalizedEmail,
        password: password,
        fullName: trimmedName,
        phoneWhatsapp: trimmedPhone,
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<UserProfile?> fetchMyProfile() async {
    final user = _requireCurrentUser();
    try {
      final row = await _dataSource.fetchProfileRow(user.id);
      return row != null ? DtoMappers.userProfileFromMap(row) : null;
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    final user = _requireCurrentUser();
    final trimmedName = fullName.trim();
    if (trimmedName.length < 2) {
      throw const ValidationFailure(
        message: 'Nama lengkap minimal 2 karakter.',
        code: 'PROFILE_INVALID_NAME',
      );
    }

    try {
      final row = await _dataSource.upsertProfileRow(
        userId: user.id,
        fullName: trimmedName,
        phoneWhatsapp: phoneWhatsapp.trim(),
      );
      return DtoMappers.userProfileFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<List<SiteMembershipWithSite>> listMySites() async {
    final user = _requireCurrentUser();
    try {
      final rows = await _dataSource.fetchMyMembershipsWithSites(user.id);
      return rows
          .map(DtoMappers.siteMembershipWithSiteFromMap)
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<Site> createSite({
    required String name,
    required SiteType siteType,
    String addressSummary = '',
    required double centerLat,
    required double centerLng,
    int defaultGeofenceMeters = 30,
  }) async {
    _requireCurrentUser();
    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      throw const ValidationFailure(
        message: 'Nama wilayah minimal 2 karakter.',
        code: 'SITE_INVALID_NAME',
      );
    }
    if (defaultGeofenceMeters < 10 || defaultGeofenceMeters > 200) {
      throw const ValidationFailure(
        message: 'Radius geofence default harus di antara 10 hingga 200 meter.',
        code: 'SITE_INVALID_GEOFENCE',
      );
    }

    try {
      final row = await _dataSource.rpcCreateSiteWithAdmin(<String, dynamic>{
        'p_name': trimmedName,
        'p_site_type': siteType.value,
        'p_address': addressSummary.trim(),
        'p_center_lat': centerLat,
        'p_center_lng': centerLng,
        'p_radius_m': defaultGeofenceMeters,
      });
      return DtoMappers.siteFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<SiteMembership> joinSiteByCode({
    required String inviteCode,
    String unitAddress = '',
  }) async {
    _requireCurrentUser();
    final normalizedCode = inviteCode.trim().toUpperCase();
    if (normalizedCode.length != 8) {
      throw const ValidationFailure(
        message: 'Kode undangan harus terdiri dari 8 karakter.',
        code: 'SITE_INVALID_INVITE_CODE',
      );
    }

    try {
      final row = await _dataSource.rpcJoinSiteByCode(<String, dynamic>{
        'p_invite_code': normalizedCode,
        'p_unit_address': unitAddress.trim(),
      });
      return DtoMappers.siteMembershipFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<Site> updateSiteSettings({
    required String siteId,
    String? name,
    SiteType? siteType,
    String? addressSummary,
    bool? requireJoinApproval,
    double? centerLat,
    double? centerLng,
    int? defaultGeofenceMeters,
    int? sosEscalationMinutes,
  }) async {
    _requireCurrentUser();
    final updates = <String, dynamic>{};

    if (name != null) {
      final trimmed = name.trim();
      if (trimmed.length < 2) {
        throw const ValidationFailure(
          message: 'Nama wilayah minimal 2 karakter.',
          code: 'SITE_INVALID_NAME',
        );
      }
      updates['name'] = trimmed;
    }
    if (siteType != null) {
      updates['site_type'] = siteType.value;
    }
    if (addressSummary != null) {
      updates['address_summary'] = addressSummary.trim();
    }
    if (requireJoinApproval != null) {
      updates['require_join_approval'] = requireJoinApproval;
    }
    if (centerLat != null) {
      updates['center_lat'] = centerLat;
    }
    if (centerLng != null) {
      updates['center_lng'] = centerLng;
    }
    if (defaultGeofenceMeters != null) {
      if (defaultGeofenceMeters < 10 || defaultGeofenceMeters > 200) {
        throw const ValidationFailure(
          message: 'Radius geofence default harus di antara 10 hingga 200 meter.',
          code: 'SITE_INVALID_GEOFENCE',
        );
      }
      updates['default_geofence_m'] = defaultGeofenceMeters;
    }
    if (sosEscalationMinutes != null) {
      if (sosEscalationMinutes < 1 || sosEscalationMinutes > 30) {
        throw const ValidationFailure(
          message: 'Waktu eskalasi SOS harus di antara 1 hingga 30 menit.',
          code: 'SITE_INVALID_SOS_SLA',
        );
      }
      updates['sos_escalation_minutes'] = sosEscalationMinutes;
    }

    if (updates.isEmpty) {
      throw const ValidationFailure(
        message: 'Tidak ada perubahan pengaturan wilayah yang dikirim.',
        code: 'SITE_NO_UPDATES',
      );
    }

    try {
      final row = await _dataSource.updateSiteRow(
        siteId: siteId,
        updates: updates,
      );
      return DtoMappers.siteFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<Site> regenerateInviteCode(String siteId) async {
    _requireCurrentUser();
    try {
      final row = await _dataSource.rpcRegenerateSiteInviteCode(siteId);
      return DtoMappers.siteFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<SiteMembership> updateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  }) async {
    _requireCurrentUser();
    try {
      final row = await _dataSource.rpcUpdateMyUnitAddress(
        siteId: siteId,
        unitAddress: unitAddress.trim(),
      );
      return DtoMappers.siteMembershipFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Stream<List<SiteMemberDetail>> watchSiteMembers(String siteId) {
    return _dataSource.streamMembershipRows(siteId).asyncMap((rows) async {
      try {
        final userIds = rows
            .map((r) => r['user_id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false);

        final profileRows = await _dataSource.fetchProfilesByIds(userIds);
        final profileById = <String, Map<String, dynamic>>{
          for (final p in profileRows)
            if (p['id'] is String) p['id'] as String: p,
        };

        final members = rows
            .map(
              (row) => DtoMappers.siteMemberDetailFromMap(
                row,
                profileMap: profileById[row['user_id']],
              ),
            )
            .toList(growable: false);

        members.sort(_compareMembers);
        return members;
      } catch (error, stackTrace) {
        throw mapSupabaseError(error, stackTrace);
      }
    });
  }

  @override
  Future<SiteMembership> updateMember({
    required String membershipId,
    SiteRole? role,
    MembershipStatus? status,
  }) async {
    _requireCurrentUser();
    final updates = <String, dynamic>{
      if (role != null) 'role': role.value,
      if (status != null) 'status': status.value,
    };
    if (updates.isEmpty) {
      throw const ValidationFailure(
        message: 'Pilih peran atau status baru sebelum menyimpan.',
        code: 'MEMBER_NO_UPDATES',
      );
    }

    try {
      final row = await _dataSource.updateMembershipRow(
        membershipId: membershipId,
        updates: updates,
      );
      return DtoMappers.siteMembershipFromMap(row);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  @override
  Future<void> removeMember(String membershipId) async {
    _requireCurrentUser();
    try {
      await _dataSource.deleteMembershipRow(membershipId);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  AuthSessionUser _requireCurrentUser() {
    final user = _dataSource.currentUser;
    if (user == null) {
      throw const AuthFailure(
        message: 'Silakan masuk terlebih dahulu untuk melanjutkan.',
        code: 'AUTH_REQUIRED',
      );
    }
    return user;
  }

  static int _compareMembers(SiteMemberDetail a, SiteMemberDetail b) {
    final statusOrder =
        _statusWeight(a.membership.status).compareTo(_statusWeight(b.membership.status));
    if (statusOrder != 0) {
      return statusOrder;
    }
    final roleOrder =
        _roleWeight(a.membership.role).compareTo(_roleWeight(b.membership.role));
    if (roleOrder != 0) {
      return roleOrder;
    }
    return a.profile.fullName
        .toLowerCase()
        .compareTo(b.profile.fullName.toLowerCase());
  }

  static int _statusWeight(MembershipStatus status) => switch (status) {
        MembershipStatus.pending => 0,
        MembershipStatus.active => 1,
        MembershipStatus.suspended => 2,
      };

  static int _roleWeight(SiteRole role) => switch (role) {
        SiteRole.admin => 0,
        SiteRole.officer => 1,
        SiteRole.resident => 2,
      };
}
