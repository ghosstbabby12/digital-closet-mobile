import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom space lists must leave so they do not end up under the floating bar.
const double floatingNavClearance = 104;

/// Minimal style: cream (or near-black) background, soft cards, sage green
/// accent and bold titles. Screens take their colors from
/// `Theme.of(context).colorScheme`, so they work in light and dark mode.
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  // Sage green with contrast ≥ 4.5:1 on the cream background and the cards.
  primary: Color(0xFF566B5A),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF566B5A),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFFCFAF6),
  onSurface: Color(0xFF1C1C1A),
  onSurfaceVariant: Color(0xFF6B6962),
  surfaceContainerHighest: Color(0xFFEDE9E0),
  outline: Color(0xFFCFCABE),
  outlineVariant: Color(0xFFE5E0D6),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF9DB5A1),
  onPrimary: Color(0xFF142017),
  secondary: Color(0xFF9DB5A1),
  onSecondary: Color(0xFF142017),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  surface: Color(0xFF1F211E),
  onSurface: Color(0xFFF2F0EA),
  onSurfaceVariant: Color(0xFFA9A79F),
  surfaceContainerHighest: Color(0xFF2C2F2A),
  outline: Color(0xFF4A4D46),
  outlineVariant: Color(0xFF353832),
);

ThemeData buildLightTheme() => _buildTheme(_lightScheme, const Color(0xFFF5F2EB));

ThemeData buildDarkTheme() => _buildTheme(_darkScheme, const Color(0xFF141513));

ThemeData _buildTheme(ColorScheme scheme, Color background) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    // Inter for loose styles too (buttons, chips, labels), which would
    // otherwise fall back to the system font (Roboto).
    fontFamily: GoogleFonts.inter().fontFamily,
  );
  final textTheme = GoogleFonts.interTextTheme(base.textTheme)
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

  return base.copyWith(
    textTheme: textTheme.copyWith(
      displaySmall: textTheme.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      // Material 3 uses wide letter spacing (0.25-0.5), which looks loose with Inter.
      bodyLarge: textTheme.bodyLarge?.copyWith(letterSpacing: 0, height: 1.4),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4, letterSpacing: 0.1),
      bodySmall: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.primary.withValues(alpha: 0.55),
        disabledForegroundColor: scheme.onPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: scheme.primary)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      side: BorderSide(color: scheme.outlineVariant),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
