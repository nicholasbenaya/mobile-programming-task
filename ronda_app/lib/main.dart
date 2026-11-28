import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      child: RondaBootstrapApp(startupFailure: startupFailure),
    ),
  );
}

/// Minimal entrypoint shell replaced by Front End `RondaApp` in P1-T03.
class RondaBootstrapApp extends StatelessWidget {
  const RondaBootstrapApp({super.key, this.startupFailure});

  final AppFailure? startupFailure;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RondaDigital',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'RondaDigital',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    startupFailure?.message ??
                        'Konfigurasi backend siap. Antarmuka aplikasi sedang dirakit.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
