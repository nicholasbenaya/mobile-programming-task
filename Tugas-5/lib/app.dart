import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'domain/ronda/models/ronda_models.dart';
import 'presentation/screens/auth/ronda_login_screen.dart';
import 'presentation/screens/ronda/admin_rt_dashboard.dart';
import 'presentation/screens/ronda/petugas_ronda_dashboard.dart';
import 'presentation/screens/ronda/warga_dashboard.dart';
import 'providers/ronda_provider.dart';

class RondaDigitalApp extends StatelessWidget {
  const RondaDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RondaProvider(),
      child: MaterialApp(
        title: 'Ronda Digital - Siskamling Modern',
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
        home: const _RoleRouterGate(),
      ),
    );
  }
}

/// Gate Pengarah Antarmuka Berdasarkan Status Autentikasi dan Peran (RBAC)
class _RoleRouterGate extends StatelessWidget {
  const _RoleRouterGate();

  @override
  Widget build(BuildContext context) {
    final ronda = context.watch<RondaProvider>();
    final user = ronda.currentUser;

    // 1. Jika belum login, tampilkan layar masuk resmi terenkripsi
    if (user == null) {
      return const RondaLoginScreen();
    }

    // 2. Jika sudah terautentikasi, alihkan ke tampilan utama yang disesuaikan per peran
    switch (user.role) {
      case UserRole.adminRt:
        return const AdminRtDashboard();
      case UserRole.petugasRonda:
        return const PetugasRondaDashboard();
      case UserRole.warga:
        return const WargaDashboard();
    }
  }
}
