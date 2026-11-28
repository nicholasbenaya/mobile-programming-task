import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/presentation/auth/site_member_card.dart';
import 'package:ronda_app/presentation/auth/site_settings_form_card.dart';
import 'package:ronda_app/presentation/auth/theme_mode_selector.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Admin Wilayah screen for site configuration, invite codes, and member approval/RBAC.
class SiteMembersSettingsScreen extends ConsumerStatefulWidget {
  const SiteMembersSettingsScreen({super.key, required this.activeMembership});

  final SiteMembershipWithSite activeMembership;

  @override
  ConsumerState<SiteMembersSettingsScreen> createState() =>
      _SiteMembersSettingsScreenState();
}

class _SiteMembersSettingsScreenState
    extends ConsumerState<SiteMembersSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _geofenceController;
  late final TextEditingController _sosSlaController;
  late SiteType _siteType;
  late bool _requireJoinApproval;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final site = widget.activeMembership.site;
    _nameController = TextEditingController(text: site.name);
    _addressController = TextEditingController(text: site.addressSummary);
    _geofenceController = TextEditingController(
      text: site.defaultGeofenceMeters.toString(),
    );
    _sosSlaController = TextEditingController(
      text: site.sosEscalationMinutes.toString(),
    );
    _siteType = site.siteType;
    _requireJoinApproval = site.requireJoinApproval;
  }

  @override
  void didUpdateWidget(covariant SiteMembersSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeMembership.site.id != widget.activeMembership.site.id) {
      final site = widget.activeMembership.site;
      _nameController.text = site.name;
      _addressController.text = site.addressSummary;
      _geofenceController.text = site.defaultGeofenceMeters.toString();
      _sosSlaController.text = site.sosEscalationMinutes.toString();
      _siteType = site.siteType;
      _requireJoinApproval = site.requireJoinApproval;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _geofenceController.dispose();
    _sosSlaController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(mySitesProvider.notifier)
          .updateSiteSettings(
            siteId: widget.activeMembership.site.id,
            name: _nameController.text.trim(),
            siteType: _siteType,
            addressSummary: _addressController.text.trim(),
            requireJoinApproval: _requireJoinApproval,
            defaultGeofenceMeters: int.parse(_geofenceController.text.trim()),
            sosEscalationMinutes: int.parse(_sosSlaController.text.trim()),
          );
      _showSnack('Pengaturan wilayah berhasil disimpan.');
    } catch (error) {
      _showSnack(AppFailure.fromException(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _regenerateInviteCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Kode Undangan Baru?'),
        content: const Text(
          'Kode undangan lama tidak akan bisa digunakan lagi oleh anggota baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Buat Kode Baru'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      final updated = await ref
          .read(mySitesProvider.notifier)
          .regenerateInviteCode(widget.activeMembership.site.id);
      _showSnack('Kode undangan baru: ${updated.inviteCode}');
    } catch (error) {
      _showSnack(AppFailure.fromException(error).message);
    }
  }

  Future<void> _updateMember(
    SiteMemberDetail detail, {
    SiteRole? role,
    MembershipStatus? status,
  }) async {
    final ok = await ref
        .read(authActionControllerProvider.notifier)
        .updateMember(
          membershipId: detail.membership.id,
          role: role,
          status: status,
        );
    if (!mounted) {
      return;
    }
    if (ok) {
      _showSnack('Data anggota ${detail.profile.fullName} diperbarui.');
    } else {
      final error = ref.read(authActionControllerProvider).asError?.error;
      _showSnack(
        error != null
            ? AppFailure.fromException(error).message
            : 'Gagal memperbarui anggota.',
      );
    }
  }

  Future<void> _removeMember(SiteMemberDetail detail) async {
    final ok = await ref
        .read(authActionControllerProvider.notifier)
        .removeMember(detail.membership.id);
    if (!mounted) {
      return;
    }
    if (ok) {
      _showSnack('Anggota ${detail.profile.fullName} dihapus dari wilayah.');
    } else {
      final error = ref.read(authActionControllerProvider).asError?.error;
      _showSnack(
        error != null
            ? AppFailure.fromException(error).message
            : 'Gagal menghapus anggota.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.activeMembership.site;
    final currentUserId = ref.watch(authSessionProvider).asData?.value?.id;
    final membersAsync = ref.watch(siteMembersProvider(site.id));
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        CivicTokens.spaceLg,
        CivicTokens.spaceLg,
        CivicTokens.spaceLg,
        CivicTokens.spaceSection + bottomInset,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SiteInviteCodeCard(
                inviteCode: site.inviteCode,
                onCopy: () async {
                  await Clipboard.setData(ClipboardData(text: site.inviteCode));
                  _showSnack('Kode undangan ${site.inviteCode} disalin.');
                },
                onRegenerate: _regenerateInviteCode,
              ),
              const SizedBox(height: CivicTokens.spaceLg),
              SiteSettingsFormCard(
                formKey: _formKey,
                nameController: _nameController,
                addressController: _addressController,
                geofenceController: _geofenceController,
                sosSlaController: _sosSlaController,
                siteType: _siteType,
                requireJoinApproval: _requireJoinApproval,
                isSaving: _isSaving,
                onSiteTypeChanged: (type) => setState(() => _siteType = type),
                onRequireApprovalChanged: (value) =>
                    setState(() => _requireJoinApproval = value),
                onSave: _saveSettings,
              ),
              const SizedBox(height: CivicTokens.spaceSection),
              Text('Persetujuan & Anggota Wilayah', style: textTheme.titleLarge),
              const SizedBox(height: CivicTokens.spaceMd),
              membersAsync.when(
                loading: () => const LoadingStateView(
                  message: 'Memuat daftar anggota wilayah...',
                ),
                error: (error, _) => ErrorStateView.fromFailure(
                  AppFailure.fromException(error),
                  onRetry: () => ref.invalidate(siteMembersProvider(site.id)),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return const EmptyStateView(
                      title: 'Belum ada anggota lain',
                      description:
                          'Bagikan kode undangan wilayah agar petugas patroli dan warga dapat bergabung.',
                      icon: Icons.group_add_outlined,
                    );
                  }
                  return Column(
                    children: [
                      for (final detail in members) ...[
                        SiteMemberManagementCard(
                          detail: detail,
                          isSelf: detail.membership.userId == currentUserId,
                          onApprove: () => _updateMember(
                            detail,
                            status: MembershipStatus.active,
                          ),
                          onReject: () => _removeMember(detail),
                          onChangeRole: (role) =>
                              _updateMember(detail, role: role),
                          onToggleSuspend: () => _updateMember(
                            detail,
                            status:
                                detail.membership.status ==
                                    MembershipStatus.suspended
                                ? MembershipStatus.active
                                : MembershipStatus.suspended,
                          ),
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: CivicTokens.spaceLg),
              const ThemeModeSelectorCard(),
              const SizedBox(height: CivicTokens.spaceLg),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.onboarding),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ganti Wilayah'),
              ),
              const SizedBox(height: CivicTokens.spaceSm),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authActionControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
