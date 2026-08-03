import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/game_theme.dart';
import '../models.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.combo,
    required this.judgement,
    required this.judgementToken,
  });

  final int score;
  final int combo;
  final Judgement? judgement;
  final int judgementToken;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(label: 'SCORE', value: '$score'),
        const Spacer(),
        _JudgementBurst(
          key: ValueKey(judgementToken),
          judgement: judgement,
        ),
        const Spacer(),
        _Pill(
          label: 'COMBO',
          value: combo > 0 ? 'x$combo' : '—',
          emphasize: combo >= 10,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            letterSpacing: 1.2,
            color: GameColors.ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: emphasize ? GameColors.candyCoral : GameColors.ink,
          ),
        ),
      ],
    );
  }
}

class _JudgementBurst extends StatelessWidget {
  const _JudgementBurst({super.key, required this.judgement});

  final Judgement? judgement;

  @override
  Widget build(BuildContext context) {
    if (judgement == null) {
      return const SizedBox(width: 110, height: 42);
    }

    final (label, color) = switch (judgement!) {
      Judgement.perfect => ('PERFECT', GameColors.perfect),
      Judgement.good => ('GOOD', GameColors.good),
      Judgement.miss => ('MISS', GameColors.miss),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Text(
        label,
        style: GoogleFonts.fredoka(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: color,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
