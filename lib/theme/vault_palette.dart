import 'package:flutter/material.dart';

@immutable
class VaultPalette extends ThemeExtension<VaultPalette> {
  const VaultPalette({
    required this.id,
    required this.name,
    required this.locked,
    required this.bgTop,
    required this.bgMid,
    required this.bgDeep,
    required this.plateTop,
    required this.plateMid,
    required this.plateDeep,
    required this.gold,
    required this.magenta,
    required this.violet,
    required this.cyan,
    required this.lime,
    required this.missRed,
    required this.ink,
    required this.paper,
    required this.dimVeil,
  });

  final String id;
  final String name;
  final bool locked;
  final Color bgTop;
  final Color bgMid;
  final Color bgDeep;
  final Color plateTop;
  final Color plateMid;
  final Color plateDeep;
  final Color gold;
  final Color magenta;
  final Color violet;
  final Color cyan;
  final Color lime;
  final Color missRed;
  final Color ink;
  final Color paper;
  final Color dimVeil;

  RadialGradient get roomGradient => RadialGradient(
        center: const Alignment(0, -0.9),
        radius: 1.2,
        colors: [bgTop, bgMid, bgDeep],
        stops: const [0.0, 0.55, 1.0],
      );

  LinearGradient get plateGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [plateTop, plateMid, plateDeep],
        stops: const [0.0, 0.62, 1.0],
      );

  LinearGradient get wordmarkGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFFFFF), paper, violet, magenta, gold],
        stops: const [0.06, 0.34, 0.52, 0.74, 1.0],
      );

  LinearGradient get scoreGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFFFFF), gold, magenta],
        stops: const [0.0, 0.55, 1.0],
      );

  LinearGradient get ctaGradient => LinearGradient(
        begin: const Alignment(-1, -0.2),
        end: const Alignment(1, 0.2),
        colors: [gold, magenta, violet],
        stops: const [0.0, 0.52, 1.0],
      );

  List<Color> get spectrum => [cyan, magenta, gold, lime, violet, cyan];

  static const discoVault = VaultPalette(
    id: 'disco_vault',
    name: 'Disco Vault',
    locked: false,
    bgTop: Color(0xFF3A1148),
    bgMid: Color(0xFF1A0722),
    bgDeep: Color(0xFF0A0310),
    plateTop: Color(0xFF2C0E38),
    plateMid: Color(0xFF160620),
    plateDeep: Color(0xFF0C0312),
    gold: Color(0xFFFFD93D),
    magenta: Color(0xFFFF2D95),
    violet: Color(0xFFA855F7),
    cyan: Color(0xFF7BE3FF),
    lime: Color(0xFF8CFF6B),
    missRed: Color(0xFFFF3C5A),
    ink: Color(0xFF160620),
    paper: Color(0xFFF6ECFF),
    dimVeil: Color(0xFF10041A),
  );

  static const neonArcade = VaultPalette(
    id: 'neon_arcade',
    name: 'Neon Arcade',
    locked: false,
    bgTop: Color(0xFF1B1040),
    bgMid: Color(0xFF0C0824),
    bgDeep: Color(0xFF050312),
    plateTop: Color(0xFF24145A),
    plateMid: Color(0xFF120A32),
    plateDeep: Color(0xFF08041A),
    gold: Color(0xFFFFF36A),
    magenta: Color(0xFFFF4DF0),
    violet: Color(0xFF7A5CFF),
    cyan: Color(0xFF4DFFF3),
    lime: Color(0xFFB8FF4D),
    missRed: Color(0xFFFF4D6D),
    ink: Color(0xFF0A0418),
    paper: Color(0xFFF3F0FF),
    dimVeil: Color(0xFF0A0618),
  );

  static const auroraIce = VaultPalette(
    id: 'aurora_ice',
    name: 'Aurora Ice',
    locked: true,
    bgTop: Color(0xFF163A4A),
    bgMid: Color(0xFF0B1E2A),
    bgDeep: Color(0xFF040E16),
    plateTop: Color(0xFF1E4A5C),
    plateMid: Color(0xFF0F2734),
    plateDeep: Color(0xFF07141C),
    gold: Color(0xFFE8F7FF),
    magenta: Color(0xFF7AD7FF),
    violet: Color(0xFF6B8CFF),
    cyan: Color(0xFF9EFFF2),
    lime: Color(0xFFB8FFE0),
    missRed: Color(0xFFFF6B8A),
    ink: Color(0xFF07141C),
    paper: Color(0xFFEFF9FF),
    dimVeil: Color(0xFF061018),
  );

  static const sunsetBakery = VaultPalette(
    id: 'sunset_bakery',
    name: 'Sunset Bakery',
    locked: true,
    bgTop: Color(0xFF5A2A1C),
    bgMid: Color(0xFF2E140C),
    bgDeep: Color(0xFF140805),
    plateTop: Color(0xFF6E3420),
    plateMid: Color(0xFF3A1A10),
    plateDeep: Color(0xFF1A0C08),
    gold: Color(0xFFFFC857),
    magenta: Color(0xFFFF6B4A),
    violet: Color(0xFFD45D9A),
    cyan: Color(0xFFFFD6A5),
    lime: Color(0xFFFFE08A),
    missRed: Color(0xFFFF3B3B),
    ink: Color(0xFF1A0C08),
    paper: Color(0xFFFFF4E8),
    dimVeil: Color(0xFF140806),
  );

  static const midnightMono = VaultPalette(
    id: 'midnight_mono',
    name: 'Midnight Mono',
    locked: true,
    bgTop: Color(0xFF2A2A2E),
    bgMid: Color(0xFF141416),
    bgDeep: Color(0xFF070708),
    plateTop: Color(0xFF333338),
    plateMid: Color(0xFF1A1A1E),
    plateDeep: Color(0xFF0C0C0E),
    gold: Color(0xFFE8E8EC),
    magenta: Color(0xFFB0B0B8),
    violet: Color(0xFF8A8A94),
    cyan: Color(0xFFD0D0D6),
    lime: Color(0xFFC8C8CE),
    missRed: Color(0xFFFF5A5A),
    ink: Color(0xFF0C0C0E),
    paper: Color(0xFFF2F2F5),
    dimVeil: Color(0xFF101012),
  );

  static const all = <VaultPalette>[
    discoVault,
    neonArcade,
    auroraIce,
    sunsetBakery,
    midnightMono,
  ];

  static VaultPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => discoVault);

  @override
  VaultPalette copyWith({
    String? id,
    String? name,
    bool? locked,
    Color? bgTop,
    Color? bgMid,
    Color? bgDeep,
    Color? plateTop,
    Color? plateMid,
    Color? plateDeep,
    Color? gold,
    Color? magenta,
    Color? violet,
    Color? cyan,
    Color? lime,
    Color? missRed,
    Color? ink,
    Color? paper,
    Color? dimVeil,
  }) {
    return VaultPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      locked: locked ?? this.locked,
      bgTop: bgTop ?? this.bgTop,
      bgMid: bgMid ?? this.bgMid,
      bgDeep: bgDeep ?? this.bgDeep,
      plateTop: plateTop ?? this.plateTop,
      plateMid: plateMid ?? this.plateMid,
      plateDeep: plateDeep ?? this.plateDeep,
      gold: gold ?? this.gold,
      magenta: magenta ?? this.magenta,
      violet: violet ?? this.violet,
      cyan: cyan ?? this.cyan,
      lime: lime ?? this.lime,
      missRed: missRed ?? this.missRed,
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      dimVeil: dimVeil ?? this.dimVeil,
    );
  }

  @override
  VaultPalette lerp(ThemeExtension<VaultPalette>? other, double t) {
    if (other is! VaultPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VaultPalette(
      id: t < 0.5 ? id : other.id,
      name: t < 0.5 ? name : other.name,
      locked: t < 0.5 ? locked : other.locked,
      bgTop: l(bgTop, other.bgTop),
      bgMid: l(bgMid, other.bgMid),
      bgDeep: l(bgDeep, other.bgDeep),
      plateTop: l(plateTop, other.plateTop),
      plateMid: l(plateMid, other.plateMid),
      plateDeep: l(plateDeep, other.plateDeep),
      gold: l(gold, other.gold),
      magenta: l(magenta, other.magenta),
      violet: l(violet, other.violet),
      cyan: l(cyan, other.cyan),
      lime: l(lime, other.lime),
      missRed: l(missRed, other.missRed),
      ink: l(ink, other.ink),
      paper: l(paper, other.paper),
      dimVeil: l(dimVeil, other.dimVeil),
    );
  }
}

extension VaultPaletteX on BuildContext {
  VaultPalette get vault =>
      Theme.of(this).extension<VaultPalette>() ?? VaultPalette.discoVault;
}
