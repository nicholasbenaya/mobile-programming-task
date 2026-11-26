import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'domain/ronda/models/ronda_models.dart';
import 'presentation/screens/auth/ronda_login_screen.dart';
import 'presentation/screens/ronda/admin_rt_dashboard.dart';
import 'presentation/screens/ronda/petugas_ronda_dashboard.dart';
import 'presentation/screens/ronda/warga_dashboard.dart';
import 'presentation/navigation/app_scroll_behavior.dart';
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
        scrollBehavior: const AppScrollBehavior(),
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

    // Keep MaterialApp/Navigator stable while the login screen is replaced.
    // This avoids tearing down the focused login subtree in the same frame as
    // provider notifications (notably while Android is dismissing the keyboard).
    final Widget screen;
    final Key screenKey;
    if (user == null) {
      screen = const RondaLoginScreen();
      screenKey = const ValueKey('ronda-login');
    } else {
      screenKey = ValueKey('ronda-${user.role.name}');
      switch (user.role) {
        case UserRole.adminRt:
          screen = const AdminRtDashboard();
        case UserRole.petugasRonda:
          screen = const PetugasRondaDashboard();
        case UserRole.warga:
          screen = const WargaDashboard();
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: screenKey, child: screen),
    );
  }
}
