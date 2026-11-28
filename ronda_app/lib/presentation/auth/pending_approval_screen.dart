import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/presentation/shared/status_badge.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Waiting view shown when the user's membership requests are pending Admin approval.
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSites = ref.watch(pendingMembershipsProvider);
    final isLoading = ref.watch(mySitesProvider).isLoading;
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pengajuan Wilayah'),
        actions: [
          IconButton(
            tooltip: 'Keluar dari akun',
            onPressed: () =>
                ref.read(authActionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CivicTokens.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(CivicTokens.spaceXl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: tokens.statusFlaggedTint,
                            borderRadius: BorderRadius.circular(
                              CivicTokens.radiusControl,
                            ),
                          ),
                          child: Icon(
                            Icons.hourglass_top_rounded,
                            color: tokens.statusFlagged,
                          ),
                        ),
                      ),
                      const SizedBox(height: CivicTokens.spaceLg),
                      Text(
                        'Menunggu Persetujuan Admin Wilayah',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: CivicTokens.spaceSm),
                      Text(
                        'Permintaan bergabung Anda sudah tercatat. Anda dapat langsung masuk setelah Admin Wilayah menyetujui keanggotaan Anda.',
                        style: textTheme.bodyMedium,
                      ),
                      if (pendingSites.isNotEmpty) ...[
                        const SizedBox(height: CivicTokens.spaceLg),
                        for (final item in pendingSites) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.surfaceSubtle,
                              borderRadius: BorderRadius.circular(
                                CivicTokens.radiusControl,
                              ),
                              border: Border.all(color: tokens.borderHairline),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                CivicTokens.spaceMd,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.site.name,
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: CivicTokens.spaceXs),
                                  Text(
                                    item.site.siteType.labelId,
                                    style: textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: CivicTokens.spaceSm),
                                  const StatusBadge.custom(
                                    label: 'Menunggu Persetujuan',
                                    icon: Icons.hourglass_top_rounded,
                                    tone: StatusTone.flagged,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: CivicTokens.spaceSm),
                        ],
                      ],
                      const SizedBox(height: CivicTokens.spaceXl),
                      FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () =>
                                  ref.read(mySitesProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Periksa Status'),
                      ),
                      const SizedBox(height: CivicTokens.spaceSm),
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        child: const Text('Buat atau Gabung Wilayah Lain'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
