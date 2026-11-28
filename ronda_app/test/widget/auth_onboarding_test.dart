import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_app/app.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/profile.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/domain/repositories/auth_site_repository.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

class FakeAuthSiteRepository implements AuthSiteRepository {
  FakeAuthSiteRepository({
    AuthSessionUser? initialUser,
    UserProfile? initialProfile,
    List<SiteMembershipWithSite>? initialSites,
    Map<String, List<SiteMemberDetail>>? initialMembersBySite,
    this.joinReturnsPending = true,
  }) : _currentUser = initialUser,
       _profile = initialProfile,
       _mySites = List<SiteMembershipWithSite>.from(
         initialSites ?? const <SiteMembershipWithSite>[],
       ),
       _membersBySite = Map<String, List<SiteMemberDetail>>.from(
         initialMembersBySite ?? const <String, List<SiteMemberDetail>>{},
       );

  final _authController = StreamController<AuthSessionUser?>.broadcast();
  final _membersControllers =
      <String, StreamController<List<SiteMemberDetail>>>{};

  AuthSessionUser? _currentUser;
  UserProfile? _profile;
  final List<SiteMembershipWithSite> _mySites;
  final Map<String, List<SiteMemberDetail>> _membersBySite;
  bool joinReturnsPending;

  int updateSettingsCalls = 0;
  int approveMemberCalls = 0;

  void dispose() {
    _authController.close();
    for (final controller in _membersControllers.values) {
      controller.close();
    }
  }

  void setMySites(List<SiteMembershipWithSite> next) {
    _mySites
      ..clear()
      ..addAll(next);
  }

  @override
  AuthSessionUser? get currentUser => _currentUser;

  @override
  Stream<AuthSessionUser?> watchAuthState() => _authController.stream;

