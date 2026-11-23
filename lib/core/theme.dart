import 'package:flutter/material.dart';

class EcoColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF005005);
  static const Color accent = Color(0xFF66BB6A);
  static const Color climateRed = Color(0xFFD32F2F);
  static const Color climateYellow = Color(0xFFFBC02D);
  static const Color climateGreen = Color(0xFF388E3C);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: EcoColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: EcoColors.primary,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EcoColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: EcoColors.primary,
          brightness: Brightness.dark,
        ),
      );
}
