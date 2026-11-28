import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/presentation/auth/join_site_sheet.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';
import 'package:ronda_app/presentation/shared/status_badge.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Multi-tenant site selector and onboarding hub (create new site or join via invite code).
class SiteOnboardingScreen extends ConsumerWidget {
  const SiteOnboardingScreen({super.key});

  Future<void> _openJoinSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const JoinSiteSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(mySitesProvider);
    final selectedSiteId = ref.watch(selectedSiteIdProvider);
    final user = ref.watch(authSessionProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Wilayah'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang daftar wilayah',
            onPressed: () => ref.read(mySitesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Keluar dari akun',
            onPressed: () =>
                ref.read(authActionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: sitesAsync.when(
          loading: () => const LoadingStateView(
            message: 'Memuat daftar wilayah Anda...',
            detail: 'Memeriksa keanggotaan aktif dan pengajuan tertunda.',
          ),
          error: (error, _) => ErrorStateView.fromFailure(
            AppFailure.fromException(error),
            title: 'Gagal memuat wilayah',
            onRetry: () => ref.read(mySitesProvider.notifier).refresh(),
          ),
          data: (sites) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(CivicTokens.spaceLg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (user != null) ...[
                        Text(
                          'Masuk sebagai ${user.email}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(CivicTokens.spaceLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Tambah atau Gabung Wilayah',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: CivicTokens.spaceXs),
                              Text(
                                'Buat wilayah baru sebagai Admin Wilayah, atau masukkan kode undangan 8 karakter dari pengurus setempat.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: CivicTokens.spaceLg),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.push(AppRoutes.createSite),
                                icon: const Icon(Icons.add_location_alt_outlined),
                                label: const Text('Buat Wilayah Baru'),
                              ),
                              const SizedBox(height: CivicTokens.spaceSm),
                              OutlinedButton.icon(
                                onPressed: () => _openJoinSheet(context),
                                icon: const Icon(Icons.vpn_key_outlined),
                                label: const Text('Gabung Pakai Kode Undangan'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: CivicTokens.spaceSection),
                      Text(
                        'Wilayah Anda',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: CivicTokens.spaceMd),
                      if (sites.isEmpty)
                        EmptyStateView(
                          title: 'Belum tergabung di wilayah mana pun',
                          description:
                              'Buat wilayah baru untuk mulai menyiapkan titik patroli, atau gabung menggunakan kode undangan.',
                          icon: Icons.location_city_outlined,
                          actionLabel: 'Gabung Pakai Kode Undangan',
                          onAction: () => _openJoinSheet(context),
                        )
                      else
                        Column(
                          children: [
                            for (final item in sites) ...[
                              _SiteMembershipTile(
                                item: item,
                                isSelected: item.site.id == selectedSiteId,
                                onTap: () {
                                  if (item.membership.isActive) {
                                    ref
                                        .read(selectedSiteIdProvider.notifier)
                                        .selectSite(item.site.id);
                                    context.go(
                                      AppRoutes.homeForRole(
                                        item.membership.role,
                                      ),
                                    );
                                  } else if (item.membership.isPending) {
                                    context.go(AppRoutes.pendingApproval);
                                  }
                                },
                              ),
                              const SizedBox(height: CivicTokens.spaceMd),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SiteMembershipTile extends StatelessWidget {
  const _SiteMembershipTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SiteMembershipWithSite item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final status = item.membership.status;
    final canOpen =
        status == MembershipStatus.active || status == MembershipStatus.pending;

    final badge = switch (status) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CivicTokens.radiusCard),
        side: BorderSide(
          color: isSelected ? tokens.accentOperational : tokens.borderHairline,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CivicTokens.radiusCard),
        onTap: canOpen ? onTap : null,
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
                        Text(item.site.name, style: textTheme.titleMedium),
                        const SizedBox(height: CivicTokens.spaceXs),
                        Text(
                          '${item.site.siteType.labelId} · ${item.membership.role.labelId}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (canOpen)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: tokens.inkSecondary,
                    ),
                ],
              ),
              if (item.site.addressSummary.trim().isNotEmpty) ...[
                const SizedBox(height: CivicTokens.spaceSm),
                Text(
                  item.site.addressSummary,
                  style: textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: CivicTokens.spaceMd),
              badge,
            ],
          ),
        ),
      ),
    );
  }
}
