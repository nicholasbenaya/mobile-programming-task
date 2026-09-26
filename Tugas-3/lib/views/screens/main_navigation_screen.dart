import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pahlawan_controller.dart';
import '../../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'hero_list_screen.dart';
import 'hero_gallery_screen.dart';
import 'hero_quiz_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Widget>? _screens;

  List<Widget> get _cachedScreens => _screens ??= [
        DashboardScreen(onNavigateTab: _onSelectTab),
        const HeroListScreen(),
        const HeroGalleryScreen(),
        const HeroQuizScreen(),
      ];

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PahlawanController>();

    // 1) Tampilkan loading selama data diambil dari API Supabase
    if (controller.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: AppTheme.primaryRed, size: 48),
              SizedBox(height: 12),
              Text(
                'Pahlawan Nasional',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: AppTheme.primaryRed),
              SizedBox(height: 12),
              Text('Mengambil data dari server...'),
            ],
          ),
        ),
      );
    }

    // 2) Tampilkan pesan error + tombol coba lagi jika server tidak bisa dihubungi
    if (controller.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.primaryRed, size: 48),
                const SizedBox(height: 12),
                Text(controller.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.loadData(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3) Data siap -> tampilkan aplikasi seperti biasa
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _cachedScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onSelectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryRed),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_rounded),
            selectedIcon: Icon(Icons.format_list_bulleted_rounded, color: AppTheme.primaryRed),
            label: 'Daftar',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded, color: AppTheme.primaryRed),
            label: 'Galeri',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded, color: AppTheme.primaryRed),
            label: 'Kuis',
          ),
        ],
      ),
    );
  }
}
