import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/profile.dart';
import 'package:ronda_app/domain/models/site.dart';

/// Contract for authentication, user profiles, multi-tenant site lifecycle, and membership RBAC.
abstract interface class AuthSiteRepository {
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

  Future<UserProfile?> fetchMyProfile();

  Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phoneWhatsapp,
  });

  Future<List<SiteMembershipWithSite>> listMySites();

  Future<Site> createSite({
    required String name,
    required SiteType siteType,
    String addressSummary = '',
    required double centerLat,
    required double centerLng,
    int defaultGeofenceMeters = 30,
  });

  Future<SiteMembership> joinSiteByCode({
    required String inviteCode,
    String unitAddress = '',
  });

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
  });

  Future<Site> regenerateInviteCode(String siteId);

  Future<SiteMembership> updateMyUnitAddress({
    required String siteId,
    required String unitAddress,
  });

  Stream<List<SiteMemberDetail>> watchSiteMembers(String siteId);

  Future<SiteMembership> updateMember({
    required String membershipId,
    SiteRole? role,
    MembershipStatus? status,
  });

  Future<void> removeMember(String membershipId);
}
