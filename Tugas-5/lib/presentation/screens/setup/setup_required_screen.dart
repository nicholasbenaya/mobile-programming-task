import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Ditampilkan jika SUPABASE_URL / SUPABASE_ANON_KEY belum diberikan.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key, this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.settings_suggest_rounded,
          title: title ?? 'Supabase belum dikonfigurasi',
          message: message ??
              'Isi supabaseUrl dan supabaseAnonKey di lib/core/config/secrets.dart, lalu jalankan ulang aplikasi.',
        ),
      ),
    );
  }
}
