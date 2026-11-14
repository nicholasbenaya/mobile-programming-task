import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_digital/app.dart';

void main() {
  testWidgets('Test alur autentikasi dan rendering semua role tanpa bug UI/layout', (tester) async {
    await tester.pumpWidget(const RondaDigitalApp());
    await tester.pumpAndSettle();

    // 1. Uji Login Sebagai Petugas Ronda (Jordi)
    final jordiChip = find.textContaining('Jordi');
    await tester.ensureVisible(jordiChip);
    await tester.tap(jordiChip);
    await tester.pumpAndSettle();

    final loginBtn = find.text('Masuk ke Sistem Keamanan');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Verifikasi berada di PetugasRondaDashboard
    expect(find.textContaining('Online - RT 04'), findsOneWidget);
    expect(find.text('Pos Checkpoint Fisik (Patroli QR)'), findsOneWidget);

    // Logout petugas
    final logoutBtn = find.byTooltip('Keluar Akun');
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();
    final confirmLogout = find.widgetWithText(FilledButton, 'Keluar');
    await tester.tap(confirmLogout);
    await tester.pumpAndSettle();

    // 2. Uji Login Sebagai Ketua RT (Nicholas Benaya)
    final rtChip = find.textContaining('Nicholas');
    await tester.ensureVisible(rtChip);
    await tester.tap(rtChip);
    await tester.pumpAndSettle();

    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Verifikasi berada di AdminRtDashboard
    expect(find.text('Pusat Komando & Log RT'), findsOneWidget);
    expect(find.textContaining('Petugas Berjaga Hari Ini'), findsOneWidget);

    // Logout Ketua RT
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmLogout);
    await tester.pumpAndSettle();

    // 3. Uji Login Sebagai Warga (Fito)
    final wargaChip = find.textContaining('Fito');
    await tester.ensureVisible(wargaChip);
    await tester.tap(wargaChip);
    await tester.pumpAndSettle();

    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Verifikasi berada di WargaDashboard
    expect(find.textContaining('Tombol Panik'), findsOneWidget);
    expect(find.textContaining('Kalender & Roster Jadwal Ronda'), findsOneWidget);
  });
}
