import 'package:flutter/material.dart';

import 'vault_palette.dart';

/// Disco Vault defaults. Prefer [BuildContext.vault] for themed screens.
class VaultColors {
  static const bgTop = Color(0xFF3A1148);
  static const bgMid = Color(0xFF1A0722);
  static const bgDeep = Color(0xFF0A0310);
  static const plateTop = Color(0xFF2C0E38);
  static const plateMid = Color(0xFF160620);
  static const plateDeep = Color(0xFF0C0312);
  static const gold = Color(0xFFFFD93D);
  static const magenta = Color(0xFFFF2D95);
  static const violet = Color(0xFFA855F7);
  static const cyan = Color(0xFF7BE3FF);
  static const lime = Color(0xFF8CFF6B);
  static const missRed = Color(0xFFFF3C5A);
  static const ink = Color(0xFF160620);
  static const paper = Color(0xFFF6ECFF);
  static const dimVeil = Color(0xFF10041A);
  static const bezel = [Color(0xFFFFF6C9), Color(0xFFE0A83D), Color(0xFF6B4A0F)];
  static const spectrum = [cyan, magenta, gold, lime, violet, cyan];
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
    colors: [Color(0xFFFFFFFF), paper, violet, magenta, gold],
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

TextStyle vaultDisplay({
  required double size,
  Color color = VaultColors.paper,
  double letterSpacing = 0,
  double height = 1,
}) =>
    TextStyle(
      fontFamily: 'ArchivoBlack',
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle vaultLabel({
  required double size,
  Color color = VaultColors.paper,
  FontWeight weight = FontWeight.w500,
  double tracking = 0.28,
}) =>
    TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: size * tracking,
    );

ThemeData buildPopItTheme({VaultPalette palette = VaultPalette.discoVault}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: palette.bgDeep,
    fontFamily: 'SpaceGrotesk',
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.violet,
      brightness: Brightness.dark,
      surface: palette.bgDeep,
    ),
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[palette],
    textTheme: base.textTheme.apply(
      bodyColor: palette.paper,
      displayColor: palette.paper,
      fontFamily: 'SpaceGrotesk',
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.gold,
        foregroundColor: palette.ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'ArchivoBlack',
          fontSize: 15,
          letterSpacing: 3.6,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.paper.withValues(alpha: 0.75),
        side: BorderSide(color: palette.paper.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.1,
        ),
      ),
    ),
  );
}
