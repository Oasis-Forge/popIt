import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameColors {
  static const candyPink = Color(0xFFFF5C8A);
  static const candyCoral = Color(0xFFFF7A59);
  static const candyMint = Color(0xFF3DDC97);
  static const candySky = Color(0xFF4DB7FF);
  static const candyLilac = Color(0xFFB388FF);
  static const boardBase = Color(0xFFFF8FAB);
  static const boardDeep = Color(0xFFE85A7C);
  static const ink = Color(0xFF2B1B24);
  static const cream = Color(0xFFFFF6F0);
  static const miss = Color(0xFFFF3B5C);
  static const perfect = Color(0xFFFFD166);
  static const good = Color(0xFF7CF5C8);

  static const bubblePalette = [
    candyPink,
    candyCoral,
    candyMint,
    candySky,
    candyLilac,
  ];
}

ThemeData buildPopItTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: GameColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GameColors.candyPink,
      brightness: Brightness.light,
      surface: GameColors.cream,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.fredokaTextTheme(base.textTheme).apply(
      bodyColor: GameColors.ink,
      displayColor: GameColors.ink,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GameColors.candyPink,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
