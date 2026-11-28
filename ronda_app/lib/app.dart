import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/app_theme.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/presentation/auth/theme_mode_selector.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';
import 'package:ronda_app/providers/theme_provider.dart';

export 'package:ronda_app/providers/theme_provider.dart';

/// Root RondaDigital widget applying Civic Operational Light and Dark themes, `id_ID` locale, and GoRouter.
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

    if (startupFailure != null && home == null && routerConfig == null) {
      return MaterialApp(
        title: 'RondaDigital',
        debugShowCheckedModeBanner: false,
        locale: defaultLocale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: effectiveThemeMode,
        home: _StartupFailureScreen(startupFailure: startupFailure!),
      );
    }

    if (home != null && routerConfig == null) {
      return MaterialApp(
        title: 'RondaDigital',
        debugShowCheckedModeBanner: false,
        locale: defaultLocale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: effectiveThemeMode,
        home: home,
      );
    }

    final effectiveRouter = routerConfig ?? ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'RondaDigital',
      debugShowCheckedModeBanner: false,
      locale: defaultLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: effectiveThemeMode,
      routerConfig: effectiveRouter,
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

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({required this.startupFailure});

  final AppFailure startupFailure;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
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
              const ThemeModeSelectorCard(),
              const SizedBox(height: CivicTokens.spaceSection),
              ErrorStateView.fromFailure(
                startupFailure,
                title: 'Konfigurasi lingkungan belum lengkap',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
