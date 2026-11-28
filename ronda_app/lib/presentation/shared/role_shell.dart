import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/presentation/admin/site_members_settings_screen.dart';
import 'package:ronda_app/presentation/auth/member_profile_panel.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

class _ShellTabSpec {
  const _ShellTabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}

/// Responsive 4-tab operational shell (NavigationBar < 600 dp, NavigationRail >= 600 dp).
class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({super.key, required this.role});

  final SiteRole role;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant RoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _selectedIndex = 0;
    }
  }

  List<_ShellTabSpec> _tabsForRole(SiteMembershipWithSite active) {
    return switch (widget.role) {
      SiteRole.admin => <_ShellTabSpec>[
        _ShellTabSpec(
          label: 'Monitor & Audit',
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield,
          body: EmptyStateView(
            title: 'Monitor & Audit Patroli',
            description:
                'Antrean audit check-in, peta pos patroli, dan ringkasan kepatuhan wilayah akan aktif setelah modul peta dan check-in terhubung.',
            icon: Icons.fact_check_outlined,
            actionLabel: 'Buka Pengaturan Wilayah',
            onAction: () => setState(() => _selectedIndex = 3),
          ),
        ),
        const _ShellTabSpec(
          label: 'Jadwal',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          body: EmptyStateView(
            title: 'Jadwal & Buku Mutasi',
            description:
                'Kalender shift petugas, pembuat jadwal otomatis, dan catatan serah terima akan muncul di sini.',
            icon: Icons.calendar_month_outlined,
          ),
        ),
        const _ShellTabSpec(
          label: 'Laporan',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          body: EmptyStateView(
            title: 'Laporan & Rumah Kosong',
            description:
                'Kotak masuk laporan non-SOS warga serta daftar pantauan lapor mudik akan ditampilkan di tab ini.',
            icon: Icons.assignment_outlined,
          ),
        ),
        _ShellTabSpec(
          label: 'Wilayah & Anggota',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          body: SiteMembersSettingsScreen(activeMembership: active),
        ),
      ],
      SiteRole.officer => <_ShellTabSpec>[
        const _ShellTabSpec(
          label: 'Patroli',
          icon: Icons.map_outlined,
          selectedIcon: Icons.map,
          body: EmptyStateView(
            title: 'Peta Patroli Aktif',
            description:
                'Peta pos patroli, radius geofence, dan pemindai QR check-in akan tampil di beranda petugas ini.',
            icon: Icons.map_outlined,
          ),
        ),
        const _ShellTabSpec(
          label: 'Jadwal & Mutasi',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          body: EmptyStateView(
            title: 'Jadwal & Buku Mutasi',
            description:
                'Jadwal shift Anda, pengajuan tukar shift antar petugas, dan buku mutasi serah terima tersedia di sini.',
            icon: Icons.swap_horiz_rounded,
          ),
        ),
        const _ShellTabSpec(
          label: 'Laporan',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          body: EmptyStateView(
            title: 'Laporan Lapangan',
            description:
                'Daftar laporan kejadian non-SOS wilayah beserta tindak lanjut petugas akan muncul di sini.',
            icon: Icons.assignment_outlined,
          ),
        ),
        _ShellTabSpec(
          label: 'SOS & Profil',
          icon: Icons.emergency_share_outlined,
          selectedIcon: Icons.emergency_share,
          body: MemberProfilePanel(active: active, allowUnitEdit: false),
        ),
      ],
      SiteRole.resident => <_ShellTabSpec>[
        const _ShellTabSpec(
          label: 'Beranda & SOS',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          body: EmptyStateView(
            title: 'Keamanan Wilayah & SOS',
            description:
                'Status patroli aktif wilayah dan tombol darurat SOS tahan 3 detik akan terhubung pada modul SOS.',
            icon: Icons.health_and_safety_outlined,
          ),
        ),
        const _ShellTabSpec(
          label: 'Peta & Jadwal',
          icon: Icons.map_outlined,
          selectedIcon: Icons.map,
          body: EmptyStateView(
            title: 'Transparansi Peta & Jadwal',
            description:
                'Progres patroli pos lingkungan dan daftar petugas jaga aktif dapat dipantau di halaman ini.',
            icon: Icons.map_outlined,
          ),
        ),
        const _ShellTabSpec(
          label: 'Lapor',
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          body: EmptyStateView(
            title: 'Laporan Warga & Lapor Mudik',
            description:
                'Kirim laporan fasilitas, kejadian non-SOS, atau pantauan rumah kosong sementara dari tab ini.',
            icon: Icons.report_problem_outlined,
          ),
        ),
        _ShellTabSpec(
          label: 'Profil',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          body: MemberProfilePanel(active: active, allowUnitEdit: true),
        ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeMembershipProvider);
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RondaDigital')),
        body: EmptyStateView(
          title: 'Belum ada wilayah aktif',
          description:
              'Pilih wilayah aktif Anda terlebih dahulu untuk melanjutkan.',
          icon: Icons.location_city_outlined,
          actionLabel: 'Pilih Wilayah',
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }

    final tabs = _tabsForRole(active);
    final currentIndex = _selectedIndex.clamp(0, tabs.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 600;
        final currentBody = tabs[currentIndex].body;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active.site.name,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge,
                ),
                Text(
                  widget.role.labelId,
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.inkSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              if (useRail)
                TextButton.icon(
                  onPressed: () => context.go(AppRoutes.onboarding),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Ganti Wilayah'),
                )
              else
                IconButton(
                  tooltip: 'Ganti Wilayah',
                  onPressed: () => context.go(AppRoutes.onboarding),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              const SizedBox(width: CivicTokens.spaceXs),
            ],
          ),
          body: SafeArea(
            child: useRail
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: currentIndex,
                        onDestinationSelected: (index) =>
                            setState(() => _selectedIndex = index),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: tokens.surfaceElevated,
                        indicatorColor: tokens.statusFlaggedTint,
                        destinations: tabs
                            .map(
                              (tab) => NavigationRailDestination(
                                icon: Icon(tab.icon),
                                selectedIcon: Icon(
                                  tab.selectedIcon,
                                  color: tokens.statusFlagged,
                                ),
                                label: Text(tab.label),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: tokens.borderHairline,
                      ),
                      Expanded(child: currentBody),
                    ],
                  )
                : currentBody,
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: tabs
                      .map(
                        (tab) => NavigationDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.selectedIcon),
                          label: tab.label,
                        ),
                      )
                      .toList(growable: false),
                ),
        );
      },
    );
  }
}
