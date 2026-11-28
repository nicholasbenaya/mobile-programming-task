import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/app.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/theme/app_colors.dart';
import 'package:ronda_app/core/theme/app_theme.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/presentation/shared/forensic_strip.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';
import 'package:ronda_app/presentation/shared/status_badge.dart';

void main() {
  Future<void> setNarrowPhoneSurface(
    WidgetTester tester, {
    double width = 360,
    double height = 640,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrapInTheme({
    required ThemeData theme,
    required Widget child,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SafeArea(child: child)),
      ),
    );
  }

  group('Civic Operational theme tokens', () {
    test('Light Mode hex tokens match ronda_app/DESIGN.md exactly', () {
      final theme = AppTheme.light();
      final tokens = theme.extension<CivicTokens>()!;

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F6F8));
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.onSurface, const Color(0xFF0F172A));
      expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF475569));
      expect(theme.colorScheme.primary, const Color(0xFF153243));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.secondary, const Color(0xFFB45309));
      expect(theme.colorScheme.outlineVariant, const Color(0xFFCBD5E1));
      expect(theme.colorScheme.outline, const Color(0xFF64748B));
      expect(theme.colorScheme.error, const Color(0xFFB91C1C));

      expect(tokens.canvas, const Color(0xFFF4F6F8));
      expect(tokens.surface, const Color(0xFFFFFFFF));
      expect(tokens.surfaceSubtle, const Color(0xFFE9EEF3));
      expect(tokens.inkPrimary, const Color(0xFF0F172A));
      expect(tokens.inkSecondary, const Color(0xFF475569));
      expect(tokens.brandPrimary, const Color(0xFF153243));
      expect(tokens.onBrandPrimary, const Color(0xFFFFFFFF));
      expect(tokens.accentOperational, const Color(0xFFB45309));
      expect(tokens.accentFill, const Color(0xFFF59E0B));
      expect(tokens.borderHairline, const Color(0xFFCBD5E1));
      expect(tokens.borderInteractive, const Color(0xFF64748B));
      expect(tokens.statusVerified, const Color(0xFF047857));
      expect(tokens.statusVerifiedTint, const Color(0xFFECFDF5));
      expect(tokens.statusFlagged, const Color(0xFF92400E));
      expect(tokens.statusFlaggedTint, const Color(0xFFFEF3C7));
      expect(tokens.statusEmergency, const Color(0xFFB91C1C));
      expect(tokens.statusEmergencyText, const Color(0xFF991B1B));
      expect(tokens.statusEmergencyTint, const Color(0xFFFEE2E2));
    });

    test('Dark Mode hex tokens match ronda_app/DESIGN.md exactly', () {
      final theme = AppTheme.dark();
      final tokens = theme.extension<CivicTokens>()!;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B111A));
      expect(theme.colorScheme.surface, const Color(0xFF131C2A));
      expect(theme.colorScheme.surfaceContainerHigh, const Color(0xFF1B273A));
      expect(theme.colorScheme.onSurface, const Color(0xFFF1F5F9));
      expect(theme.colorScheme.onSurfaceVariant, const Color(0xFFA3B3C6));
      expect(theme.colorScheme.primary, const Color(0xFF5FA8D3));
      expect(theme.colorScheme.onPrimary, const Color(0xFF0B111A));
      expect(theme.colorScheme.secondary, const Color(0xFFF59E0B));
      expect(theme.colorScheme.outlineVariant, const Color(0xFF263449));
      expect(theme.colorScheme.outline, const Color(0xFF6E829B));
      expect(theme.colorScheme.error, const Color(0xFFDC2626));

      expect(tokens.canvas, const Color(0xFF0B111A));
      expect(tokens.surface, const Color(0xFF131C2A));
      expect(tokens.surfaceElevated, const Color(0xFF1B273A));
      expect(tokens.inkPrimary, const Color(0xFFF1F5F9));
      expect(tokens.inkSecondary, const Color(0xFFA3B3C6));
      expect(tokens.brandPrimary, const Color(0xFF5FA8D3));
      expect(tokens.onBrandPrimary, const Color(0xFF0B111A));
      expect(tokens.accentOperational, const Color(0xFFF59E0B));
      expect(tokens.borderHairline, const Color(0xFF263449));
      expect(tokens.borderInteractive, const Color(0xFF6E829B));
      expect(tokens.statusVerified, const Color(0xFF34D399));
      expect(tokens.statusVerifiedTint, const Color(0xFF0B2E26));
      expect(tokens.statusFlagged, const Color(0xFFFBBF24));
      expect(tokens.statusFlaggedTint, const Color(0xFF332207));
      expect(tokens.statusEmergency, const Color(0xFFDC2626));
      expect(tokens.statusEmergencyText, const Color(0xFFFCA5A5));
      expect(tokens.statusEmergencyTint, const Color(0xFF3B1219));
    });

    test('Typography scale and bundled font families match DESIGN.md', () {
      final lightTheme = AppTheme.light();
      final textTheme = lightTheme.textTheme;
      final tokens = lightTheme.extension<CivicTokens>()!;

      expect(textTheme.headlineMedium?.fontFamily, AppTheme.sansFontFamily);
      expect(textTheme.headlineMedium?.fontSize, 22);
      expect(textTheme.headlineMedium?.fontWeight, FontWeight.w700);
      expect(textTheme.titleLarge?.fontSize, 18);
      expect(textTheme.titleMedium?.fontSize, 15);
      expect(textTheme.bodyLarge?.fontSize, 15);
      expect(textTheme.bodyMedium?.fontSize, 13.5);
      expect(textTheme.labelLarge?.fontSize, 14);
      expect(textTheme.labelSmall?.fontSize, 12);

      expect(tokens.forensicMono.fontFamily, AppTheme.monoFontFamily);
      expect(tokens.forensicMono.fontSize, 12.5);
      expect(tokens.forensicMono.fontWeight, FontWeight.w400);
    });

    test('CivicTokens supports copyWith and lerp smoothly', () {
      final copied = CivicTokens.light.copyWith(
        brandPrimary: AppColors.darkBrandPrimary,
      );
      expect(copied.brandPrimary, AppColors.darkBrandPrimary);
      expect(copied.canvas, CivicTokens.light.canvas);

      final mid = CivicTokens.light.lerp(CivicTokens.dark, 0.5);
      expect(
        mid.canvas,
        Color.lerp(CivicTokens.light.canvas, CivicTokens.dark.canvas, 0.5),
      );
      expect(CivicTokens.light.lerp(null, 0.5), same(CivicTokens.light));
    });
  });

  group('StatusBadge', () {
    for (final mode in <(String, ThemeData)>[
      ('Light', AppTheme.light()),
      ('Dark', AppTheme.dark()),
    ]) {
      testWidgets(
        'renders all operational statuses with icon and label in ${mode.$1} mode without overflow',
        (tester) async {
          await setNarrowPhoneSurface(tester);

          await tester.pumpWidget(
            wrapInTheme(
              theme: mode.$2,
              child: const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(status: OperationalStatus.autoVerified),
                    StatusBadge(status: OperationalStatus.manualApproved),
                    StatusBadge(status: OperationalStatus.flaggedReview),
                    StatusBadge(status: OperationalStatus.autoRejected),
                    StatusBadge(status: OperationalStatus.manualRejected),
                    StatusBadge(status: OperationalStatus.offlinePending),
                    StatusBadge.custom(
                      label: 'Diproses',
                      icon: Icons.build_circle_outlined,
                      tone: StatusTone.flagged,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Terverifikasi'), findsOneWidget);
          expect(find.text('Disetujui Admin'), findsOneWidget);
          expect(find.text('Perlu Tinjauan'), findsOneWidget);
          expect(find.text('Ditolak Otomatis'), findsOneWidget);
          expect(find.text('Ditolak Admin'), findsOneWidget);
          expect(find.text('Menunggu Sinkronisasi'), findsOneWidget);
          expect(find.text('Diproses'), findsOneWidget);

          // Every status badge pairs its label with a visible semantic icon.
          expect(find.byType(Icon), findsNWidgets(7));
          for (final status in OperationalStatus.values) {
            final badge = StatusBadge(status: status);
            expect(badge.label.contains('\u2014'), isFalse);
          }
        },
      );
    }

    testWidgets('holds at 200% text scaling on 360 dp phone width', (
      tester,
    ) async {
      await setNarrowPhoneSurface(tester);

      await tester.pumpWidget(
        wrapInTheme(
          theme: AppTheme.dark(),
          textScale: 2.0,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(status: OperationalStatus.offlinePending),
                SizedBox(height: 8),
                StatusBadge(status: OperationalStatus.flaggedReview),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Menunggu Sinkronisasi'), findsOneWidget);
    });
  });

  group('StateViews', () {
    for (final mode in <(String, ThemeData)>[
      ('Light', AppTheme.light()),
      ('Dark', AppTheme.dark()),
    ]) {
      testWidgets(
        'Loading, Empty, and Error views render and invoke real actions in ${mode.$1} mode',
        (tester) async {
          await setNarrowPhoneSurface(tester);
          var emptyActionCalls = 0;
          var retryCalls = 0;

          await tester.pumpWidget(
            wrapInTheme(
              theme: mode.$2,
              child: const LoadingStateView(
                message: 'Memuat jadwal patroli minggu ini...',
                detail: 'Mengambil data shift aktif wilayah.',
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(
            find.text('Memuat jadwal patroli minggu ini...'),
            findsOneWidget,
          );

          await tester.pumpWidget(
            wrapInTheme(
              theme: mode.$2,
              child: EmptyStateView(
                title: 'Belum ada titik patroli',
                description:
                    'Tambahkan pos pertama di peta untuk mencetak kode QR.',
                icon: Icons.add_location_alt_outlined,
                actionLabel: 'Tambah Pos Patroli',
                onAction: () => emptyActionCalls++,
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Tambah Pos Patroli'));
          await tester.pump();
          expect(emptyActionCalls, 1);

          await tester.pumpWidget(
            wrapInTheme(
              theme: mode.$2,
              child: ErrorStateView.fromFailure(
                const NetworkFailure(
                  message: 'Gagal memuat data wilayah karena koneksi terputus.',
                  code: 'NETWORK_OFFLINE',
                ),
                onRetry: () => retryCalls++,
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            find.text('Gagal memuat data wilayah karena koneksi terputus.'),
            findsOneWidget,
          );
          expect(find.text('KODE: NETWORK_OFFLINE'), findsOneWidget);

          final codeText = tester.widget<Text>(
            find.text('KODE: NETWORK_OFFLINE'),
          );
          expect(codeText.style?.fontFamily, AppTheme.monoFontFamily);

          await tester.tap(find.text('Coba Lagi'));
          await tester.pump();
          expect(retryCalls, 1);
        },
      );
    }

    testWidgets('StateViews render cleanly at 200% text scaling', (
      tester,
    ) async {
      await setNarrowPhoneSurface(tester);

      await tester.pumpWidget(
        wrapInTheme(
          theme: AppTheme.light(),
          textScale: 2.0,
          child: EmptyStateView(
            title: 'Belum ada laporan insiden',
            description:
                'Laporan warga atau petugas di wilayah ini akan muncul di sini.',
            icon: Icons.assignment_outlined,
            actionLabel: 'Buat Laporan',
            onAction: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Buat Laporan'), findsOneWidget);
    });
  });

  group('ForensicStrip', () {
    const sampleHash =
        'a3f9c1209b4e8d71c6f20a145d3c8e7f9012a4b6c8d0e2f4a6b8c0d2e4f68b4d';

    for (final mode in <(String, ThemeData)>[
      ('Light', AppTheme.light()),
      ('Dark', AppTheme.dark()),
    ]) {
      testWidgets(
        'renders wrap and table forensic layouts in ${mode.$1} mode with JetBrains Mono values',
        (tester) async {
          await setNarrowPhoneSurface(tester);

          await tester.pumpWidget(
            wrapInTheme(
              theme: mode.$2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ForensicStrip.metadata(
                      title: 'Ringkasan Bukti Patroli',
                      latitude: -7.282514,
                      longitude: 112.795481,
                      timestampLabel: '22:34:09 WIB',
                      distanceMeters: 14.2,
                      accuracyMeters: 12.0,
                      isMocked: false,
                      sha256Hash: sampleHash,
                      layout: ForensicStripLayout.wrap,
                    ),
                    const SizedBox(height: 16),
                    ForensicStrip.metadata(
                      title: 'Tabel Audit Forensik',
                      latitude: -7.282514,
                      longitude: 112.795481,
                      timestampLabel: '22:34:09 WIB',
                      distanceMeters: 42.6,
                      accuracyMeters: 41.5,
                      isMocked: true,
                      sha256Hash: sampleHash,
                      layout: ForensicStripLayout.table,
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('-7.28251, 112.79548'), findsNWidgets(2));
          expect(find.text('22:34:09 WIB'), findsNWidgets(2));
          expect(find.text('14.2 m'), findsOneWidget);
          expect(find.text('GPS Asli'), findsOneWidget);
          expect(find.text('Terdeteksi Mock'), findsOneWidget);
          expect(find.text('a3f9c120...f68b4d'), findsOneWidget);
          expect(find.text(sampleHash), findsOneWidget);

          final coordWidget = tester.widget<Text>(
            find.text('-7.28251, 112.79548').first,
          );
          expect(coordWidget.style?.fontFamily, AppTheme.monoFontFamily);
        },
      );
    }

    testWidgets('renders table layout cleanly at 200% text scaling', (
      tester,
    ) async {
      await setNarrowPhoneSurface(tester);

      await tester.pumpWidget(
        wrapInTheme(
          theme: AppTheme.dark(),
          textScale: 2.0,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ForensicStrip.metadata(
              latitude: -7.282514,
              longitude: 112.795481,
              timestampLabel: '22:34:09 WIB',
              distanceMeters: 14.2,
              accuracyMeters: 12.0,
              sha256Hash: sampleHash,
              layout: ForensicStripLayout.table,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('-7.28251, 112.79548'), findsOneWidget);
    });
  });

  group('RondaApp shell and ThemeMode switching', () {
    testWidgets('switches between Light, Dark, and System modes interactively', (
      tester,
    ) async {
      await setNarrowPhoneSurface(tester);

      await tester.pumpWidget(const ProviderScope(child: RondaApp()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('RondaDigital'), findsOneWidget);

      final initialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(initialApp.locale, const Locale('id', 'ID'));
      expect(initialApp.themeMode, ThemeMode.system);

      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      await tester.tap(find.text('Terang'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
    });

    testWidgets('displays startupFailure using ErrorStateView', (tester) async {
      await setNarrowPhoneSurface(tester);

      await tester.pumpWidget(
        const ProviderScope(
          child: RondaApp(
            startupFailure: ConfigurationFailure(
              message: 'Konfigurasi SUPABASE_URL belum diatur.',
              code: 'ENV_MISSING',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Konfigurasi SUPABASE_URL belum diatur.'),
        findsOneWidget,
      );
      expect(find.text('KODE: ENV_MISSING'), findsOneWidget);
    });

    testWidgets('supports MaterialApp.router when routerConfig is supplied', (
      tester,
    ) async {
      await setNarrowPhoneSurface(tester);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Halaman Router Aktif')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: RondaApp(
            routerConfig: router,
            themeModeOverride: ThemeMode.dark,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Halaman Router Aktif'), findsOneWidget);
    });
  });
}
