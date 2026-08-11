import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppThemeKind { 
  light, 
  dark, 
  gold,
  ocean,      // Analogous blues & teals - calming, trustworthy
  forest,     // Nature greens - balanced, healthy
  sunset,     // Warm oranges & pinks - energetic, optimistic
  lavender,   // Soft purples - creative, mindful
  midnight,   // Deep blue-blacks - sophisticated, focused
  custom,     // User-customizable theme
}

class AppTheme {
  // ===== Shared base tokens (from your original) =====
  static const _primaryIndigo = Color(0xFF6366F1);
  static const _lightBg = Color(0xFFF8FAFC);
  static const _lightSurface = Colors.white;
  static const _lightTextPrimary = Color(0xFF1E293B);
  static const _lightTextSecondary = Color(0xFF64748B);

  // ===== Dark (black & white) =====
  static const _darkBg = Color(0xFF121212);         // WCAG-friendly dark
  static const _darkSurface = Color(0xFF1E1E1E);    // slightly lighter for cards
  static const _darkTextPrimary = Color(0xDEFFFFFF); // 87% opacity white
  static const _darkTextSecondary = Color(0x99FFFFFF); // 60% opacity white
  static const _darkPrimary = Colors.white;         // white accents

  // ===== Gold (luxury) =====
  // Tip: keep gold as accent, not large surfaces. Looks premium & readable.
  static const _goldPrimary = Color(0xFFFFD700);    // bright gold for contrast
  static const _goldPrimaryAlt = Color(0xFFC6A05E); // hover/pressed
  static const _goldBg = Color(0xFF121212);         // WCAG dark background
  static const _goldSurface = Color(0xFF1E1E1E);    // dark card surface
  static const _goldTextPrimary = Color(0xDEFFFFFF); // 87% opacity white
  static const _goldTextSecondary = Color(0xFFC7A200); // brighter gold for better contrast

  // ===== Ocean (Analogous: blues & teals - calming, trustworthy) =====
  // Darkened from 0xFF0EA5E9: that sky blue only hit 2.77:1 contrast against
  // the white text buttons render on top of it (AA needs 4.5:1) -- caught by
  // test/regression/theme_contrast_test.dart. Reuses the palette's existing
  // deep-blue shade rather than inventing a new color.
  static const _oceanPrimary = Color(0xFF0369A1);     // Sky blue (main CTA)
  static const _oceanSecondary = Color(0xFF06B6D4);   // Cyan (accents)
  static const _oceanBg = Color(0xFFF0F9FF);          // Very light blue bg
  static const _oceanSurface = Color(0xFFFFFFFF);     // White cards
  static const _oceanTextPrimary = Color(0xFF0C4A6E); // Deep blue text
  static const _oceanTextSecondary = Color(0xFF0369A1); // Medium blue

  // ===== Forest (Nature: greens - balanced, healthy, growth) =====
  // Darkened from 0xFF10B981 for the same reason as ocean above (2.54:1
  // white-on-primary contrast, below the 4.5:1 AA bar).
  static const _forestPrimary = Color(0xFF047857);    // Emerald green
  static const _forestSecondary = Color(0xFF059669);  // Darker green
  static const _forestBg = Color(0xFFF0FDF4);         // Very light green bg
  static const _forestSurface = Color(0xFFFFFFFF);    // White cards
  static const _forestTextPrimary = Color(0xFF064E3B); // Deep forest text
  static const _forestTextSecondary = Color(0xFF047857); // Medium green

  // ===== Sunset (Warm: oranges & pinks - energetic, optimistic) =====
  // Darkened from 0xFFFF6B35 for the same reason as ocean above (2.84:1
  // white-on-primary contrast, below the 4.5:1 AA bar).
  static const _sunsetPrimary = Color(0xFFC2410C);    // Vibrant orange
  static const _sunsetSecondary = Color(0xFFF72585);  // Hot pink accent
  static const _sunsetBg = Color(0xFFFFF8F5);         // Warm cream bg
  static const _sunsetSurface = Color(0xFFFFFFFF);    // White cards
  static const _sunsetTextPrimary = Color(0xFF7C2D12); // Deep brown-red text
  static const _sunsetTextSecondary = Color(0xFFC2410C); // Orange-brown

