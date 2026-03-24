import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFFFF6584);
  static const Color accentColor = Color(0xFFFFBE0B);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color surfaceColor = Color(0xFFF8F9FA);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
        ),
        scaffoldBackgroundColor: surfaceColor,
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      );

  static const List<Color> noteColors = [
    Color(0xFFFFF9C4),
    Color(0xFFE1F5FE),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
    Color(0xFFFFE0B2),
    Color(0xFFFCE4EC),
  ];

  static const List<Color> appointmentColors = [
    Color(0xFF6C63FF),
    Color(0xFF4CAF50),
    Color(0xFFFF6584),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
  ];

  static LinearGradient get homeGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
      );

  static LinearGradient get todoGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2196F3), Color(0xFF6C63FF)],
      );

  static LinearGradient get noteGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF26C6DA), Color(0xFF00897B)],
      );

  static LinearGradient get calendarGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF26C6DA)],
      );

  static LinearGradient get alarmGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6584), Color(0xFFFF9800)],
      );
}
