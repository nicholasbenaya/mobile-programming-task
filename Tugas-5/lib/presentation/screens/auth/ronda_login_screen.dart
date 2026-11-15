import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/mock/seed_data.dart';
import '../../../domain/ronda/models/ronda_models.dart';
import '../../../providers/ronda_provider.dart';

/// Layar Masuk / Login Resmi & Terenkripsi untuk Ekosistem Ronda Digital
class RondaLoginScreen extends StatefulWidget {
  const RondaLoginScreen({super.key});

  @override
  State<RondaLoginScreen> createState() => _RondaLoginScreenState();
}

class _RondaLoginScreenState extends State<RondaLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _whatsappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _autofillCredentials(RondaUser user) {
    setState(() {
      _whatsappController.text = user.nomorWhatsapp;
      _passwordController.text = SeedData.defaultDemoPassword;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kredensial ${user.namaLengkap} (${user.role.label}) dimuat.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final ronda = context.read<RondaProvider>();

    final success = await ronda.login(
      whatsapp: _whatsappController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success && ronda.lastErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(ronda.lastErrorMessage!)),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ronda = context.watch<RondaProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Logo & Identitas Aplikasi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ronda Digital',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Siskamling Modern RT 04 / RW 02 Gebang Putih\nTeknik Komputer FTEIC ITS',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2. Banner Notifikasi Status jika ada
                    if (ronda.lastErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ronda.lastErrorMessage!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Form Input Nomor WhatsApp & Kata Sandi
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor WhatsApp Terdaftar',
                        hintText: 'Contoh: 081234567802',
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor WhatsApp wajib diisi';
                        }
                        if (value.trim().length < 8) {
                          return 'Nomor tidak valid (minimal 8 digit)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi (Terenkripsi SHA-256)',
                        hintText: 'Masukkan kata sandi akun',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 4. Tombol Masuk
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _handleLogin,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          _isLoading ? 'Memverifikasi...' : 'Masuk ke Sistem Keamanan',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 5. Akun Uji Coba Demo Penguji (Memudahkan Penguji Tanpa Mengorbankan Enkripsi)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.badge_outlined, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Pilihan Akun Demo (Klik untuk Autofill)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilih profil di bawah untuk mengisi kredensial secara otomatis, lalu tekan tombol Masuk:',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ronda.availableUsers.map((user) {
                                final isKetua = user.role == UserRole.adminRt;
                                final isPetugas = user.role == UserRole.petugasRonda;

                                Color chipColor;
                                if (isKetua) {
                                  chipColor = Colors.purple.shade700;
                                } else if (isPetugas) {
                                  chipColor = Colors.blue.shade700;
                                } else {
                                  chipColor = Colors.teal.shade700;
                                }

                                return ActionChip(
                                  avatar: CircleAvatar(
                                    backgroundColor: chipColor,
                                    child: Text(
                                      user.namaLengkap[0],
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                  label: Text(
                                    '${user.namaLengkap.split(' ').first} (${user.role.label})',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () => _autofillCredentials(user),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Kata sandi default: password123',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
