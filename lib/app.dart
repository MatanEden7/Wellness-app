import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme.dart';
import 'routing/routes.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/preferences_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WellnessApp extends ConsumerWidget {
  const WellnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final prefs = ref.watch(preferencesServiceProvider);
    
    return MaterialApp.router(
      title: 'Wellness App',
      theme: AppTheme.byKind(
        currentTheme,
        customPrimary: currentTheme == AppThemeKind.custom ? prefs.customPrimaryColor : null,
        customBackground: currentTheme == AppThemeKind.custom ? prefs.customBackgroundColor : null,
        customSurface: currentTheme == AppThemeKind.custom ? prefs.customSurfaceColor : null,
      ).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLanguage.values.map((lang) => lang.locale),
      locale: currentLanguage.locale,
      
      // RTL support - automatically handles text direction based on locale
      builder: (context, child) {
        return Directionality(
          textDirection: currentLanguage.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
