import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/profile.dart';

/// Domain entity for `sites`.
class Site {
  const Site({
    required this.id,
    required this.name,
    required this.siteType,
    required this.addressSummary,
    required this.inviteCode,
    required this.requireJoinApproval,
    required this.centerLat,
    required this.centerLng,
    required this.defaultGeofenceMeters,
    required this.sosEscalationMinutes,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;
  final SiteType siteType;
  final String addressSummary;
  final String inviteCode;
  final bool requireJoinApproval;
  final double centerLat;
  final double centerLng;
  final int defaultGeofenceMeters;
  final int sosEscalationMinutes;
  final String createdBy;
  final DateTime createdAt;

  Site copyWith({
    String? name,
    SiteType? siteType,
    String? addressSummary,
    String? inviteCode,
    bool? requireJoinApproval,
    double? centerLat,
    double? centerLng,
    int? defaultGeofenceMeters,
    int? sosEscalationMinutes,
  }) {
    return Site(
      id: id,
      name: name ?? this.name,
      siteType: siteType ?? this.siteType,
      addressSummary: addressSummary ?? this.addressSummary,
      inviteCode: inviteCode ?? this.inviteCode,
      requireJoinApproval: requireJoinApproval ?? this.requireJoinApproval,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      defaultGeofenceMeters:
          defaultGeofenceMeters ?? this.defaultGeofenceMeters,
      sosEscalationMinutes: sosEscalationMinutes ?? this.sosEscalationMinutes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site &&
          other.id == id &&
          other.name == name &&
          other.siteType == siteType &&
          other.addressSummary == addressSummary &&
          other.inviteCode == inviteCode &&
          other.requireJoinApproval == requireJoinApproval &&
          other.centerLat == centerLat &&
          other.centerLng == centerLng &&
          other.defaultGeofenceMeters == defaultGeofenceMeters &&
          other.sosEscalationMinutes == sosEscalationMinutes &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        siteType,
        addressSummary,
        inviteCode,
        requireJoinApproval,
        centerLat,
        centerLng,
        defaultGeofenceMeters,
        sosEscalationMinutes,
        createdBy,
        createdAt,
      );
}

/// Domain entity for `site_memberships`.
class SiteMembership {
  const SiteMembership({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.role,
    required this.status,
    required this.unitAddress,
    required this.joinedAt,
  });

  final String id;
  final String siteId;
  final String userId;
  final SiteRole role;
  final MembershipStatus status;
  final String unitAddress;
  final DateTime joinedAt;

  bool get isActive => status == MembershipStatus.active;
  bool get isPending => status == MembershipStatus.pending;

  SiteMembership copyWith({
    SiteRole? role,
    MembershipStatus? status,
    String? unitAddress,
  }) {
    return SiteMembership(
      id: id,
      siteId: siteId,
      userId: userId,
      role: role ?? this.role,
      status: status ?? this.status,
      unitAddress: unitAddress ?? this.unitAddress,
      joinedAt: joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteMembership &&
          other.id == id &&
          other.siteId == siteId &&
          other.userId == userId &&
          other.role == role &&
          other.status == status &&
          other.unitAddress == unitAddress &&
          other.joinedAt == joinedAt;

  @override
  int get hashCode =>
      Object.hash(id, siteId, userId, role, status, unitAddress, joinedAt);
}

/// Composite view pairing the current user's membership with its site details.
class SiteMembershipWithSite {
  const SiteMembershipWithSite({
    required this.membership,
    required this.site,
  });

  final SiteMembership membership;
  final Site site;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteMembershipWithSite &&
          other.membership == membership &&
          other.site == site;

  @override
  int get hashCode => Object.hash(membership, site);
}

/// Composite view pairing a site membership with the member's profile.
class SiteMemberDetail {
  const SiteMemberDetail({
    required this.membership,
    required this.profile,
  });

  final SiteMembership membership;
  final UserProfile profile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteMemberDetail &&
          other.membership == membership &&
          other.profile == profile;

  @override
  int get hashCode => Object.hash(membership, profile);
}
