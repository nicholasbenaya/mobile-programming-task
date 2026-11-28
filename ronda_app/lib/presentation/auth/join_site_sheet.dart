import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Bottom sheet allowing a user to join an existing site using an 8-character invite code.
class JoinSiteSheet extends ConsumerStatefulWidget {
  const JoinSiteSheet({super.key});

  @override
  ConsumerState<JoinSiteSheet> createState() => _JoinSiteSheetState();
}

class _JoinSiteSheetState extends ConsumerState<JoinSiteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _unitController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final membership = await ref
          .read(mySitesProvider.notifier)
          .joinSiteByCode(
            inviteCode: _codeController.text,
            unitAddress: _unitController.text,
          );
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      if (membership.isActive) {
        context.go(AppRoutes.homeForRole(membership.role));
      } else {
        context.go(AppRoutes.pendingApproval);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppFailure.fromException(error).message;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        CivicTokens.spaceLg,
        CivicTokens.spaceLg,
        CivicTokens.spaceLg,
        CivicTokens.spaceSection + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gabung Pakai Kode Undangan',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: CivicTokens.spaceXs),
              Text(
                'Masukkan kode undangan 8 karakter yang dibagikan oleh Admin Wilayah.',
                style: textTheme.bodyMedium,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: CivicTokens.spaceMd),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.statusEmergencyTint,
                    borderRadius: BorderRadius.circular(
                      CivicTokens.radiusControl,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CivicTokens.spaceMd),
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.statusEmergencyText,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: CivicTokens.spaceLg),
              TextFormField(
                controller: _codeController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                style: tokens.forensicMono.copyWith(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Kode Undangan',
                  hintText: 'Contoh: RD8K2M9A',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                validator: (value) {
                  final cleaned = (value ?? '').trim();
                  if (cleaned.length < 6) {
                    return 'Masukkan kode undangan wilayah yang valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: CivicTokens.spaceMd),
              TextFormField(
                controller: _unitController,
                enabled: !_isSubmitting,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Alamat Unit / Blok (Opsional)',
                  hintText: 'Contoh: Blok B No. 12',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: CivicTokens.spaceXl),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: tokens.onBrandPrimary,
                        ),
                      )
                    : const Text('Ajukan Bergabung'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
