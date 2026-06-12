import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryPink = Color(0xFFF080A8); // Thoda aur premium pink
  static const Color backgroundCream = Color(0xFFFDFBF7); 
  static const Color textDark = Color(0xFF2D3142); // Sharp deep text
  static const Color textLight = Color(0xFF9094A6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPink,
        primary: primaryPink,
        surface: Colors.transparent, 
      ),
      scaffoldBackgroundColor: Colors.transparent, // Transparent for gradient
      // Inter font ekdum clean aur modern Apple/Stripe look deta hai
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(color: textDark, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: const TextStyle(color: textDark, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
        bodyMedium: const TextStyle(color: textLight, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryPink),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}