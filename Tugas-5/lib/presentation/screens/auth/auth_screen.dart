import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/motion/fade_in_slide.dart';
import '../../widgets/motion/loading_button.dart';
import 'widgets/auth_banner.dart';
import 'widgets/auth_header.dart';
import 'widgets/google_button.dart';

/// Satu layar untuk Masuk dan Daftar (tab di atas form).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _googleLoading = false;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setMode(bool login) {
    context.read<AuthProvider>().clearError();
    setState(() {
      _isLogin = login;
      _info = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    if (_isLogin) {
      await auth.signIn(email: _email.text, password: _password.text);
      return; // jika berhasil, AuthGate otomatis pindah ke aplikasi
    }

    final outcome = await auth.signUp(name: _name.text, email: _email.text, password: _password.text);
    if (!mounted) return;
    if (outcome == SignUpOutcome.needsEmailConfirmation) {
      setState(() {
        _isLogin = true;
        _info = 'Akun dibuat! Kami mengirim tautan verifikasi ke ${_email.text.trim()}. '
            'Verifikasi dulu, lalu masuk.';
      });
      _password.clear();
      _confirm.clear();
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleLoading = true);
    await context.read<AuthProvider>().signInWithGoogle();
    if (mounted) setState(() => _googleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthHeader(
                        subtitle: _isLogin
                            ? 'Masuk untuk melanjutkan catatan lapangan Anda.'
                            : 'Buat akun untuk mulai mencatat temuan lapangan.',
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: true, label: Text('Masuk'), icon: Icon(Icons.login_rounded)),
                          ButtonSegment(value: false, label: Text('Daftar'), icon: Icon(Icons.person_add_alt_1_rounded)),
                        ],
                        selected: {_isLogin},
                        onSelectionChanged: auth.loading ? null : (s) => _setMode(s.first),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [
                            if (_info != null) ...[
                              FadeInSlide(
                                key: ValueKey(_info),
                                offset: const Offset(0, -8),
                                child: AuthBanner(icon: Icons.mark_email_read_rounded, message: _info!, color: scheme.primary),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (auth.error != null) ...[
                              FadeInSlide(
                                key: ValueKey(auth.error),
                                offset: const Offset(0, -8),
                                child: AuthBanner(icon: Icons.error_outline_rounded, message: auth.error!, color: scheme.error),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: _isLogin
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: TextFormField(
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: Validators.fullName,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama lengkap',
                                    prefixIcon: Icon(Icons.person_rounded),
                                  ),
                                ),
                              ),
                      ),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_rounded)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                        autofillHints: [_isLogin ? AutofillHints.password : AutofillHints.newPassword],
                        validator: Validators.password,
                        onFieldSubmitted: (_) => _isLogin ? _submit() : null,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                              child: Icon(
                                _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                key: ValueKey(_obscure),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: _isLogin
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: TextFormField(
                                  controller: _confirm,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.newPassword],
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) => v != _password.text ? 'Password tidak sama' : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Konfirmasi password',
                                    prefixIcon: Icon(Icons.lock_reset_rounded),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 22),
                      LoadingButton(
                        loading: auth.loading && !_googleLoading,
                        onPressed: auth.loading ? null : _submit,
                        label: _isLogin ? 'Masuk' : 'Buat akun',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau', style: text.bodySmall?.copyWith(color: scheme.outline)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GoogleButton(
                        enabled: !auth.loading || _googleLoading,
                        loading: _googleLoading,
                        onPressed: _google,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 14, color: scheme.outline),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Catatan dan foto Anda hanya bisa diakses oleh akun Anda.',
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(color: scheme.outline),
                            ),
                          ),
                        ],
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
