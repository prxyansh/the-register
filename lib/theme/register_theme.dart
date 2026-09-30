import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens and theme — "The Register" design direction.
///
/// Visual vocabulary: attendance register (ruled rows, stamps) crossed with
/// split-flap departure board (mono digits, high-legibility readouts).
///
/// Color: ink-on-paper, functional status colors only.
/// Type: IBM Plex Sans (UI) + IBM Plex Mono (data/numbers).
class RegisterTheme {
  RegisterTheme._();

  // ─── Color tokens ──────────────────────────────────────────
  static const Color paper = Color(0xFFF1F2EC);
  static const Color ink = Color(0xFF1B2430);
  static const Color stampBlue = Color(0xFF2F4C7A);
  static const Color present = Color(0xFF2E7D52);
  static const Color absent = Color(0xFFB5482F);
  static const Color ambiguous = Color(0xFFC98A2C);
  static const Color rule = Color(0xFFD8D9CF);

  // Dark mode counterparts
  static const Color paperDark = Color(0xFF1B2430);
  static const Color inkDark = Color(0xFFE8E9E3);
  static const Color stampBlueDark = Color(0xFF6B9BD2);
  static const Color presentDark = Color(0xFF4CAF78);
  static const Color absentDark = Color(0xFFD4735A);
  static const Color ambiguousDark = Color(0xFFDBA94A);
  static const Color ruleDark = Color(0xFF2D3A4A);

  // Subject color palette — 12 vibrant, distinguishable colors
  static const List<Color> subjectColors = [
    Color(0xFF2F4C7A), // Stamp blue
    Color(0xFF0984E3), // Blue
    Color(0xFF00838F), // Teal
    Color(0xFF2E7D52), // Green
    Color(0xFFC98A2C), // Amber
    Color(0xFFB5482F), // Rust
    Color(0xFFE17055), // Orange
    Color(0xFFD63031), // Red
    Color(0xFFE84393), // Pink
    Color(0xFF6C5CE7), // Purple
    Color(0xFF74B9FF), // Sky
    Color(0xFF00B894), // Mint
  ];

  // Day of week labels (ISO 8601: 1=Monday)
  static const List<String> dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const List<String> dayShortNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  // ─── Typography ────────────────────────────────────────────

  /// IBM Plex Sans — all UI text
  static TextStyle _sans({
    double fontSize = 16,
    double height = 1.5,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// IBM Plex Mono — numeric/data readouts
  static TextStyle _mono({
    double fontSize = 16,
    double height = 1.375,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // ─── Type scale ────────────────────────────────────────────

  /// Display: Plex Mono 48/52 Bold — bunk-budget number
  static TextStyle display([Color? color]) => _mono(
        fontSize: 48,
        height: 52,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// H1: Plex Sans 26/32 SemiBold — screen titles
  static TextStyle h1([Color? color]) => _sans(
        fontSize: 26,
        height: 32,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// H2: Plex Sans 19/25 SemiBold — section headers
  static TextStyle h2([Color? color]) => _sans(
        fontSize: 19,
        height: 25,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Body: Plex Sans 16/24 Regular — standard text
  static TextStyle body([Color? color]) => _sans(
        fontSize: 16,
        height: 24,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Body Small: Plex Sans 14/20 Regular — secondary text
  static TextStyle bodySmall([Color? color]) => _sans(
        fontSize: 14,
        height: 20,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Data: Plex Mono 16/22 Medium — times, percentages, scores
  static TextStyle data([Color? color]) => _mono(
        fontSize: 16,
        height: 22,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Caption: Plex Sans 13/18 Medium — metadata, timestamps
  static TextStyle caption([Color? color]) => _sans(
        fontSize: 13,
        height: 18,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ─── Theme builders ────────────────────────────────────────

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.light(
        surface: paper,
        onSurface: ink,
        primary: stampBlue,
        onPrimary: paper,
        secondary: stampBlue,
        onSecondary: paper,
        tertiary: ambiguous,
        error: absent,
        outline: rule,
        outlineVariant: rule,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: h1(ink),
      ),
      dividerTheme: const DividerThemeData(
        color: rule,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paper,
        indicatorColor: stampBlue.withValues(alpha: 0.12),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return caption(stampBlue);
          }
          return caption(ink.withValues(alpha: 0.6));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: stampBlue, size: 22);
          }
          return IconThemeData(color: ink.withValues(alpha: 0.6), size: 22);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: stampBlue,
        foregroundColor: paper,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: rule),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: rule),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: stampBlue, width: 2),
        ),
        labelStyle: bodySmall(ink.withValues(alpha: 0.6)),
      ),
      textTheme: TextTheme(
        headlineLarge: h1(ink),
        headlineMedium: h2(ink),
        titleLarge: h1(ink),
        titleMedium: h2(ink),
        bodyLarge: body(ink),
        bodyMedium: body(ink),
        bodySmall: bodySmall(ink),
        labelLarge: caption(ink),
        labelMedium: caption(ink),
        labelSmall: caption(ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: stampBlue,
          foregroundColor: paper,
          textStyle: body(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: stampBlue,
          textStyle: body(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: bodySmall(paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: paperDark,
      colorScheme: ColorScheme.dark(
        surface: paperDark,
        onSurface: inkDark,
        primary: stampBlueDark,
        onPrimary: paperDark,
        secondary: stampBlueDark,
        onSecondary: paperDark,
        tertiary: ambiguousDark,
        error: absentDark,
        outline: ruleDark,
        outlineVariant: ruleDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paperDark,
        foregroundColor: inkDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: h1(inkDark),
      ),
      dividerTheme: const DividerThemeData(
        color: ruleDark,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: paperDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paperDark,
        indicatorColor: stampBlueDark.withValues(alpha: 0.15),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return caption(stampBlueDark);
          }
          return caption(inkDark.withValues(alpha: 0.6));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: stampBlueDark, size: 22);
          }
          return IconThemeData(color: inkDark.withValues(alpha: 0.6), size: 22);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: stampBlueDark,
        foregroundColor: paperDark,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paperDark,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: ruleDark),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ruleDark),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: stampBlueDark, width: 2),
        ),
        labelStyle: bodySmall(inkDark.withValues(alpha: 0.6)),
      ),
      textTheme: TextTheme(
        headlineLarge: h1(inkDark),
        headlineMedium: h2(inkDark),
        titleLarge: h1(inkDark),
        titleMedium: h2(inkDark),
        bodyLarge: body(inkDark),
        bodyMedium: body(inkDark),
        bodySmall: bodySmall(inkDark),
        labelLarge: caption(inkDark),
        labelMedium: caption(inkDark),
        labelSmall: caption(inkDark),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: stampBlueDark,
          foregroundColor: paperDark,
          textStyle: body(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: stampBlueDark,
          textStyle: body(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inkDark,
        contentTextStyle: bodySmall(paperDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
