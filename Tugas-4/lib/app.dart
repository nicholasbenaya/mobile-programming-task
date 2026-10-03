import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/env.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/record_repository.dart';
import 'data/services/export_service.dart';
import 'data/services/image_service.dart';
import 'data/services/location_service.dart';
import 'data/services/sensor_service.dart';
import 'data/services/supabase_service.dart';
import 'presentation/navigation/auth_gate.dart';
import 'presentation/screens/setup/setup_required_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/records_provider.dart';

class SensorLogApp extends StatelessWidget {
  const SensorLogApp({super.key, this.startupError});

  /// Pesan error jika inisialisasi Supabase gagal saat startup.
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    final ready = Env.isConfigured && startupError == null;
    final app = MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ready
          ? const AuthGate()
          : SetupRequiredScreen(
              title: startupError == null ? null : 'Gagal terhubung ke Supabase',
              message: startupError,
            ),
    );
    // Provider harus berada DI ATAS MaterialApp agar layar yang di-push
    // (Catat, Detail, Akun) tetap bisa mengaksesnya.
    return ready ? _AppScope(child: app) : app;
  }
}

/// Menyediakan service, repository, dan provider global.
class _AppScope extends StatelessWidget {
  const _AppScope({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => SensorService()),
        Provider(create: (_) => ImageService()),
        Provider(create: (_) => ExportService()),
        Provider(create: (_) => AuthRepository(SupabaseService.client)),
        Provider(create: (_) => RecordRepository(SupabaseService.client)),
        ChangeNotifierProvider(create: (c) => AuthProvider(c.read<AuthRepository>())),
        // Data catatan mengikuti akun yang sedang masuk (dikosongkan saat keluar/ganti akun).
        ChangeNotifierProxyProvider<AuthProvider, RecordsProvider>(
          create: (c) => RecordsProvider(c.read<RecordRepository>()),
          update: (_, auth, records) => records!..onUserChanged(auth.user?.id),
        ),
      ],
      child: child,
    );
  }
}
