import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';

class MainMenuScreen extends StatelessWidget {
  void _showExitConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Keluar Aplikasi'),
      content: const Text('Apakah kamu yakin ingin keluar?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(), // tutup dialog
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(); 
            SystemNavigator.pop(); 
          },
          child: const Text('Ya, Keluar'),
        ),
      ],
    ),
  );
}
  const MainMenuScreen({super.key});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background full-screen dari game pack
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_main_menu.png'),
            fit: BoxFit.cover, 
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Image.asset(
                  'assets/images/logo.png',
                  height: 350,
                  fit: BoxFit.contain, // menjaga rasio gambar, tidak melar
                  ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Image.asset(
                    'assets/images/PLAY.png',
                    height: 64,
                  ),
                ),
                const SizedBox(height: 36),
                InkWell(
                  onTap: () {
                    _showExitConfirmation(context);
                  },
                  child: Image.asset(
                    'assets/images/Exit.png',
                    height: 64,
                    ),
                    ),
                  
                const SizedBox(height: 107),
              ],
            ),
          ),
        ),
      ),
    );
  }
}