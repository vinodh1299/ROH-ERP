import 'package:flutter/material.dart';

class AppTheme {
  // Sage Green primary seed color as recommended by the Engineering Guide
  static const Color sagePrimary = Color(0xFF7FA98A);
  static const Color sagePrimaryLight = Color(0xFFA5C4AE);
  static const Color sagePrimaryDark = Color(0xFF5B8266);
  static const Color background = Color(0xFFF9FAF9);
  static const Color surface = Colors.white;

  static ThemeData get light => lightTheme;
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sagePrimary,
        primary: sagePrimary,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sagePrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48), // Accessible tap target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
