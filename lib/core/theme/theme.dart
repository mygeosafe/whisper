import 'package:flutter/material.dart';

class LoopMindTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A7C9A),
        brightness: Brightness.light,
      ),
      textTheme: _textTheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7F8),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        color: Colors.transparent,
        foregroundColor: base.colorScheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300),
    displayMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300),
    displaySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
    labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
  );
}
