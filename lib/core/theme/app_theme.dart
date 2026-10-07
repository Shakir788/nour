import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF160E22);
  static const Color backgroundEnd = Color(0xFF20132E);
  static const Color surface = Color(0xFF241831);
  static const Color surfaceElevated = Color(0xFF2E1E40);

  static const Color gold = Color(0xFFE0B155);
  static const Color goldLight = Color(0xFFF3D089);
  static const Color goldMuted = Color(0xFF9C7A3A);

  static const Color textPrimary = Color(0xFFFAF6EE);
  static const Color textSecondary = Color(0xFFC7BCD6);
  static const Color textMuted = Color(0xFF8B7FA0);

  static const Color divider = Color(0x1AFFFFFF);
  static const Color goldBorder = Color(0x59E0B155);

  // ─── Backward-compat aliases ───
  static const Color primaryPink = gold;
  static const Color textDark    = textPrimary;
  static const Color textLight   = textMuted;

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold, goldMuted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient heroGlow = RadialGradient(
    colors: [Color(0x40E0B155), Color(0x00E0B155)],
    center: Alignment.topRight,
    radius: 1.2,
  );
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );
}

class AppTheme {
  AppTheme._();

  // ─── Backward-compat aliases (journal_screen uses AppTheme.xxx) ───
  static const Color primaryPink = AppColors.gold;
  static const Color textDark    = AppColors.textPrimary;
  static const Color textLight   = AppColors.textMuted;

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.surface,
        onPrimary: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.caption,
      ),
      dividerColor: AppColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      iconTheme: const IconThemeData(color: AppColors.gold),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.background),
        side: const BorderSide(color: AppColors.textMuted, width: 2),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
      ),
    );
  }
}