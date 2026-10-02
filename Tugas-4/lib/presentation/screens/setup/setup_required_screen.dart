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
          message: 'Jalankan dengan --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=... (lihat README).',
        ),
      ),
    );
  }
}
