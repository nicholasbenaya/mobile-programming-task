import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/presentation/auth/theme_mode_selector.dart';
import 'package:ronda_app/presentation/shared/status_badge.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Shared profile, unit address, theme toggle, site switcher, and sign-out panel for Officers and Residents.
class MemberProfilePanel extends ConsumerStatefulWidget {
  const MemberProfilePanel({
    super.key,
    required this.active,
    required this.allowUnitEdit,
  });

  final SiteMembershipWithSite active;
  final bool allowUnitEdit;

  @override
  ConsumerState<MemberProfilePanel> createState() => _MemberProfilePanelState();
}

class _MemberProfilePanelState extends ConsumerState<MemberProfilePanel> {
  late final TextEditingController _unitController;
  bool _isSavingUnit = false;

  @override
  void initState() {
    super.initState();
    _unitController = TextEditingController(
      text: widget.active.membership.unitAddress,
    );
  }

  @override
  void didUpdateWidget(covariant MemberProfilePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active.site.id != widget.active.site.id) {
      _unitController.text = widget.active.membership.unitAddress;
    }
  }

  @override
  void dispose() {
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveUnitAddress() async {
    setState(() => _isSavingUnit = true);
    try {
      await ref
          .read(mySitesProvider.notifier)
          .updateMyUnitAddress(
            siteId: widget.active.site.id,
            unitAddress: _unitController.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat unit berhasil diperbarui.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppFailure.fromException(error).message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingUnit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(authSessionProvider).asData?.value;
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
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(CivicTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identitas & Wilayah Aktif',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: CivicTokens.spaceSm),
                      Text(
                        profileAsync.asData?.value?.fullName ??
                            user?.email ??
                            'Pengguna RondaDigital',
                        style: textTheme.titleMedium,
                      ),
                      if (user != null)
                        Text(user.email, style: textTheme.bodyMedium),
                      if (profileAsync.asData?.value != null)
                        Text(
                          'WhatsApp: ${profileAsync.asData!.value!.phoneWhatsapp}',
                          style: textTheme.bodyMedium,
                        ),
                      const SizedBox(height: CivicTokens.spaceMd),
                      Wrap(
                        spacing: CivicTokens.spaceSm,
                        runSpacing: CivicTokens.spaceSm,
                        children: [
                          StatusBadge.custom(
                            label: widget.active.membership.role.labelId,
                            icon: Icons.verified_user_outlined,
                            tone: StatusTone.verified,
                            compact: true,
                          ),
                          StatusBadge.custom(
                            label: widget.active.site.name,
                            icon: Icons.location_city_outlined,
                            tone: StatusTone.offline,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.allowUnitEdit) ...[
                const SizedBox(height: CivicTokens.spaceLg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(CivicTokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Alamat Unit / Rumah',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: CivicTokens.spaceSm),
                        TextField(
                          controller: _unitController,
                          enabled: !_isSavingUnit,
                          decoration: const InputDecoration(
                            labelText: 'Blok / Nomor Rumah',
                            hintText: 'Contoh: Blok C No. 08',
                          ),
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                        FilledButton(
                          onPressed: _isSavingUnit ? null : _saveUnitAddress,
                          child: const Text('Simpan Alamat Unit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: CivicTokens.spaceLg),
              const ThemeModeSelectorCard(),
              const SizedBox(height: CivicTokens.spaceLg),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.onboarding),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ganti atau Gabung Wilayah'),
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
