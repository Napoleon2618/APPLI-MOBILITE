import 'package:flutter/material.dart';

/// Light/dark theme tokens (FR-011) expressing an identity that blends
/// "sport intense" (strong contrast, assertive type) and "nature organique"
/// (earthy tones, soft curves) — FR-012. Neither direction is exclusive:
/// the strong-contrast accent color and bold headline weight come from the
/// "sport intense" side, while the organic neutrals and generously rounded
/// shapes come from the "nature organique" side.
///
/// Brand palette (THERAFORMY): the identity is dominated by the brand's
/// teal (used to seed the whole Material color scheme — surfaces,
/// containers, links) and navy "ink" (dark text / dark-mode base). A muted
/// warm terracotta is reserved for exactly two things — primary action
/// buttons and progress indicators — so it draws the eye to what's
/// actionable without competing with the teal identity anywhere else
/// (no warm backgrounds or large fill areas).
class AppTheme {
  AppTheme._();

  // Dominant identity color — seeds the whole scheme (surfaces, containers,
  // links, tertiary tones all derive from this).
  static const _dominant = Color(0xFF31848C); // THERAFORMY teal
  // THERAFORMY navy — the brand's dark/"ink" color (from the logo); used as
  // dark text on the light theme and as the base surface for the dark
  // theme, so it anchors both ends of the palette.
  static const _ink = Color(0xFF1A2D3B);
  // Punctual accent — ONLY for primary action buttons and progress
  // indicators (never backgrounds or large fills), so the dominant teal
  // identity isn't diluted. Muted terracotta rather than a saturated
  // orange: it sits close to teal's true complementary hue (~186° vs.
  // ~18° here, near the ~6° complement) so it reads as "the thing to tap"
  // without turning into a second competing brand color.
  static const _actionAccent = Color(0xFFC97D5D);
  // "Nature organique": an organic light neutral instead of a stark white.
  static const _earthLight = Color(0xFFF6F1EA);
  static const _stoneLight = Color(0xFF57534E);
  static const _stoneDark = Color(0xFFD6CFC4);

  // Soft curves: consistent, generous corner radius across components.
  static const BorderRadius radius = BorderRadius.all(Radius.circular(20));

  static ThemeData get light => _base(
        brightness: Brightness.light,
        surface: _earthLight,
        onSurface: _ink,
        secondaryText: _stoneLight,
      );

  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        surface: _ink,
        onSurface: _earthLight,
        secondaryText: _stoneDark,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
    required Color secondaryText,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _dominant,
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
          backgroundColor: _actionAccent,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      // Progress indicators are the other place the punctual accent
      // appears (session progress bar, loading spinners) — everything else
      // stays within the teal-seeded scheme.
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _actionAccent),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
