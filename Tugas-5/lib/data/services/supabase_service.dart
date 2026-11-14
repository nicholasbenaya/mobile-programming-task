import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// Inisialisasi dan akses Supabase Client untuk Ronda Digital
class SupabaseService {
  const SupabaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!Env.isConfigured) return;
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: Env.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('Supabase connected successfully to: ${Env.supabaseUrl}');
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
      _initialized = false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static SupabaseClient? get clientOrNull {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
