import 'package:flutter/material.dart';

/// AppTheme — Retro 8-bit / pixel aesthetic
/// All colours, typography and widget defaults live here.
/// Screens import RetroColors / RetroTextStyles rather than hardcoding values.
abstract class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: RetroColors.neonGreen,
        secondary: RetroColors.pixelYellow,
        tertiary: RetroColors.chaosRed,
        surface: RetroColors.darkBg,
        onPrimary: RetroColors.darkBg,
        onSecondary: RetroColors.darkBg,
        onSurface: RetroColors.lightText,
      ),
      scaffoldBackgroundColor: RetroColors.darkBg,
      fontFamily: 'PixelifySans',
      textTheme: _buildTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RetroColors.neonGreen,
          foregroundColor: RetroColors.darkBg,
          textStyle: RetroTextStyles.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RetroColors.panelBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: RetroColors.neonGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: RetroColors.dimGreen, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: RetroColors.neonGreen, width: 2),
        ),
        labelStyle: RetroTextStyles.label,
        hintStyle: RetroTextStyles.hint,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RetroColors.panelBg,
        foregroundColor: RetroColors.neonGreen,
        titleTextStyle: TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 14,
          color: RetroColors.neonGreen,
          letterSpacing: 2,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: RetroColors.panelBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: RetroColors.dimGreen,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: RetroColors.neonGreen),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: RetroColors.panelBg,
        contentTextStyle: TextStyle(
          fontFamily: 'PixelifySans',
          color: RetroColors.lightText,
          fontSize: 13,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 28,
        color: RetroColors.neonGreen,
        letterSpacing: 3,
        height: 1.4,
      ),
      displayMedium: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 20,
        color: RetroColors.neonGreen,
        letterSpacing: 2,
        height: 1.4,
      ),
      displaySmall: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 16,
        color: RetroColors.neonGreen,
        letterSpacing: 1.5,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 13,
        color: RetroColors.pixelYellow,
        letterSpacing: 1.5,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PixelifySans',
        fontSize: 20,
        color: RetroColors.lightText,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontFamily: 'PixelifySans',
        fontSize: 18,
        color: RetroColors.lightText,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'PixelifySans',
        fontSize: 16,
        color: RetroColors.lightText,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PixelifySans',
        fontSize: 14,
        color: RetroColors.dimText,
      ),
      labelLarge: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 11,
        color: RetroColors.neonGreen,
        letterSpacing: 1,
      ),
    );
  }
}

abstract class RetroColors {
  // Backgrounds
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color panelBg = Color(0xFF12121A);
  static const Color cardBg = Color(0xFF1A1A26);

  // Neons
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color dimGreen = Color(0xFF1A6B08);
  static const Color pixelYellow = Color(0xFFFFE600);
  static const Color chaosRed = Color(0xFFFF2D55);
  static const Color electricBlue = Color(0xFF00D4FF);
  static const Color pixelPurple = Color(0xFFBF5FFF);
  static const Color warmOrange = Color(0xFFFF6B00);

  // Text
  static const Color lightText = Color(0xFFE8E8F0);
  static const Color dimText = Color(0xFF7A7A96);

  // Canvas UI
  static const Color canvasBg = Color(0xFF050508);
  static const Color gridLine = Color(0xFF1E1E2E);
  static const Color cursorGlow = Color(0xFF39FF14);

  // Scanline overlay alpha
  static const Color scanlineColor = Color(0x0A000000);
}

abstract class RetroTextStyles {
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 11,
    letterSpacing: 1.5,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'PixelifySans',
    fontSize: 14,
    color: RetroColors.dimText,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: 'PixelifySans',
    fontSize: 14,
    color: RetroColors.dimGreen,
  );

  static const TextStyle pixelTitle = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 24,
    color: RetroColors.neonGreen,
    letterSpacing: 3,
    shadows: [
      Shadow(color: RetroColors.neonGreen, blurRadius: 12),
      Shadow(color: RetroColors.neonGreen, blurRadius: 24),
    ],
  );

  static const TextStyle chaosTitle = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 24,
    color: RetroColors.chaosRed,
    letterSpacing: 3,
    shadows: [
      Shadow(color: RetroColors.chaosRed, blurRadius: 12),
      Shadow(color: RetroColors.chaosRed, blurRadius: 24),
    ],
  );
}