import 'package:flutter/material.dart';

/// Light/dark theme tokens (FR-011) expressing an identity that blends
/// "sport intense" (strong contrast, assertive type) and "nature organique"
/// (earthy tones, soft curves) — FR-012. Neither direction is exclusive:
/// the strong-contrast accent color and bold headline weight come from the
/// "sport intense" side, while the earthy neutrals and generously rounded
/// shapes come from the "nature organique" side.
class AppTheme {
  AppTheme._();

  // "Sport intense": a single strong accent for calls to action / progress.
  static const _accent = Color(0xFFE0521B); // burnt orange — high contrast
  // "Nature organique": earthy neutrals instead of a stark black/white.
  static const _earthLight = Color(0xFFF6F1EA);
  static const _earthDark = Color(0xFF231F1B);
  static const _stoneLight = Color(0xFF57534E);
  static const _stoneDark = Color(0xFFD6CFC4);

  // Soft curves: consistent, generous corner radius across components.
  static const BorderRadius radius = BorderRadius.all(Radius.circular(20));

  static ThemeData get light => _base(
        brightness: Brightness.light,
        surface: _earthLight,
        onSurface: Color(0xFF231F1B),
        secondaryText: _stoneLight,
      );

  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        surface: _earthDark,
        onSurface: Color(0xFFF6F1EA),
        secondaryText: _stoneDark,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
    required Color secondaryText,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        // "Sport intense": bold, assertive headlines.
        headlineMedium: const TextStyle(fontWeight: FontWeight.w800),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: secondaryText),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
