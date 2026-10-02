import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Ditampilkan jika SUPABASE_URL / SUPABASE_ANON_KEY belum diberikan.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.settings_suggest_rounded,
          title: 'Supabase belum dikonfigurasi',
          message: 'Isi supabaseUrl dan supabaseAnonKey di lib/core/config/secrets.dart, lalu jalankan ulang aplikasi.',
        ),
      ),
    );
  }
}
