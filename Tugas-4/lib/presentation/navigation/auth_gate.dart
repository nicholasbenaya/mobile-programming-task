import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../screens/auth/auth_screen.dart';
import 'main_shell.dart';

/// Penjaga pintu: belum masuk -> layar login/daftar, sudah masuk -> aplikasi.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: loggedIn ? const MainShell(key: ValueKey('main')) : const AuthScreen(key: ValueKey('auth')),
    );
  }
}
