import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // Jangan biarkan error startup (key salah, anonymous sign-in mati, tanpa
  // internet) membuat layar putih: tampilkan pesannya di layar.
  String? startupError;
  try {
    await SupabaseService.initialize();
  } catch (e) {
    startupError = e.toString();
  }
  runApp(SensorLogApp(startupError: startupError));
}
