import 'package:flutter/material.dart';

class AppTheme {
  // Primary brand colors
  static const Color mustGreen = Color(0xFF2E7D32);
  static const Color mustDeepGreen = Color(0xFF1B5E20);
  static const Color mustGold = Color(0xFFD4AF37);
  static const Color mustGreenBody=Color(0xFF081C15);
  static const Color mustGreenSurface = Color(0xFF1B4332);

  // Background gradient for splash and auth screens
  static const Gradient mustGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF081C15),
      Color(0xFF1B4332),
    ],
  );

  // Main application theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: mustGreen),
    );
  }
}