import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna diambil dari desain Figma:
/// - Background cream/beige lembut
/// - Aksen coklat tua untuk tombol, nav bar, dan card gelap
/// - Teks putih di atas elemen gelap, coklat tua di atas elemen terang
class AppColors {
  static const Color background = Color(0xFFF3EFE6); // krem terang
  static const Color cardDark = Color(0xFF4A3B32); // coklat tua (nav, card, tombol)
  static const Color cardDarkAlt = Color(0xFF5C4A3E); // coklat sedikit lebih terang
  static const Color textLight = Color(0xFFF5F1E8); // teks di atas gelap
  static const Color textDark = Color(0xFF2E2620); // teks utama di atas terang
  static const Color textMuted = Color(0xFF8A7B6E); // teks sekunder / placeholder
  static const Color success = Color(0xFF3F7D4C);
  static const Color pending = Color(0xFFD9A441);
  static const Color danger = Color(0xFFB4483C);
  static const Color inputFill = Color(0xFFEFE9DC);
  static const Color border = Color(0xFFDDD4C4);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cardDark,
        primary: AppColors.cardDark,
        surface: AppColors.background,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textDark,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardDark,
          foregroundColor: AppColors.textLight,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}