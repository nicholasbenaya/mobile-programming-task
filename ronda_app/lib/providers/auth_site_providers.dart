import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/profile.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/domain/repositories/auth_site_repository.dart';

/// Fallback repository used until Supabase runtime wiring is injected in ProviderScope.
class UnconfiguredAuthSiteRepository implements AuthSiteRepository {
  const UnconfiguredAuthSiteRepository();

  static const ConfigurationFailure _notConfiguredFailure =
      ConfigurationFailure(
        message:
            'Koneksi layanan backend belum aktif. Atur SUPABASE_URL dan SUPABASE_ANON_KEY terlebih dahulu.',
        code: 'BACKEND_NOT_WIRED',
      );

  @override
  AuthSessionUser? get currentUser => null;

  @override
  Stream<AuthSessionUser?> watchAuthState() => const Stream.empty();

  @override
  Future<AuthSessionUser> signIn({
    required String email,
    required String password,
  }) => Future.error(_notConfiguredFailure);

  @override
  Future<AuthSessionUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  }) => Future.error(_notConfiguredFailure);

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfile?> fetchMyProfile() async => null;

  @override
  Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phoneWhatsapp,
  }) => Future.error(_notConfiguredFailure);

  @override
  Future<List<SiteMembershipWithSite>> listMySites() async =>
      const <SiteMembershipWithSite>[];

  @override
  Future<Site> createSite({
    required String name,
    required SiteType siteType,
    String addressSummary = '',
    required double centerLat,
    required double centerLng,
    int defaultGeofenceMeters = 30,
  }) => Future.error(_notConfiguredFailure);

  @override
  Future<SiteMembership> joinSiteByCode({
    required String inviteCode,
    String unitAddress = '',
  }) => Future.error(_notConfiguredFailure);

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
  }) => Future.error(_notConfiguredFailure);

  @override
  Future<Site> regenerateInviteCode(String siteId) =>
      Future.error(_notConfiguredFailure);

  @override
  Future<SiteMembership> updateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  }) => Future.error(_notConfiguredFailure);

  @override
  Stream<List<SiteMemberDetail>> watchSiteMembers(String siteId) =>
      Stream.value(const <SiteMemberDetail>[]);

  @override
  Future<SiteMembership> updateMember({
    required String membershipId,
    SiteRole? role,
    MembershipStatus? status,
  }) => Future.error(_notConfiguredFailure);

  @override
  Future<void> removeMember(String membershipId) =>
      Future.error(_notConfiguredFailure);
}

final authSiteRepositoryProvider = Provider<AuthSiteRepository>(
  (ref) => const UnconfiguredAuthSiteRepository(),
);

/// Controls whether FlutterMap fetches live OSM tiles (override false in offline tests).
final mapNetworkTilesEnabledProvider = Provider<bool>((ref) => true);

final authSessionProvider = StreamProvider<AuthSessionUser?>((ref) async* {
  final repository = ref.watch(authSiteRepositoryProvider);
  yield repository.currentUser;
  yield* repository.watchAuthState();
});

final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null) {
    return null;
  }
  return ref.watch(authSiteRepositoryProvider).fetchMyProfile();
});

class SelectedSiteIdController extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authSessionProvider);
    return null;
  }

  void selectSite(String? siteId) {
    state = siteId;
  }
}

final selectedSiteIdProvider =
    NotifierProvider<SelectedSiteIdController, String?>(
      SelectedSiteIdController.new,
    );

class MySitesNotifier extends AsyncNotifier<List<SiteMembershipWithSite>> {
  @override
  Future<List<SiteMembershipWithSite>> build() async {
    final user = await ref.watch(authSessionProvider.future);
    if (user == null) {
      return const <SiteMembershipWithSite>[];
    }
    return ref.watch(authSiteRepositoryProvider).listMySites();
  }

  Future<void> refresh() async {
    final user = ref.read(authSessionProvider).asData?.value;
    if (user == null) {
      state = const AsyncData(<SiteMembershipWithSite>[]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authSiteRepositoryProvider).listMySites(),
    );
  }

  Future<Site> createSite({
    required String name,
    required SiteType siteType,
    String addressSummary = '',
    required double centerLat,
    required double centerLng,
    int defaultGeofenceMeters = 30,
  }) async {
    final site = await ref.read(authSiteRepositoryProvider).createSite(
      name: name,
      siteType: siteType,
      addressSummary: addressSummary,
      centerLat: centerLat,
      centerLng: centerLng,
      defaultGeofenceMeters: defaultGeofenceMeters,
    );
    await refresh();
    ref.read(selectedSiteIdProvider.notifier).selectSite(site.id);
    return site;
  }

