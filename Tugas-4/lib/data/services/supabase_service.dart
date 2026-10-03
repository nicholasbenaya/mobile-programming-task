import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// Inisialisasi Supabase. Login ditangani oleh AuthRepository.
class SupabaseService {
  const SupabaseService._();

  static Future<void> initialize() async {
    if (!Env.isConfigured) return;
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
