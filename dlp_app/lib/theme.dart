import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kSeed = Color(0xFF0F6E56);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kSeed);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0x1F000000)),
      ),
      margin: EdgeInsets.zero,
    ),
  );
}

/// Colour for a result band chip (Distinction/Pass/Fail/Withdrawn).
Color resultColor(String result, ColorScheme scheme) => switch (result) {
      'Distinction' => const Color(0xFF0F6E56),
      'Pass' => const Color(0xFF185FA5),
      'Fail' => const Color(0xFFA32D2D),
      _ => const Color(0xFF854F0B),
    };
