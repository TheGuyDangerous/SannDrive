import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0C0F16);
  static const surface = Color(0xFF141925);
  static const surfaceHi = Color(0xFF1C2332);
  static const border = Color(0x14FFFFFF);
  static const text = Color(0xFFE9ECF4);
  static const muted = Color(0xFF8A93A8);
  static const accent = Color(0xFF3B82F6);
  static const accent2 = Color(0xFF22D3EE);
  static const danger = Color(0xFFF2555A);
}

class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
