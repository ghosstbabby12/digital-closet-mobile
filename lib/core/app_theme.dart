import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tipografías inspiradas en la ficha de arquitectura del proyecto
/// (closet.html): tonos cálidos de papel, acentos tierra, serif para
/// títulos y sans para texto de cuerpo.
class AppColors {
  static const ink = Color(0xFF2B241E);
  static const inkSoft = Color(0xFF5B5347);
  static const paper = Color(0xFFECE6DA);
  static const card = Color(0xFFF6F2E9);
  static const line = Color(0xFFC9BFA9);
  static const accent = Color(0xFFAD8639);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.paper,
    ),
    scaffoldBackgroundColor: AppColors.paper,
  );

  return base.copyWith(
    textTheme: GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      titleLarge: GoogleFonts.cormorantGaramond(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.workSans(color: AppColors.inkSoft),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.card,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}
