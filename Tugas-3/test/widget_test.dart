import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pahlawan_nasional/main.dart';

void main() {
  testWidgets('PahlawanNasionalApp smoke test', (WidgetTester tester) async {
    // Di lingkungan test tidak ada koneksi Supabase, jadi cukup pastikan
    // aplikasi bisa dibangun dan menampilkan layar (loading / error).
    await tester.pumpWidget(
      const PahlawanNasionalApp(startupError: 'Mode test: tanpa server'),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
