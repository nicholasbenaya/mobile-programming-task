import 'secrets.dart';

/// Akses konfigurasi aplikasi. Nilai sebenarnya ada di secrets.dart.
class Env {
  const Env._();

  /// URL dibersihkan otomatis: spasi, garis miring di akhir, dan path
  /// tambahan (mis. /rest/v1) dibuang supaya hanya https://<ref>.supabase.co.
  static String get supabaseUrl {
    final raw = Secrets.supabaseUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return raw;
    return '${uri.scheme}://${uri.authority}';
  }

  static String get supabaseAnonKey => Secrets.supabaseAnonKey.trim();

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.startsWith('ISI_');
}
