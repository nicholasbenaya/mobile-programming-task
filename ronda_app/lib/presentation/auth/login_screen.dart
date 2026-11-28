import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/presentation/auth/theme_mode_selector.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Email and password sign-in screen with daytime/night-shift theme toggle.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _errorMessage = null);
    final ok = await ref
        .read(authActionControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted || ok) {
      return;
    }

    final actionState = ref.read(authActionControllerProvider);
    final error = actionState.asError?.error;
    final failure = error != null
        ? AppFailure.fromException(error)
        : const AuthFailure(message: 'Gagal masuk. Periksa akun Anda.');
    setState(() => _errorMessage = failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final isSubmitting = ref.watch(authActionControllerProvider).isLoading;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              CivicTokens.spaceLg,
              CivicTokens.spaceSection,
              CivicTokens.spaceLg,
              CivicTokens.spaceSection + bottomInset,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tokens.brandPrimary,
                          borderRadius: BorderRadius.circular(
                            CivicTokens.radiusControl,
                          ),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 22,
                          color: tokens.onBrandPrimary,
                        ),
                      ),
                      const SizedBox(width: CivicTokens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RondaDigital',
                              style: textTheme.headlineMedium,
                            ),
                            Text(
                              'Patroli & Keamanan Lingkungan Multi-Wilayah',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CivicTokens.spaceLg),
                  const ThemeModeSelector(showIcons: false),
                  const SizedBox(height: CivicTokens.spaceSection),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(CivicTokens.spaceXl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Masuk ke Akun', style: textTheme.titleLarge),
                            const SizedBox(height: CivicTokens.spaceXs),
                            Text(
                              'Gunakan email dan kata sandi terdaftar untuk mengakses wilayah patroli.',
                              style: textTheme.bodyMedium,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: CivicTokens.spaceMd),
                              _InlineErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: CivicTokens.spaceLg),
                            TextFormField(
                              controller: _emailController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'nama@email.com',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Email wajib diisi.';
                                }
                                if (!text.contains('@') || !text.contains('.')) {
                                  return 'Masukkan alamat email yang valid.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: CivicTokens.spaceMd),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !isSubmitting,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Kata Sandi',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Tampilkan kata sandi'
                                      : 'Sembunyikan kata sandi',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Kata sandi wajib diisi.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: CivicTokens.spaceXl),
                            FilledButton(
                              onPressed: isSubmitting ? null : _submit,
                              child: isSubmitting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: tokens.onBrandPrimary,
                                      ),
                                    )
                                  : const Text('Masuk'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CivicTokens.spaceLg),
                  OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => context.go(AppRoutes.register),
                    child: const Text('Daftar Akun Baru'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.statusEmergencyTint,
        borderRadius: BorderRadius.circular(CivicTokens.radiusControl),
        border: Border.all(
          color: tokens.statusEmergencyText.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CivicTokens.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: tokens.statusEmergencyText,
            ),
            const SizedBox(width: CivicTokens.spaceSm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.statusEmergencyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