  // ===== Lavender (Soft purples - creative, mindful, wellness) =====
  static const _lavenderPrimary = Color(0xFF9333EA);  // Rich purple
  static const _lavenderSecondary = Color(0xFFA855F7); // Lighter purple
  static const _lavenderBg = Color(0xFFFAF5FF);       // Very light lavender bg
  static const _lavenderSurface = Color(0xFFFFFFFF);  // White cards
  static const _lavenderTextPrimary = Color(0xFF581C87); // Deep purple text
  static const _lavenderTextSecondary = Color(0xFF7E22CE); // Medium purple

  // ===== Midnight (Deep blue-black - sophisticated, focused) =====
  static const _midnightPrimary = Color(0xFF60A5FA);  // Bright blue accent
  static const _midnightSecondary = Color(0xFF3B82F6); // Medium blue
  static const _midnightBg = Color(0xFF0F172A);       // Very dark blue-black
  static const _midnightSurface = Color(0xFF1E293B);  // Slate surface
  static const _midnightTextPrimary = Color(0xDEFFFFFF); // 87% white
  static const _midnightTextSecondary = Color(0x99FFFFFF); // 60% white

  // Public API: get ThemeData by kind
  static ThemeData byKind(AppThemeKind kind, {
    Color? customPrimary,
    Color? customBackground,
    Color? customSurface,
  }) {
    final raw = _rawByKind(
      kind,
      customPrimary: customPrimary,
      customBackground: customBackground,
      customSurface: customSurface,
    );
    // _appleize is Cupertino chrome only — not applied on Material (Android).
    final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isApplePlatform ? _appleize(raw) : raw;
  }

  static ThemeData _rawByKind(AppThemeKind kind, {
    Color? customPrimary,
    Color? customBackground,
    Color? customSurface,
  }) {
    switch (kind) {
      case AppThemeKind.dark:
        return _darkTheme;
      case AppThemeKind.gold:
        return _goldTheme;
      case AppThemeKind.ocean:
        return _oceanTheme;
      case AppThemeKind.forest:
        return _forestTheme;
      case AppThemeKind.sunset:
        return _sunsetTheme;
      case AppThemeKind.lavender:
        return _lavenderTheme;
      case AppThemeKind.midnight:
        return _midnightTheme;
      case AppThemeKind.custom:
        return buildCustomTheme(
          primary: customPrimary ?? _primaryIndigo,
          background: customBackground ?? _lightBg,
          surface: customSurface ?? _lightSurface,
        );
      case AppThemeKind.light:
        return _lightTheme;
    }
  }