  Future<SiteMembership> joinSiteByCode({
    required String inviteCode,
    String unitAddress = '',
  }) async {
    final membership = await ref.read(authSiteRepositoryProvider).joinSiteByCode(
      inviteCode: inviteCode.trim().toUpperCase(),
      unitAddress: unitAddress.trim(),
    );
    await refresh();
    if (membership.isActive) {
      ref.read(selectedSiteIdProvider.notifier).selectSite(membership.siteId);
    }
    return membership;
  }

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
    final updated = await ref
        .read(authSiteRepositoryProvider)
        .updateSiteSettings(
          siteId: siteId,
          name: name,
          siteType: siteType,
          addressSummary: addressSummary,
          requireJoinApproval: requireJoinApproval,
          centerLat: centerLat,
          centerLng: centerLng,
          defaultGeofenceMeters: defaultGeofenceMeters,
          sosEscalationMinutes: sosEscalationMinutes,
        );
    await refresh();
    return updated;
  }

  Future<Site> regenerateInviteCode(String siteId) async {
    final updated = await ref
        .read(authSiteRepositoryProvider)
        .regenerateInviteCode(siteId);
    await refresh();
    return updated;
  }

  Future<SiteMembership> updateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  }) async {
    final updated = await ref
        .read(authSiteRepositoryProvider)
        .updateMyUnitAddress(siteId: siteId, unitAddress: unitAddress.trim());
    await refresh();
    return updated;
  }
}

final mySitesProvider =
    AsyncNotifierProvider<MySitesNotifier, List<SiteMembershipWithSite>>(
      MySitesNotifier.new,
    );

/// Pure resolver selecting the active membership (preferring [selectedSiteId]).
SiteMembershipWithSite? resolveActiveMembership(
  List<SiteMembershipWithSite>? sites,
  String? selectedSiteId,
) {
  if (sites == null || sites.isEmpty) {
    return null;
  }

  final activeSites = sites.where((item) => item.membership.isActive).toList();
  if (activeSites.isEmpty) {
    return null;
  }

  if (selectedSiteId != null) {
    for (final item in activeSites) {
      if (item.site.id == selectedSiteId) {
        return item;
      }
    }
  }
  return activeSites.first;
}

/// Resolves the currently active site membership, preferring the user's explicit selection.
final activeMembershipProvider = Provider<SiteMembershipWithSite?>((ref) {
  final sites = ref.watch(mySitesProvider).asData?.value;
  final selectedId = ref.watch(selectedSiteIdProvider);
  return resolveActiveMembership(sites, selectedId);
});

final pendingMembershipsProvider = Provider<List<SiteMembershipWithSite>>((
  ref,
) {
  final sites = ref.watch(mySitesProvider).asData?.value;
  if (sites == null) {
    return const <SiteMembershipWithSite>[];
  }
  return sites.where((item) => item.membership.isPending).toList();
});

final siteMembersProvider = StreamProvider.family<List<SiteMemberDetail>, String>(
  (ref, siteId) {
    return ref.watch(authSiteRepositoryProvider).watchSiteMembers(siteId);
  },
);

class AuthActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authSiteRepositoryProvider)
          .signIn(email: email.trim(), password: password);
    });
    state = result;
    return !result.hasError;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authSiteRepositoryProvider)
          .signUp(
            email: email.trim(),
            password: password,
            fullName: fullName.trim(),
            phoneWhatsapp: phoneWhatsapp.trim(),
          );
    });
    state = result;
    return !result.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authSiteRepositoryProvider).signOut();
      ref.read(selectedSiteIdProvider.notifier).selectSite(null);
    });
  }

  Future<bool> updateMember({
    required String membershipId,
    SiteRole? role,
    MembershipStatus? status,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authSiteRepositoryProvider)
          .updateMember(membershipId: membershipId, role: role, status: status);
    });
    state = result;
    return !result.hasError;
  }

  Future<bool> removeMember(String membershipId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authSiteRepositoryProvider).removeMember(membershipId);
    });
    state = result;
    return !result.hasError;
  }
}

final authActionControllerProvider =
    NotifierProvider<AuthActionController, AsyncValue<void>>(
      AuthActionController.new,
    );

/// Human-readable Indonesian labels for site types and roles across auth/admin UI.
extension SiteTypeLabels on SiteType {
  String get labelId => switch (this) {
    SiteType.desa => 'Desa / Kelurahan',
    SiteType.perumahan => 'Perumahan',
    SiteType.rtRw => 'RT / RW',
    SiteType.klaster => 'Klaster',
    SiteType.fasilitas => 'Fasilitas',
    SiteType.lainnya => 'Lainnya',
  };
}

extension SiteRoleLabels on SiteRole {
  String get labelId => switch (this) {
    SiteRole.admin => 'Admin Wilayah',
    SiteRole.officer => 'Petugas Patroli',
    SiteRole.resident => 'Warga',
  };
}
