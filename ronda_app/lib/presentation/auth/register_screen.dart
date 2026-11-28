import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Account registration screen collecting full name, WhatsApp number, email, and password.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
        .signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          phoneWhatsapp: _phoneController.text,
        );

    if (!mounted || ok) {
      return;
    }

    final error = ref.read(authActionControllerProvider).asError?.error;
    final failure = error != null
        ? AppFailure.fromException(error)
        : const AuthFailure(message: 'Pendaftaran gagal. Silakan coba lagi.');
    setState(() => _errorMessage = failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final isSubmitting = ref.watch(authActionControllerProvider).isLoading;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        leading: IconButton(
          tooltip: 'Kembali ke halaman masuk',
          onPressed: isSubmitting ? null : () => context.go(AppRoutes.login),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              CivicTokens.spaceLg,
              CivicTokens.spaceLg,
              CivicTokens.spaceLg,
              CivicTokens.spaceSection + bottomInset,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(CivicTokens.spaceXl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Identitas Pengguna', style: textTheme.titleLarge),
                        const SizedBox(height: CivicTokens.spaceXs),
                        Text(
                          'Satu akun dapat digunakan untuk membuat wilayah baru atau bergabung ke beberapa wilayah.',
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
                              border: Border.all(
                                color: tokens.statusEmergencyText.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                CivicTokens.spaceMd,
                              ),
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
                          controller: _nameController,
                          enabled: !isSubmitting,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'Nama sesuai identitas wilayah',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length < 2) {
                              return 'Nama lengkap minimal 2 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp',
                            hintText: '08xxxxxxxxxx',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final digits = (value ?? '').replaceAll(
                              RegExp(r'[^0-9+]'),
                              '',
                            );
                            if (digits.length < 9) {
                              return 'Masukkan nomor WhatsApp yang aktif.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'nama@email.com',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            final text = (value ?? '').trim();
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
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi',
                            helperText: 'Minimal 6 karakter',
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
                            if ((value ?? '').length < 6) {
                              return 'Kata sandi minimal 6 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                        TextFormField(
                          controller: _confirmController,
                          enabled: !isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Konfirmasi kata sandi tidak cocok.';
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
                              : const Text('Buat Akun'),
                        ),
                        const SizedBox(height: CivicTokens.spaceMd),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => context.go(AppRoutes.login),
                          child: const Text('Sudah punya akun? Masuk'),
                        ),
                      ],
                    ),
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
