class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xhxrntuzbhlrbvhjccsn.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_HBGWHlVRHOX1DG8XV-MZYw_wWBLfcey',
  );

  static bool get isNotConfigured =>
      url.contains('ISI-PROJECT-ID') || publishableKey.startsWith('ISI-');
}
