import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Pintu masuk ke Supabase (API + database online).
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Dipanggil sekali di main() sebelum runApp().
  static Future<void> initialize() async {
    if (SupabaseConfig.isNotConfigured) {
      throw StateError(
        'URL / key Supabase belum diisi.\n'
        'Buka lib/config/supabase_config.dart lalu isi dengan data project kamu.',
      );
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publishableKey,
    );
  }

  /// Memastikan pengguna punya "akun tamu" (anonymous sign-in) agar
  /// favoritnya tersimpan di server & terpisah dari pengguna lain.
  /// Sesi disimpan otomatis, jadi pengguna yang sama tetap dikenali
  /// walaupun aplikasi ditutup lalu dibuka lagi.
  static Future<String> ensureSignedIn() async {
    final auth = client.auth;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    return auth.currentUser!.id;
  }
}
