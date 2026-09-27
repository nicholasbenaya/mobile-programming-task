import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/pahlawan_controller.dart';
import 'services/supabase_service.dart';
import 'utils/app_theme.dart';
import 'views/screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Memperbesar kapasitas image cache bawaan Flutter untuk seluruh sesi
  PaintingBinding.instance.imageCache.maximumSize = 2500;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20; // 250 MB

  String? startupError;
  try {
    await SupabaseService.initialize();
  } catch (e) {
    startupError = e.toString();
  }

  runApp(PahlawanNasionalApp(startupError: startupError));
}

class PahlawanNasionalApp extends StatelessWidget {
  final String? startupError;

  const PahlawanNasionalApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PahlawanController(startupError: startupError)..loadData(),
      child: MaterialApp(
        title: 'Informasi Pahlawan Nasional',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
