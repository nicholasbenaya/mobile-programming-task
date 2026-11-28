import 'package:flutter/material.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/presentation/shared/status_badge.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Displays the site's monospaced invite code with copy and regenerate actions.
class SiteInviteCodeCard extends StatelessWidget {
  const SiteInviteCodeCard({
    super.key,
    required this.inviteCode,
    required this.onCopy,
    required this.onRegenerate,
  });

  final String inviteCode;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CivicTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kode Undangan Wilayah', style: textTheme.titleLarge),
            const SizedBox(height: CivicTokens.spaceXs),
            Text(
              'Bagikan kode ini agar petugas dan warga dapat mengajukan bergabung.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: CivicTokens.spaceMd),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
                border: Border.all(color: tokens.borderHairline),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicTokens.spaceLg,
                  vertical: CivicTokens.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        inviteCode,
                        style: tokens.forensicMono.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Salin kode undangan',
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CivicTokens.spaceMd),
            OutlinedButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.autorenew_rounded),
              label: const Text('Buat Kode Undangan Baru'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Member card for Admin approval, role assignment, and suspension controls.
class SiteMemberManagementCard extends StatelessWidget {
  const SiteMemberManagementCard({
    super.key,
    required this.detail,
    required this.isSelf,
    required this.onApprove,
    required this.onReject,
    required this.onChangeRole,
    required this.onToggleSuspend,
  });

  final SiteMemberDetail detail;
  final bool isSelf;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<SiteRole> onChangeRole;
  final VoidCallback onToggleSuspend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final membership = detail.membership;
    final statusBadge = switch (membership.status) {
      MembershipStatus.active => const StatusBadge.custom(
        label: 'Aktif',
        icon: Icons.check_circle_outline,
        tone: StatusTone.verified,
        compact: true,
      ),
      MembershipStatus.pending => const StatusBadge.custom(
        label: 'Menunggu Persetujuan',
        icon: Icons.hourglass_top_rounded,
        tone: StatusTone.flagged,
        compact: true,
      ),
      MembershipStatus.suspended => const StatusBadge.custom(
        label: 'Ditangguhkan',
        icon: Icons.block_rounded,
        tone: StatusTone.rejected,
        compact: true,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CivicTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.profile.fullName, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        detail.profile.phoneWhatsapp,
                        style: textTheme.bodyMedium,
                      ),
                      if (membership.unitAddress.trim().isNotEmpty)
                        Text(
                          'Unit: ${membership.unitAddress}',
                          style: textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: CivicTokens.spaceSm),
                Flexible(child: statusBadge),
              ],
            ),
            const SizedBox(height: CivicTokens.spaceMd),
            if (membership.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: CivicTokens.spaceSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              )
            else if (!isSelf)
              Wrap(
                spacing: CivicTokens.spaceSm,
                runSpacing: CivicTokens.spaceSm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<SiteRole>(
                      initialValue: membership.role,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Peran',
                        isDense: true,
                      ),
                      items: SiteRole.values
                          .map(
                            (role) => DropdownMenuItem<SiteRole>(
                              value: role,
                              child: Text(role.labelId),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (role) {
                        if (role != null && role != membership.role) {
                          onChangeRole(role);
                        }
                      },
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onToggleSuspend,
                    child: Text(
                      membership.status == MembershipStatus.suspended
                          ? 'Aktifkan'
                          : 'Tangguhkan',
                    ),
                  ),
                ],
              )
            else
              Text(
                'Peran Anda: ${membership.role.labelId}',
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
