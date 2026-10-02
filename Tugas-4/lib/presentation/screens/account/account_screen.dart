import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/records_provider.dart';
import '../../widgets/user_avatar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk melihat catatan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Tutup semua layar yang terbuka dulu, baru keluar; AuthGate akan menampilkan layar login.
    navigator.popUntil((route) => route.isFirst);
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final total = context.select<RecordsProvider, int>((p) => p.records.length);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final joined = auth.joinedAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  UserAvatar(name: auth.displayName, imageUrl: auth.avatarUrl, radius: 44),
                  const SizedBox(height: 14),
                  Text(auth.displayName, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(auth.email, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(auth.providerLabel == 'Google' ? Icons.g_mobiledata_rounded : Icons.mail_rounded),
                  title: const Text('Metode masuk'),
                  trailing: Text(auth.providerLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('Bergabung sejak'),
                  trailing: Text(joined == null ? '—' : Formatters.shortDate(joined), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_rounded),
                  title: const Text('Total catatan'),
                  trailing: Text('$total', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Catatan dan foto Anda tersimpan privat. Hanya akun ini yang dapat melihat, mengubah, dan menghapusnya.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              foregroundColor: scheme.error,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
