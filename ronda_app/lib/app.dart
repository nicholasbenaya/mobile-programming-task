import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/theme/app_theme.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';

/// Manages the active Light, Dark, or System theme preference for RondaDigital.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Root RondaDigital widget applying Civic Operational Light and Dark themes and `id_ID` locale.
class RondaApp extends ConsumerWidget {
  const RondaApp({
    super.key,
    this.routerConfig,
    this.home,
    this.startupFailure,
    this.themeModeOverride,
  });

  final RouterConfig<Object>? routerConfig;
  final Widget? home;
  final AppFailure? startupFailure;
  final ThemeMode? themeModeOverride;

  static const Locale defaultLocale = Locale('id', 'ID');
  static const List<Locale> appSupportedLocales = <Locale>[
    Locale('id', 'ID'),
    Locale('en', 'US'),
  ];
  static const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        _FallbackMaterialLocalizationsDelegate(),
        _FallbackCupertinoLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveThemeMode =
        themeModeOverride ?? ref.watch(themeModeProvider);

    if (routerConfig != null) {
      return MaterialApp.router(
        title: 'RondaDigital',
        debugShowCheckedModeBanner: false,
        locale: defaultLocale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: effectiveThemeMode,
        routerConfig: routerConfig,
      );
    }

    return MaterialApp(
      title: 'RondaDigital',
      debugShowCheckedModeBanner: false,
      locale: defaultLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: effectiveThemeMode,
      home: home ?? _RondaStartupScreen(startupFailure: startupFailure),
    );
  }
}

// Allows `Locale('id', 'ID')` without pulling extra localization packages.
class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'id' || locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class _FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'id' || locale.languageCode == 'en';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

class _RondaStartupScreen extends ConsumerWidget {
  const _RondaStartupScreen({this.startupFailure});

  final AppFailure? startupFailure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tokens.brandPrimary,
                borderRadius: BorderRadius.circular(CivicTokens.radiusChip),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 18,
                color: tokens.onBrandPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('RondaDigital'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CivicTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(CivicTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mode Tampilan', style: textTheme.titleMedium),
                      const SizedBox(height: CivicTokens.spaceXs),
                      Text(
                        'Pilih tampilan siang atau malam sesuai kebutuhan jaga.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: CivicTokens.spaceMd),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const <ButtonSegment<ThemeMode>>[
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              label: Text('Sistem'),
                              icon: Icon(Icons.brightness_auto_outlined),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              label: Text('Terang'),
                              icon: Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              label: Text('Gelap'),
                              icon: Icon(Icons.dark_mode_outlined),
                            ),
                          ],
                          selected: <ThemeMode>{currentMode},
                          onSelectionChanged: (selection) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CivicTokens.spaceSection),
              if (startupFailure != null)
                ErrorStateView.fromFailure(
                  startupFailure!,
                  title: 'Konfigurasi lingkungan belum lengkap',
                )
              else
                const EmptyStateView(
                  title: 'Siap masuk ke wilayah patroli',
                  description:
                      'Tema operasional dan komponen antarmuka sudah aktif. Modul autentikasi dan peta akan terhubung pada tahap berikutnya.',
                  icon: Icons.radar_outlined,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
