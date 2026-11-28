import 'package:flutter/material.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';

/// Canonical operational statuses mapped in `DESIGN.md` section 6.3.
enum OperationalStatus {
  autoVerified,
  manualApproved,
  flaggedReview,
  autoRejected,
  manualRejected,
  offlinePending,
}

/// Visual tone categories for non-color-only status badges.
enum StatusTone { verified, flagged, rejected, offline }

/// Non-color-only operational status tag combining icon, Indonesian label, and semantic tint.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required OperationalStatus this.status,
    this.labelOverride,
    this.compact = false,
  }) : _customIcon = null,
       _customTone = null;

  /// Creates a badge for secondary workflows (reports, shifts, memberships) using the same tokens.
  const StatusBadge.custom({
    super.key,
    required String label,
    required IconData icon,
    required StatusTone tone,
    this.compact = false,
  }) : status = null,
       labelOverride = label,
       _customIcon = icon,
       _customTone = tone;

  final OperationalStatus? status;
  final String? labelOverride;
  final IconData? _customIcon;
  final StatusTone? _customTone;
  final bool compact;

  String get label => labelOverride ?? _defaultLabel(status!);

  IconData get icon => _customIcon ?? _defaultIcon(status!);

  StatusTone get tone => _customTone ?? _defaultTone(status!);

  static String _defaultLabel(OperationalStatus status) {
    return switch (status) {
      OperationalStatus.autoVerified => 'Terverifikasi',
      OperationalStatus.manualApproved => 'Disetujui Admin',
      OperationalStatus.flaggedReview => 'Perlu Tinjauan',
      OperationalStatus.autoRejected => 'Ditolak Otomatis',
      OperationalStatus.manualRejected => 'Ditolak Admin',
      OperationalStatus.offlinePending => 'Menunggu Sinkronisasi',
    };
  }

  static IconData _defaultIcon(OperationalStatus status) {
    return switch (status) {
      OperationalStatus.autoVerified => Icons.check_circle_outline,
      OperationalStatus.manualApproved => Icons.verified_user_outlined,
      OperationalStatus.flaggedReview => Icons.warning_amber_rounded,
      OperationalStatus.autoRejected => Icons.block_rounded,
      OperationalStatus.manualRejected => Icons.cancel_outlined,
      OperationalStatus.offlinePending => Icons.cloud_off_outlined,
    };
  }

  static StatusTone _defaultTone(OperationalStatus status) {
    return switch (status) {
      OperationalStatus.autoVerified ||
      OperationalStatus.manualApproved => StatusTone.verified,
      OperationalStatus.flaggedReview => StatusTone.flagged,
      OperationalStatus.autoRejected ||
      OperationalStatus.manualRejected => StatusTone.rejected,
      OperationalStatus.offlinePending => StatusTone.offline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final (foreground, background) = switch (tone) {
      StatusTone.verified => (tokens.statusVerified, tokens.statusVerifiedTint),
      StatusTone.flagged => (tokens.statusFlagged, tokens.statusFlaggedTint),
      StatusTone.rejected => (
        tokens.statusEmergencyText,
        tokens.statusEmergencyTint,
      ),
      StatusTone.offline => (tokens.statusOffline, tokens.statusOfflineTint),
    };

    final horizontalPadding = compact ? 8.0 : 10.0;
    final verticalPadding = compact ? 4.0 : 6.0;
    final iconSize = compact ? 15.0 : 16.0;

    return Semantics(
      label: 'Status: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(CivicTokens.radiusChip),
          border: Border.all(
            color: foreground.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  softWrap: true,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
