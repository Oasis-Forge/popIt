import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Disco Vault — the luxury visual system for Pop It.
///
/// Mirror-tile stones set in gold bezels on an aubergine plate, lit by a
/// slow-turning spectrum. Type is Archivo Black for numerals and the
/// wordmark, Space Grotesk for labels.
class VaultColors {
  // Room
  static const bgTop = Color(0xFF3A1148);
  static const bgMid = Color(0xFF1A0722);
  static const bgDeep = Color(0xFF0A0310);

  // Plate
  static const plateTop = Color(0xFF2C0E38);
  static const plateMid = Color(0xFF160620);
  static const plateDeep = Color(0xFF0C0312);

  // Accents
  static const gold = Color(0xFFFFD93D);
  static const magenta = Color(0xFFFF2D95);
  static const violet = Color(0xFFA855F7);
  static const cyan = Color(0xFF7BE3FF);
  static const lime = Color(0xFF8CFF6B);
  static const missRed = Color(0xFFFF3C5A);

  static const ink = Color(0xFF160620);
  static const paper = Color(0xFFF6ECFF);
  static const dimVeil = Color(0xFF10041A);

  /// Bezel metal, light to dark.
  static const bezel = [Color(0xFFFFF6C9), Color(0xFFE0A83D), Color(0xFF6B4A0F)];

  /// The turning spectrum used for blooms, rings and progress.
  static const spectrum = [cyan, magenta, gold, lime, violet, cyan];

  /// One tint triplet per board column: highlight, body, shadow.
  static const stones = <List<Color>>[
    [Color(0xFFFFFFFF), Color(0xFFC9F0FF), Color(0xFF3E86B8)],
    [Color(0xFFFFFFFF), Color(0xFFFFD9F2), Color(0xFFB4468C)],
    [Color(0xFFFFFFFF), Color(0xFFFFF3C4), Color(0xFFB88C1F)],
    [Color(0xFFFFFFFF), Color(0xFFD9FFE8), Color(0xFF2A9269)],
    [Color(0xFFFFFFFF), Color(0xFFE4D9FF), Color(0xFF5C42AD)],
  ];

  static const roomGradient = RadialGradient(
    center: Alignment(0, -0.9),
    radius: 1.2,
    colors: [bgTop, bgMid, bgDeep],
    stops: [0.0, 0.55, 1.0],
  );

  static const plateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [plateTop, plateMid, plateDeep],
    stops: [0.0, 0.62, 1.0],
  );

  static const wordmarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFE6C9FF),
      violet,
      magenta,
      gold,
    ],
    stops: [0.06, 0.34, 0.52, 0.74, 1.0],
  );

  static const scoreGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), gold, magenta],
    stops: [0.0, 0.55, 1.0],
  );

  static const ctaGradient = LinearGradient(
    begin: Alignment(-1, -0.2),
    end: Alignment(1, 0.2),
    colors: [gold, magenta, violet],
    stops: [0.0, 0.52, 1.0],
  );
}

/// Display numerals + wordmark.
TextStyle vaultDisplay({
  required double size,
  Color color = VaultColors.paper,
  double letterSpacing = 0,
  double height = 1,
}) =>
    GoogleFonts.archivoBlack(
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

/// Labels, meta, tracked small caps.
TextStyle vaultLabel({
  required double size,
  Color color = VaultColors.paper,
  FontWeight weight = FontWeight.w500,
  double tracking = 0.28,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: size * tracking,
    );

ThemeData buildPopItTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: VaultColors.bgDeep,
    colorScheme: ColorScheme.fromSeed(
      seedColor: VaultColors.violet,
      brightness: Brightness.dark,
      surface: VaultColors.bgDeep,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: VaultColors.paper,
      displayColor: VaultColors.paper,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VaultColors.gold,
        foregroundColor: VaultColors.ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.archivoBlack(fontSize: 15, letterSpacing: 3.6),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VaultColors.paper.withValues(alpha: 0.75),
        side: BorderSide(color: VaultColors.paper.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.1,
        ),
      ),
    ),
  );
}
