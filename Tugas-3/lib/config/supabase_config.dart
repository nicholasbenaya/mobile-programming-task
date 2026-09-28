class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fuwlkofuuqpctwturjdr.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_5iBDF4E8leLJiqsBscn5mQ_aXFUxTBw',
  );

  static bool get isNotConfigured =>
      url.contains('ISI-PROJECT-ID') || publishableKey.startsWith('ISI-');
}
