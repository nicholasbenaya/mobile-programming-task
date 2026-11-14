import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/services/supabase_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID');

    // Inisialisasi koneksi cloud Supabase (jika secrets telah dikonfigurasi)
    try {
      await SupabaseService.initialize();
    } catch (e) {
      debugPrint('Supabase init warning: $e');
    }

    runApp(const RondaDigitalApp());
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
