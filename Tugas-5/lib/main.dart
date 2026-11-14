import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/services/supabase_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Di mode release, error tampilan biasanya hanya jadi kotak abu-abu/kosong.
    // Tampilkan pesannya agar penyebabnya terlihat di layar.
    if (kReleaseMode) {
      ErrorWidget.builder = (details) => _ErrorBox(details.exceptionAsString());
    }

    await initializeDateFormatting('id_ID');

    // Error startup (key salah, tanpa internet, izin INTERNET hilang) tidak boleh
    // membuat layar kosong: tampilkan pesannya di layar.
    String? startupError;
    try {
      await SupabaseService.initialize().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      startupError = 'Koneksi ke Supabase terlalu lama. Periksa internet dan pastikan izin '
          'INTERNET ada di android/app/src/main/AndroidManifest.xml.';
    } catch (e) {
      startupError = e.toString();
    }
    runApp(SensorLogApp(startupError: startupError));
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFFFF3F0),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Terjadi kesalahan tampilan:\n\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
