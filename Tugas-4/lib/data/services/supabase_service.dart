import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// Inisialisasi Supabase + login anonim (tiap perangkat punya data sendiri).
class SupabaseService {
  const SupabaseService._();

  static Future<void> initialize() async {
    if (!Env.isConfigured) return;
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
