import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronda_app/app.dart';
import 'package:ronda_app/core/config/env.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppFailure? startupFailure;
  if (Env.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
    } catch (error, stackTrace) {
      startupFailure = AppFailure.fromException(error, stackTrace);
    }
  } else {
    startupFailure = const ConfigurationFailure(
      message:
          'Konfigurasi SUPABASE_URL dan SUPABASE_ANON_KEY belum diatur melalui --dart-define-from-file=.env.local.',
      code: 'ENV_MISSING',
    );
  }

  runApp(
    ProviderScope(
      child: RondaApp(startupFailure: startupFailure),
    ),
  );
}
