import 'package:ronda_app/core/errors/app_failure.dart';

/// Compile-time runtime environment values supplied via `--dart-define`
/// or `--dart-define-from-file=.env.local`.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Android high-importance notification channel ID used by SOS FCM alarms.
  static const String sosNotificationChannelId = 'rondadigital_sos_alarm';

  static bool get isSupabaseConfigured => isValidSupabaseConfig(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

  /// Validates that [url] is an HTTP(S) URI with a host and [anonKey] is non-empty.
  static bool isValidSupabaseConfig({
    required String url,
    required String anonKey,
  }) {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();
    if (trimmedUrl.isEmpty || trimmedKey.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return false;
    }

    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  /// Throws [ConfigurationFailure] when required Supabase dart-defines are missing or invalid.
  static void ensureSupabaseConfigured({
    String url = supabaseUrl,
    String anonKey = supabaseAnonKey,
  }) {
    final missing = <String>[];
    if (url.trim().isEmpty) {
      missing.add('SUPABASE_URL');
    }
    if (anonKey.trim().isEmpty) {
      missing.add('SUPABASE_ANON_KEY');
    }

    if (missing.isNotEmpty) {
      throw ConfigurationFailure(
        message:
            'Konfigurasi ${missing.join(', ')} belum diatur. Jalankan aplikasi dengan --dart-define-from-file=.env.local.',
        code: 'ENV_MISSING',
      );
    }

    if (!isValidSupabaseConfig(url: url, anonKey: anonKey)) {
      throw const ConfigurationFailure(
        message:
            'Nilai SUPABASE_URL tidak valid. Pastikan menggunakan URL lengkap diawali https://.',
        code: 'ENV_INVALID_URL',
      );
    }
  }
}