  @override
  Future<AuthSessionUser> signIn({
    required String email,
    required String password,
  }) async {
    if (password == 'wrong') {
      throw const AuthFailure(message: 'Email atau kata sandi salah.');
    }
    _currentUser = AuthSessionUser(id: 'user-1', email: email);
    _profile ??= UserProfile(
      id: 'user-1',
      fullName: 'Pengguna Uji',
      phoneWhatsapp: '081234567890',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AuthSessionUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    _currentUser = AuthSessionUser(id: 'user-new', email: email);
    _profile = UserProfile(
      id: 'user-new',
      fullName: fullName,
      phoneWhatsapp: phoneWhatsapp,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<UserProfile?> fetchMyProfile() async => _profile;

  @override
  Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phoneWhatsapp,
  }) async {
    _profile = UserProfile(
      id: _currentUser!.id,
      fullName: fullName,
      phoneWhatsapp: phoneWhatsapp,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    return _profile!;
  }

  @override
  Future<List<SiteMembershipWithSite>> listMySites() async =>
      List<SiteMembershipWithSite>.unmodifiable(_mySites);

  @override
  Future<Site> createSite({
    required String name,
    required SiteType siteType,
    String addressSummary = '',
    required double centerLat,
    required double centerLng,
    int defaultGeofenceMeters = 30,
  }) async {
    final site = Site(
      id: 'site-${_mySites.length + 1}',
      name: name,
      siteType: siteType,
      addressSummary: addressSummary,
      inviteCode: 'RD88K2M1',
      requireJoinApproval: true,
      centerLat: centerLat,
      centerLng: centerLng,
      defaultGeofenceMeters: defaultGeofenceMeters,
      sosEscalationMinutes: 3,
      createdBy: _currentUser!.id,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final membership = SiteMembership(
      id: 'mem-${_mySites.length + 1}',
      siteId: site.id,
      userId: _currentUser!.id,
      role: SiteRole.admin,
      status: MembershipStatus.active,
      unitAddress: '',
      joinedAt: DateTime.utc(2026, 1, 1),
    );
    _mySites.add(SiteMembershipWithSite(membership: membership, site: site));
    return site;
  }

  @override
  Future<SiteMembership> joinSiteByCode({
    required String inviteCode,
    String unitAddress = '',
  }) async {
    if (inviteCode.toUpperCase() != 'MELATI01') {
      throw const NotFoundFailure(message: 'Kode undangan tidak ditemukan.');
    }
    final site = _sampleSite(id: 'site-join', name: 'Perumahan Melati');
    final membership = SiteMembership(
      id: 'mem-join',
      siteId: site.id,
      userId: _currentUser!.id,
      role: SiteRole.resident,
      status: joinReturnsPending
          ? MembershipStatus.pending
          : MembershipStatus.active,
      unitAddress: unitAddress,
      joinedAt: DateTime.utc(2026, 1, 1),
    );
    _mySites.add(SiteMembershipWithSite(membership: membership, site: site));
    return membership;
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
    updateSettingsCalls++;
    final index = _mySites.indexWhere((e) => e.site.id == siteId);
    final updated = _mySites[index].site.copyWith(
      name: name,
      siteType: siteType,
      addressSummary: addressSummary,
      requireJoinApproval: requireJoinApproval,
      centerLat: centerLat,
      centerLng: centerLng,
      defaultGeofenceMeters: defaultGeofenceMeters,
      sosEscalationMinutes: sosEscalationMinutes,
    );
    _mySites[index] = SiteMembershipWithSite(
      membership: _mySites[index].membership,
      site: updated,
    );
    return updated;
  }

  @override
  Future<Site> regenerateInviteCode(String siteId) async {
    final index = _mySites.indexWhere((e) => e.site.id == siteId);
    final updated = _mySites[index].site.copyWith(inviteCode: 'NEW99881');
    _mySites[index] = SiteMembershipWithSite(
      membership: _mySites[index].membership,
      site: updated,
    );
    return updated;
  }

  @override
  Future<SiteMembership> updateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  }) async {
    final index = _mySites.indexWhere((e) => e.site.id == siteId);
    final updated = _mySites[index].membership.copyWith(
      unitAddress: unitAddress,
    );
    _mySites[index] = SiteMembershipWithSite(
      membership: updated,
      site: _mySites[index].site,
    );
    return updated;
  }

  @override
  Stream<List<SiteMemberDetail>> watchSiteMembers(String siteId) async* {
    yield List<SiteMemberDetail>.unmodifiable(
      _membersBySite[siteId] ?? const <SiteMemberDetail>[],
    );
    final controller = _membersControllers.putIfAbsent(
      siteId,
      () => StreamController<List<SiteMemberDetail>>.broadcast(),
    );
    yield* controller.stream;
  }

  @override
  Future<SiteMembership> updateMember({
    required String membershipId,
    SiteRole? role,
    MembershipStatus? status,
  }) async {
    if (status == MembershipStatus.active) {
      approveMemberCalls++;
    }
    for (final entry in _membersBySite.entries) {
      final list = entry.value;
      final index = list.indexWhere((m) => m.membership.id == membershipId);
      if (index != -1) {
        final updatedMembership = list[index].membership.copyWith(
          role: role,
          status: status,
        );
        final updatedList = List<SiteMemberDetail>.from(list);
        updatedList[index] = SiteMemberDetail(
          membership: updatedMembership,
          profile: list[index].profile,
        );
        _membersBySite[entry.key] = updatedList;
        _membersControllers[entry.key]?.add(updatedList);
        return updatedMembership;
      }
    }
    throw const NotFoundFailure(message: 'Anggota tidak ditemukan.');
  }

  @override
  Future<void> removeMember(String membershipId) async {
    for (final entry in _membersBySite.entries) {
      final updatedList = entry.value
          .where((m) => m.membership.id != membershipId)
          .toList();
      _membersBySite[entry.key] = updatedList;
      _membersControllers[entry.key]?.add(updatedList);
    }
  }
}

Site _sampleSite({String id = 'site-1', String name = 'Klaster Flamboyan'}) {
  return Site(
    id: id,
    name: name,
    siteType: SiteType.klaster,
    addressSummary: 'Surabaya Timur',
    inviteCode: 'MELATI01',
    requireJoinApproval: true,
    centerLat: -7.28251,
    centerLng: 112.79548,
    defaultGeofenceMeters: 30,
    sosEscalationMinutes: 3,
    createdBy: 'user-admin',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

SiteMembershipWithSite _membershipWithSite({
  required SiteRole role,
  MembershipStatus status = MembershipStatus.active,
  String siteId = 'site-1',
  String siteName = 'Klaster Flamboyan',
  String userId = 'user-1',
}) {
  return SiteMembershipWithSite(
    membership: SiteMembership(
      id: 'mem-$siteId-$userId',
      siteId: siteId,
      userId: userId,
      role: role,
      status: status,
      unitAddress: 'Blok A No. 4',
      joinedAt: DateTime.utc(2026, 1, 1),
    ),
    site: _sampleSite(id: siteId, name: siteName),
  );
}

void main() {
  Future<void> setViewport(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('resolveAppRedirect RBAC & onboarding guards', () {
    final adminSite = _membershipWithSite(role: SiteRole.admin);
    final officerSite = _membershipWithSite(role: SiteRole.officer);
    final residentSite = _membershipWithSite(role: SiteRole.resident);

    test('redirects unauthenticated users to /login except /register', () {
      expect(
        resolveAppRedirect(
          location: AppRoutes.adminHome,
          isAuthLoading: false,
          isAuthenticated: false,
          isSitesLoading: false,
          activeMembership: null,
          hasPendingMembership: false,
        ),
        AppRoutes.login,
      );
      expect(
        resolveAppRedirect(
          location: AppRoutes.register,
          isAuthLoading: false,
          isAuthenticated: false,
          isSitesLoading: false,
          activeMembership: null,
          hasPendingMembership: false,
        ),
        isNull,
      );
    });

    test('routes no-site users to /onboarding and pending users to /pending-approval', () {
      expect(
        resolveAppRedirect(
          location: AppRoutes.login,
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: null,
          hasPendingMembership: false,
        ),
        AppRoutes.onboarding,
      );
      expect(
        resolveAppRedirect(
          location: AppRoutes.residentHome,
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: null,
          hasPendingMembership: true,
        ),
        AppRoutes.pendingApproval,
      );
    });

    test('enforces strict role shell isolation and SOS deep-link guard', () {
      expect(
        resolveAppRedirect(
          location: AppRoutes.adminHome,
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: residentSite,
          hasPendingMembership: false,
        ),
        AppRoutes.residentHome,
      );
      expect(
        resolveAppRedirect(
          location: AppRoutes.residentHome,
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: officerSite,
          hasPendingMembership: false,
        ),
        AppRoutes.officerHome,
      );
      expect(
        resolveAppRedirect(
          location: AppRoutes.adminHome,
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: adminSite,
          hasPendingMembership: false,
        ),
        isNull,
      );
      expect(
        resolveAppRedirect(
          location: AppRoutes.sosDetail('sos-42'),
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: officerSite,
          hasPendingMembership: false,
        ),
        isNull,
      );
      expect(
        resolveAppRedirect(
          location: AppRoutes.sosDetail('sos-42'),
          isAuthLoading: false,
          isAuthenticated: true,
          isSitesLoading: false,
          activeMembership: null,
          hasPendingMembership: true,
        ),
        AppRoutes.pendingApproval,
      );
    });
  });

  group('Auth, onboarding, and pending approval flows', () {
    testWidgets('unauthenticated user registers, creates a site, and enters Admin shell', (
      tester,
    ) async {
      await setViewport(tester, width: 390, height: 844);
      final repo = FakeAuthSiteRepository();
      addTearDown(repo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSiteRepositoryProvider.overrideWithValue(repo),
            mapNetworkTilesEnabledProvider.overrideWithValue(false),
          ],
          child: const RondaApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Akun'), findsOneWidget);
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Identitas Pengguna'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Lengkap'),
        'Budi Santoso',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nomor WhatsApp'),
        '081234567890',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'budi@ronda.id',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kata Sandi'),
        'rahasia123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi'),
        'rahasia123',
      );

      await tester.ensureVisible(find.text('Buat Akun'));
      await tester.tap(find.text('Buat Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Wilayah'), findsOneWidget);
      expect(find.text('Buat Wilayah Baru'), findsOneWidget);

      await tester.tap(find.text('Buat Wilayah Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Titik Pusat Peta Wilayah'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Wilayah'),
        'Perumahan Melati Asri',
      );
      await tester.ensureVisible(find.text('Simpan & Buat Wilayah'));
      await tester.tap(find.text('Simpan & Buat Wilayah'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Perumahan Melati Asri'), findsOneWidget);
      expect(find.text('Monitor & Audit'), findsOneWidget);
      expect(find.text('Wilayah & Anggota'), findsOneWidget);
    });

    testWidgets('joining a site requiring approval routes to PendingApprovalScreen', (
      tester,
    ) async {
      await setViewport(tester, width: 390, height: 844);
      final repo = FakeAuthSiteRepository(
        initialUser: const AuthSessionUser(
          id: 'user-warga',
          email: 'warga@ronda.id',
        ),
        joinReturnsPending: true,
      );
      addTearDown(repo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authSiteRepositoryProvider.overrideWithValue(repo)],
          child: const RondaApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pilih Wilayah'), findsOneWidget);
      await tester.tap(find.text('Gabung Pakai Kode Undangan').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kode Undangan'),
        'MELATI01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Alamat Unit / Blok (Opsional)'),
        'Blok D No. 7',
      );
      await tester.tap(find.text('Ajukan Bergabung'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Menunggu Persetujuan Admin Wilayah'), findsOneWidget);
      expect(find.text('Perumahan Melati'), findsOneWidget);
    });
  });

  group('All 3 role shells, responsive NavigationRail, and Admin settings', () {
    for (final roleCase in <(SiteRole, List<String>)>[
      (
        SiteRole.admin,
        <String>['Monitor & Audit', 'Jadwal', 'Laporan', 'Wilayah & Anggota'],
      ),
      (
        SiteRole.officer,
        <String>['Patroli', 'Jadwal & Mutasi', 'Laporan', 'SOS & Profil'],
      ),
      (
        SiteRole.resident,
        <String>['Beranda & SOS', 'Peta & Jadwal', 'Lapor', 'Profil'],
      ),
    ]) {
      testWidgets(
        'renders ${roleCase.$1.value} shell cleanly on mobile NavigationBar and tablet NavigationRail',
        (tester) async {
          final repo = FakeAuthSiteRepository(
            initialUser: const AuthSessionUser(
              id: 'user-1',
              email: 'aktif@ronda.id',
            ),
            initialSites: [_membershipWithSite(role: roleCase.$1)],
          );
          addTearDown(repo.dispose);

          await setViewport(tester, width: 390, height: 844);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [authSiteRepositoryProvider.overrideWithValue(repo)],
              child: const RondaApp(themeModeOverride: ThemeMode.light),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(find.byType(NavigationRail), findsNothing);
          for (final label in roleCase.$2) {
            expect(find.text(label), findsOneWidget);
          }

          // Tablet width >= 600 dp switches to NavigationRail cleanly.
          await setViewport(tester, width: 720, height: 900);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [authSiteRepositoryProvider.overrideWithValue(repo)],
              child: const RondaApp(themeModeOverride: ThemeMode.dark),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(NavigationRail), findsOneWidget);
          expect(find.byType(NavigationBar), findsNothing);
        },
      );
    }

    testWidgets(
      'Admin Site Settings saves configuration and approves a pending member',
      (tester) async {
        await setViewport(tester, width: 412, height: 915);
        final pendingMember = SiteMemberDetail(
          membership: SiteMembership(
            id: 'mem-pending-1',
            siteId: 'site-1',
            userId: 'user-2',
            role: SiteRole.resident,
            status: MembershipStatus.pending,
            unitAddress: 'Blok E No. 3',
            joinedAt: DateTime.utc(2026, 1, 2),
          ),
          profile: UserProfile(
            id: 'user-2',
            fullName: 'Rina Wijaya',
            phoneWhatsapp: '081299998888',
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        );

        final repo = FakeAuthSiteRepository(
          initialUser: const AuthSessionUser(
            id: 'user-1',
            email: 'admin@ronda.id',
          ),
          initialSites: [_membershipWithSite(role: SiteRole.admin)],
          initialMembersBySite: {
            'site-1': [pendingMember],
          },
        );
        addTearDown(repo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authSiteRepositoryProvider.overrideWithValue(repo)],
            child: const RondaApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wilayah & Anggota'));
        await tester.pumpAndSettle();

        expect(find.text('MELATI01'), findsOneWidget);
        expect(find.text('Rina Wijaya'), findsOneWidget);

        final saveButton = find.text('Simpan Pengaturan Wilayah');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(repo.updateSettingsCalls, 1);

        final approveButton = find.text('Setujui');
        await tester.ensureVisible(approveButton);
        await tester.tap(approveButton);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(repo.approveMemberCalls, 1);
      },
    );

    testWidgets('opens SOS deep-link route placeholder for active officer', (
      tester,
    ) async {
      await setViewport(tester, width: 360, height: 780);
      final repo = FakeAuthSiteRepository(
        initialUser: const AuthSessionUser(
          id: 'user-officer',
          email: 'petugas@ronda.id',
        ),
        initialSites: [
          _membershipWithSite(role: SiteRole.officer, userId: 'user-officer'),
        ],
      );
      addTearDown(repo.dispose);

      final container = ProviderContainer(
        overrides: [authSiteRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RondaApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go(AppRoutes.sosDetail('sos-99'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pelacak SOS #sos-99'), findsOneWidget);

      await tester.tap(find.text('Kembali ke Beranda'));
      await tester.pumpAndSettle();
      expect(find.text('Patroli'), findsOneWidget);
    });
  });
}