  /// iOS-flavoured component styling applied on top of every theme.
  ///
  /// Layered here, in the single funnel all nine themes pass through, rather
  /// than repeated in each `_xTheme` getter -- so a tweak lands everywhere and
  /// the per-theme definitions stay purely about colour.
  static ThemeData _appleize(ThemeData base) {
    final scheme = base.colorScheme;

    return base.copyWith(
      // iOS switches are a white thumb on a tinted track. Material 3's default
      // renders a dark thumb here, which reads as "off" at a glance.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.4);
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurface.withValues(alpha: 0.22);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        trackOutlineWidth: WidgetStateProperty.all(0),
      ),
      // iOS never uses Material's filled/elevated slider look.
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 4,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.16),
        thumbColor: Colors.white,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      ),
      // Hairline dividers, as on iOS grouped lists.
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: scheme.onSurface.withValues(alpha: 0.12),
      ),
      // iOS sheets and dialogs are noticeably more rounded than Material's.
      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        showDragHandle: true,
      ),
      // iOS's taller, rounder buttons with its 17pt label.
      //
      // Height only -- deliberately NOT `Size.fromHeight`, which sets the
      // *minimum width* to double.infinity. That forces every button to demand
      // infinite width, so any button laid out in a Row (a dialog's
      // Cancel/Confirm pair, for instance) fails to lay out and its whole
      // dialog renders as an empty barrier. Callers that want full-width
      // wrap the button in a SizedBox, as onboarding already does.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // 44pt is Apple's minimum comfortable hit target.
      listTileTheme: base.listTileTheme.copyWith(
        minVerticalPadding: 10,
        iconColor: scheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
  
  // Build a custom theme from provided colors
  static ThemeData buildCustomTheme({
    required Color primary,
    required Color background,
    required Color surface,
  }) {
    // Determine if we're in dark mode based on background luminance
    final isDark = background.computeLuminance() < 0.5;
    final onPrimary = primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final onSurface = surface.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    // No `onBackground` counterpart: Material 3 folded ColorScheme.background
    // and onBackground into surface/onSurface, and the argument no longer
    // exists. `background` is still applied below via scaffoldBackgroundColor.

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      error: Colors.red,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.2)),
        ),
      ),
    );
  }

  // Keep aliases if you want direct access:
  static ThemeData get lightTheme => _lightTheme;
  static ThemeData get darkTheme  => _darkTheme;
  static ThemeData get goldTheme  => _goldTheme;

  // ===== LIGHT THEME (yours, with a few small extras) =====
  static ThemeData get _lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryIndigo,
      brightness: Brightness.light,
      surface: _lightSurface,
      background: _lightBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _lightTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryIndigo,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _primaryIndigo, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _lightTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _lightTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _lightTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _lightTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _lightTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _lightTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _lightTextSecondary),
      ),

      dividerColor: Colors.grey.shade200,
      iconTheme: const IconThemeData(color: _lightTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _primaryIndigo,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== DARK THEME (black & white) =====
  static ThemeData get _darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: Colors.black,
      secondary: _darkPrimary,
      onSecondary: Colors.black,
      surface: _darkSurface,
      onSurface: _darkTextPrimary,
      onSurfaceVariant: _darkTextSecondary, // 60% opacity for secondary text
      error: Color(0xFFEF4444),
      onError: Colors.white,
      tertiary: Colors.white,
      onTertiary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBg,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        hintStyle: const TextStyle(color: _darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _darkTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _darkTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _darkTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _darkTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _darkTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _darkTextSecondary),
      ),

      dividerColor: Colors.white.withValues(alpha: 0.06),
      iconTheme: const IconThemeData(color: _darkTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: Colors.white,
        unselectedItemColor: _darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== GOLD THEME (luxury) =====
  static ThemeData get _goldTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _goldPrimary,
      onPrimary: Color(0xFF121212), // Dark text on gold
      secondary: _goldPrimary,
      onSecondary: Color(0xFF121212),
      surface: _goldSurface,
      onSurface: _goldTextPrimary,
      onSurfaceVariant: _goldTextSecondary, // Brighter gold for secondary text
      outline: _goldTextSecondary, // Use brighter gold for outlines
      error: Color(0xFFEF4444),
      onError: Colors.white,
      tertiary: _goldPrimaryAlt,
      onTertiary: Color(0xFF121212),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _goldBg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _goldBg,
        foregroundColor: _goldTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _goldTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: _goldSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _goldPrimary.withValues(alpha: 0.25)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _goldPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _goldSurface,
        hintStyle: const TextStyle(color: _goldTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _goldPrimary.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _goldPrimary.withValues(alpha: 0.35)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _goldPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _goldTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _goldTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _goldTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _goldTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _goldTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _goldTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _goldTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _goldTextSecondary),
      ),

      dividerColor: _goldPrimary.withValues(alpha: 0.18),
      iconTheme: const IconThemeData(color: _goldTextPrimary),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _goldSurface,
        contentTextStyle: TextStyle(color: _goldTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _goldSurface,
        selectedItemColor: _goldPrimary,
        unselectedItemColor: _goldTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== OCEAN THEME (Calming blues & teals) =====
  static ThemeData get _oceanTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _oceanPrimary,
      brightness: Brightness.light,
      primary: _oceanPrimary,
      secondary: _oceanSecondary,
      surface: _oceanSurface,
      background: _oceanBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _oceanBg,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: _oceanSurface,
        foregroundColor: _oceanTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _oceanTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: _oceanSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _oceanPrimary.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _oceanPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _oceanPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _oceanSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _oceanSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _oceanSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _oceanPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _oceanTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _oceanTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _oceanTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _oceanTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _oceanTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _oceanTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _oceanTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _oceanTextSecondary),
      ),

      dividerColor: _oceanSecondary.withValues(alpha: 0.2),
      iconTheme: const IconThemeData(color: _oceanTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _oceanSurface,
        selectedItemColor: _oceanPrimary,
        unselectedItemColor: _oceanTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== FOREST THEME (Natural greens) =====
  static ThemeData get _forestTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _forestPrimary,
      brightness: Brightness.light,
      primary: _forestPrimary,
      secondary: _forestSecondary,
      surface: _forestSurface,
      background: _forestBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _forestBg,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: _forestSurface,
        foregroundColor: _forestTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _forestTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: _forestSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _forestPrimary.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _forestPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _forestPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _forestSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _forestSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _forestSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _forestPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _forestTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _forestTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _forestTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _forestTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _forestTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _forestTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _forestTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _forestTextSecondary),
      ),

      dividerColor: _forestSecondary.withValues(alpha: 0.2),
      iconTheme: const IconThemeData(color: _forestTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _forestSurface,
        selectedItemColor: _forestPrimary,
        unselectedItemColor: _forestTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== SUNSET THEME (Warm & energetic) =====
  static ThemeData get _sunsetTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _sunsetPrimary,
      brightness: Brightness.light,
      primary: _sunsetPrimary,
      secondary: _sunsetSecondary,
      surface: _sunsetSurface,
      background: _sunsetBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _sunsetBg,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: _sunsetSurface,
        foregroundColor: _sunsetTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _sunsetTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: _sunsetSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _sunsetPrimary.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _sunsetPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _sunsetPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _sunsetSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _sunsetSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _sunsetSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _sunsetPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _sunsetTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _sunsetTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _sunsetTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _sunsetTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _sunsetTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _sunsetTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _sunsetTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _sunsetTextSecondary),
      ),

      dividerColor: _sunsetSecondary.withValues(alpha: 0.2),
      iconTheme: const IconThemeData(color: _sunsetTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _sunsetSurface,
        selectedItemColor: _sunsetPrimary,
        unselectedItemColor: _sunsetTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== LAVENDER THEME (Mindful & creative) =====
  static ThemeData get _lavenderTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lavenderPrimary,
      brightness: Brightness.light,
      primary: _lavenderPrimary,
      secondary: _lavenderSecondary,
      surface: _lavenderSurface,
      background: _lavenderBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lavenderBg,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: _lavenderSurface,
        foregroundColor: _lavenderTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _lavenderTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: _lavenderSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _lavenderPrimary.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lavenderPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lavenderPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lavenderSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lavenderSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lavenderSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _lavenderPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _lavenderTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _lavenderTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _lavenderTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _lavenderTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _lavenderTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _lavenderTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _lavenderTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _lavenderTextSecondary),
      ),

      dividerColor: _lavenderSecondary.withValues(alpha: 0.2),
      iconTheme: const IconThemeData(color: _lavenderTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lavenderSurface,
        selectedItemColor: _lavenderPrimary,
        unselectedItemColor: _lavenderTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ===== MIDNIGHT THEME (Sophisticated dark blue) =====
  static ThemeData get _midnightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _midnightPrimary,
      onPrimary: _midnightBg,
      secondary: _midnightSecondary,
      onSecondary: Colors.white,
      surface: _midnightSurface,
      onSurface: _midnightTextPrimary,
      onSurfaceVariant: _midnightTextSecondary,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      tertiary: _midnightPrimary,
      onTertiary: _midnightBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _midnightBg,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: _midnightBg,
        foregroundColor: _midnightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: _midnightTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: _midnightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _midnightPrimary.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _midnightPrimary,
          foregroundColor: _midnightBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 44),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _midnightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(44, 44),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _midnightSurface,
        hintStyle: const TextStyle(color: _midnightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _midnightSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _midnightSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _midnightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _midnightTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _midnightTextPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _midnightTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _midnightTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _midnightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: _midnightTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _midnightTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: _midnightTextSecondary),
      ),

      dividerColor: _midnightSecondary.withValues(alpha: 0.2),
      iconTheme: const IconThemeData(color: _midnightTextPrimary),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _midnightSurface,
        selectedItemColor: _midnightPrimary,
        unselectedItemColor: _midnightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}