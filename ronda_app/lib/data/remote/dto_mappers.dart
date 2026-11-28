import 'package:ronda_app/domain/models/models.dart';

/// Pure static DTO mappers translating Supabase JSON rows into domain entities.
abstract final class DtoMappers {
  static UserProfile userProfileFromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: _reqString(map, 'id'),
      fullName: _optString(map, 'full_name') ?? '',
      phoneWhatsapp: _optString(map, 'phone_whatsapp') ?? '',
      createdAt: _reqDateTime(map, 'created_at'),
    );
  }

  static Site siteFromMap(Map<String, dynamic> map) {
    return Site(
      id: _reqString(map, 'id'),
      name: _reqString(map, 'name'),
      siteType: SiteType.fromValue(_reqString(map, 'site_type')),
      addressSummary: _optString(map, 'address_summary') ?? '',
      inviteCode: _reqString(map, 'invite_code'),
      requireJoinApproval: _optBool(map, 'require_join_approval') ?? true,
      centerLat: _reqDouble(map, 'center_lat'),
      centerLng: _reqDouble(map, 'center_lng'),
      defaultGeofenceMeters: _reqInt(map, 'default_geofence_m'),
      sosEscalationMinutes: _reqInt(map, 'sos_escalation_minutes'),
      createdBy: _reqString(map, 'created_by'),
      createdAt: _reqDateTime(map, 'created_at'),
    );
  }

  static SiteMembership siteMembershipFromMap(Map<String, dynamic> map) {
    return SiteMembership(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      userId: _reqString(map, 'user_id'),
      role: SiteRole.fromValue(_reqString(map, 'role')),
      status: MembershipStatus.fromValue(_reqString(map, 'status')),
      unitAddress: _optString(map, 'unit_address') ?? '',
      joinedAt: _reqDateTime(map, 'joined_at'),
    );
  }

  static SiteMembershipWithSite siteMembershipWithSiteFromMap(
    Map<String, dynamic> map,
  ) {
    final rawSite = map['sites'];
    if (rawSite is! Map<String, dynamic>) {
      throw const FormatException('Data relasi wilayah (sites) tidak valid.');
    }
    return SiteMembershipWithSite(
      membership: siteMembershipFromMap(map),
      site: siteFromMap(rawSite),
    );
  }

  static SiteMemberDetail siteMemberDetailFromMap(
    Map<String, dynamic> membershipMap, {
    Map<String, dynamic>? profileMap,
  }) {
    final membership = siteMembershipFromMap(membershipMap);
    final embedded = profileMap ?? _asMap(membershipMap['profiles']);
    final profile = embedded != null
        ? userProfileFromMap(embedded)
        : UserProfile(
            id: membership.userId,
            fullName: 'Anggota Wilayah',
            phoneWhatsapp: '',
            createdAt: membership.joinedAt,
          );
    return SiteMemberDetail(
      membership: membership,
      profile: profile,
    );
  }

  static Checkpoint checkpointFromMap(Map<String, dynamic> map) {
    return Checkpoint(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      code: _reqString(map, 'code'),
      name: _reqString(map, 'name'),
      description: _optString(map, 'description') ?? '',
      latitude: _reqDouble(map, 'latitude'),
      longitude: _reqDouble(map, 'longitude'),
      radiusMeters: _reqInt(map, 'radius_m'),
      sortOrder: _optInt(map, 'sort_order') ?? 0,
      targetTimeLocal: _optString(map, 'target_time_local'),
      qrTokenVersion: _reqInt(map, 'qr_token_version'),
      isActive: _optBool(map, 'is_active') ?? true,
      createdAt: _reqDateTime(map, 'created_at'),
    );
  }

  static CheckpointQrPayload checkpointQrPayloadFromMap(
    Map<String, dynamic> map,
  ) {
    return CheckpointQrPayload(
      checkpointId: _reqString(map, 'checkpoint_id'),
      siteId: _reqString(map, 'site_id'),
      code: _reqString(map, 'code'),
      name: _reqString(map, 'name'),
      qrTokenVersion: _reqInt(map, 'qr_token_version'),
      qrPayload: _reqString(map, 'qr_payload'),
    );
  }

  static CheckpointPatrolSummary checkpointPatrolSummaryFromMap(
    Map<String, dynamic> map,
  ) {
    return CheckpointPatrolSummary(
      checkpointId: _reqString(map, 'checkpoint_id'),
      lastVerifiedAt: _optDateTime(map, 'last_verified_at'),
      verifiedCount: _optInt(map, 'verified_count') ?? 0,
    );
  }

  static ShiftTemplate shiftTemplateFromMap(Map<String, dynamic> map) {
    return ShiftTemplate(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      name: _reqString(map, 'name'),
      startTime: _reqString(map, 'start_time'),
      endTime: _reqString(map, 'end_time'),
      isOvernight: _optBool(map, 'is_overnight') ?? false,
      isActive: _optBool(map, 'is_active') ?? true,
    );
  }

  static PatrolSchedule patrolScheduleFromMap(Map<String, dynamic> map) {
    final officerProfile = _asMap(map['profiles']);
    return PatrolSchedule(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      officerId: _reqString(map, 'officer_id'),
      templateId: _optString(map, 'template_id'),
      shiftName: _reqString(map, 'shift_name'),
      shiftDate: _reqDateTime(map, 'shift_date'),
      startsAt: _reqDateTime(map, 'starts_at'),
      endsAt: _reqDateTime(map, 'ends_at'),
      status: ScheduleStatus.fromValue(_reqString(map, 'status')),
      createdAt: _reqDateTime(map, 'created_at'),
      officerName:
          _optString(map, 'officer_name') ?? _optString(officerProfile, 'full_name'),
    );
  }

  static ShiftSwap shiftSwapFromMap(Map<String, dynamic> map) {
    return ShiftSwap(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      scheduleId: _reqString(map, 'schedule_id'),
      requesterId: _reqString(map, 'requester_id'),
      targetOfficerId: _reqString(map, 'target_officer_id'),
      targetScheduleId: _optString(map, 'target_schedule_id'),
      reason: _reqString(map, 'reason'),
      status: SwapStatus.fromValue(_reqString(map, 'status')),
      expiresAt: _reqDateTime(map, 'expires_at'),
      respondedAt: _optDateTime(map, 'responded_at'),
      createdAt: _reqDateTime(map, 'created_at'),
      requesterName: _optString(map, 'requester_name'),
      targetOfficerName: _optString(map, 'target_officer_name'),
    );
  }

  static ShiftHandover shiftHandoverFromMap(Map<String, dynamic> map) {
    return ShiftHandover(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      fromScheduleId: _optString(map, 'from_schedule_id'),
      authorId: _reqString(map, 'author_id'),
      summary: _reqString(map, 'summary'),
      assetStatus: _optString(map, 'asset_status') ?? '',
      photoPath: _optString(map, 'photo_path'),
      acknowledgedBy: _optString(map, 'acknowledged_by'),
      acknowledgedAt: _optDateTime(map, 'acknowledged_at'),
      clientEventId: _optString(map, 'client_event_id'),
      createdAt: _reqDateTime(map, 'created_at'),
      authorName: _optString(map, 'author_name'),
      acknowledgedByName: _optString(map, 'acknowledged_by_name'),
    );
  }

  static PatrolCheckin patrolCheckinFromMap(Map<String, dynamic> map) {
    final autoStatus =
        AutoVerificationStatus.fromValue(_reqString(map, 'auto_status'));
    final rawManual = _optString(map, 'manual_status');
    final manualStatus =
        rawManual != null ? ManualReviewStatus.fromValue(rawManual) : null;
    final rawEffective = _optString(map, 'effective_status');
    final effectiveStatus = rawEffective != null
        ? EffectiveCheckinStatus.fromValue(rawEffective)
        : EffectiveCheckinStatus.resolve(
            autoStatus: autoStatus,
            manualStatus: manualStatus,
          );

    final rawReasons = map['flag_reasons'];
    final reasons = <CheckinFlagReason>[];
    if (rawReasons is List) {
      for (final item in rawReasons) {
        if (item is String && item.isNotEmpty) {
          reasons.add(CheckinFlagReason.fromValue(item));
        }
      }
    }

    final checkpointMap = _asMap(map['checkpoints']);
    final officerMap = _asMap(map['officer']) ?? _asMap(map['profiles']);

    return PatrolCheckin(
      id: _reqString(map, 'id'),
      clientEventId: _reqString(map, 'client_event_id'),
      siteId: _reqString(map, 'site_id'),
      checkpointId: _reqString(map, 'checkpoint_id'),
      scheduleId: _optString(map, 'schedule_id'),
      officerId: _reqString(map, 'officer_id'),
      qrTokenVersionScanned: _reqInt(map, 'qr_token_version_scanned'),
      photoPath: _reqString(map, 'photo_path'),
      photoSha256: _optString(map, 'photo_sha256') ?? '',
      capturedAtClient: _reqDateTime(map, 'captured_at_client'),
      syncedAtServer: _reqDateTime(map, 'synced_at_server'),
      latitude: _reqDouble(map, 'latitude'),
      longitude: _reqDouble(map, 'longitude'),
      accuracyMeters: _reqDouble(map, 'accuracy_m'),
      distanceMeters: _reqDouble(map, 'distance_m'),
      isMocked: _optBool(map, 'is_mocked') ?? false,
      isOfflineSubmission: _optBool(map, 'is_offline_submission') ?? false,
      deviceModel: _optString(map, 'device_model'),
      officerNote: _optString(map, 'officer_note') ?? '',
      autoStatus: autoStatus,
      flagReasons: List<CheckinFlagReason>.unmodifiable(reasons),
      manualStatus: manualStatus,
      reviewedBy: _optString(map, 'reviewed_by'),
      reviewedAt: _optDateTime(map, 'reviewed_at'),
      reviewNote: _optString(map, 'review_note'),
      effectiveStatus: effectiveStatus,
      createdAt: _reqDateTime(map, 'created_at'),
      checkpointCode: _optString(checkpointMap, 'code'),
      checkpointName: _optString(checkpointMap, 'name'),
      officerName: _optString(officerMap, 'full_name'),
      reviewerName: _optString(map, 'reviewer_name'),
    );
  }

  static CheckinAuditLog checkinAuditLogFromMap(Map<String, dynamic> map) {
    final actorMap = _asMap(map['profiles']);
    return CheckinAuditLog(
      id: _reqString(map, 'id'),
      checkinId: _reqString(map, 'checkin_id'),
      siteId: _reqString(map, 'site_id'),
      actorId: _optString(map, 'actor_id'),
      actorName: _optString(map, 'actor_name') ?? _optString(actorMap, 'full_name'),
      action: AuditAction.fromValue(_reqString(map, 'action')),
      previousStatus: _optString(map, 'previous_status'),
      newStatus: _reqString(map, 'new_status'),
      note: _reqString(map, 'note'),
      createdAt: _reqDateTime(map, 'created_at'),
    );
  }

  static SosEvent sosEventFromMap(Map<String, dynamic> map) {
    return SosEvent(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      reporterId: _reqString(map, 'reporter_id'),
      category: SosCategory.fromValue(_reqString(map, 'category')),
      latitude: _reqDouble(map, 'latitude'),
      longitude: _reqDouble(map, 'longitude'),
      addressNote: _optString(map, 'address_note') ?? '',
      note: _optString(map, 'note') ?? '',
      status: SosStatus.fromValue(_reqString(map, 'status')),
      triggeredAt: _reqDateTime(map, 'triggered_at'),
      escalatedAt: _optDateTime(map, 'escalated_at'),
      responderId: _optString(map, 'responder_id'),
      acknowledgedAt: _optDateTime(map, 'acknowledged_at'),
      onSceneAt: _optDateTime(map, 'on_scene_at'),
      resolvedAt: _optDateTime(map, 'resolved_at'),
      resolutionNote: _optString(map, 'resolution_note'),
      resolutionPhotoPath: _optString(map, 'resolution_photo_path'),
      cancelReason: _optString(map, 'cancel_reason'),
      reporterName: _optString(map, 'reporter_name'),
      responderName: _optString(map, 'responder_name'),
    );
  }

  static DeviceToken deviceTokenFromMap(Map<String, dynamic> map) {
    return DeviceToken(
      id: _reqString(map, 'id'),
      userId: _reqString(map, 'user_id'),
      fcmToken: _reqString(map, 'fcm_token'),
      platform: DevicePlatform.fromValue(_reqString(map, 'platform')),
      updatedAt: _reqDateTime(map, 'updated_at'),
    );
  }

  static IncidentReport incidentReportFromMap(Map<String, dynamic> map) {
    return IncidentReport(
      id: _reqString(map, 'id'),
      clientEventId: _optString(map, 'client_event_id'),
      siteId: _reqString(map, 'site_id'),
      reporterId: _reqString(map, 'reporter_id'),
      category: IncidentCategory.fromValue(_reqString(map, 'category')),
      title: _reqString(map, 'title'),
      description: _reqString(map, 'description'),
      photoPath: _reqString(map, 'photo_path'),
      latitude: _reqDouble(map, 'latitude'),
      longitude: _reqDouble(map, 'longitude'),
      status: IncidentStatus.fromValue(_reqString(map, 'status')),
      handledBy: _optString(map, 'handled_by'),
      resolutionNote: _optString(map, 'resolution_note'),
      createdAt: _reqDateTime(map, 'created_at'),
      updatedAt: _reqDateTime(map, 'updated_at'),
      reporterName: _optString(map, 'reporter_name'),
      handledByName: _optString(map, 'handled_by_name'),
    );
  }

  static EmptyHouseWatch emptyHouseWatchFromMap(Map<String, dynamic> map) {
    return EmptyHouseWatch(
      id: _reqString(map, 'id'),
      siteId: _reqString(map, 'site_id'),
      residentId: _reqString(map, 'resident_id'),
      houseLabel: _reqString(map, 'house_label'),
      latitude: _reqDouble(map, 'latitude'),
      longitude: _reqDouble(map, 'longitude'),
      startDate: _reqDateTime(map, 'start_date'),
      endDate: _reqDateTime(map, 'end_date'),
      emergencyContact: _reqString(map, 'emergency_contact'),
      notes: _optString(map, 'notes') ?? '',
      status: EmptyHouseStatus.fromValue(_reqString(map, 'status')),
      createdAt: _reqDateTime(map, 'created_at'),
      residentName: _optString(map, 'resident_name'),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String _reqString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Kolom wajib $key tidak valid atau kosong.');
  }

  static String? _optString(Map<String, dynamic>? map, String key) {
    if (map == null) {
      return null;
    }
    final value = map[key];
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static double _reqDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Kolom desimal $key tidak valid.');
  }

  static int _reqInt(Map<String, dynamic> map, String key) {
    final parsed = _optInt(map, key);
    if (parsed == null) {
      throw FormatException('Kolom bilangan bulat $key tidak valid.');
    }
    return parsed;
  }

  static int? _optInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool? _optBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
    return null;
  }

  static DateTime _reqDateTime(Map<String, dynamic> map, String key) {
    final parsed = _optDateTime(map, key);
    if (parsed == null) {
      throw FormatException('Kolom waktu $key tidak valid.');
    }
    return parsed;
  }

  static DateTime? _optDateTime(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
