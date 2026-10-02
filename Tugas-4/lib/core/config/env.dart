import 'secrets.dart';

/// Akses konfigurasi aplikasi. Nilai sebenarnya ada di secrets.dart.
class Env {
  const Env._();

  static const supabaseUrl = Secrets.supabaseUrl;
  static const supabaseAnonKey = Secrets.supabaseAnonKey;

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.startsWith('ISI_');
}
