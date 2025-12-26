import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo 600

  // Background Light
  static const Color bgLightStart = Color(0xFFF8FAFC); // Slate 50
  static const Color bgLightEnd = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF0F172A); // Slate 900

  // Background Dark
  static const Color bgDarkStart = Color(0xFF030712); // Gray 950
  static const Color bgDarkEnd = Color(0xFF111827); // Gray 900
  static const Color surfaceDark = Color(0xFF1F2937); // Gray 800 (Glass base)
  static const Color textDark = Color(0xFFF9FAFB); // Gray 50

  // Accents
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color warning = Color(0xFFEAB308); // Yellow 500
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
}
