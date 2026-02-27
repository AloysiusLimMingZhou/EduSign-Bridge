import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // App basic colors
  static const Color primary = Color(0xFF6C63FF); // Bright Purple
  static const Color secondary = Color(0xFF9D50BB); // Deep Purple
  static const Color accent = Color(0xFFB0C7FF);

  // Gradient Colors
  static const Gradient linearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9D50BB), // Purple
      Color(0xFF6E48AA), // Deep Blue-Purple
    ],
  );

  // Text colors
  static const Color textPrimary = Color(
    0xFFFFFFFF,
  ); // White text for dark mode default
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textWhite = Colors.white;

  // Background colors
  static const Color lightBackground = Color(0xFFF6F6F6);
  static const Color darkBackground = Color(0xFF0F0F0F); // Space Black
  static const Color primaryBackground = Color(0xFF1A1A1A);

  // Background Container colors
  static const Color lightContainer = Color(0xFFFFFFFF);
  static const Color darkContainer = Color(0xFF1E1E1E);

  // Button colors
  static const Color buttonPrimary = Color(0xFF6C63FF);
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Status colors
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color success = Color(0xFF4CAF50);

  // Neutral Shades
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF121212);
  static const Color grey = Color(0xFF2C2C2C);
  static const Color lightGrey = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
}
