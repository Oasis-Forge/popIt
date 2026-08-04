import 'package:flutter/material.dart';

import '../../theme/game_theme.dart';
import '../models.dart';

/// Score / combo / accuracy cards.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.combo,
    required this.accuracy,
  });

  final int score;
  final int combo;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'SCORE',
            value: '$score',
            valueColor: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'COMBO',
            value: combo > 0 ? '\u00d7$combo' : '—',
            valueColor: VaultColors.gold,
            emphasize: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'ACC',
            value: '${(accuracy * 100).round()}%',
            valueColor: VaultColors.lime,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: emphasize
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VaultColors.magenta.withValues(alpha: 0.22),
                  VaultColors.violet.withValues(alpha: 0.16),
                ],
              )
            : null,
        color: emphasize ? null : VaultColors.paper.withValues(alpha: 0.06),
        border: Border.all(
          color: emphasize
              ? VaultColors.magenta.withValues(alpha: 0.38)
              : VaultColors.paper.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: vaultLabel(
              size: 8.5,
              color: VaultColors.paper.withValues(alpha: 0.45),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            style: vaultDisplay(size: 26, color: valueColor, height: 1.15),
          ),
        ],
      ),
    );
  }
}

/// Early / late offset of the last hit.
class TimingBar extends StatelessWidget {
  const TimingBar({super.key, required this.deltaMs, required this.visible});

  final int deltaMs;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final t = (deltaMs / RhythmTiming.goodWindowMs).clamp(-1.0, 1.0);
    final labelStyle = vaultLabel(
      size: 8.5,
      color: VaultColors.paper.withValues(alpha: 0.35),
      tracking: 0.2,
    );

    return Row(
      children: [
        Text('EARLY', style: labelStyle),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: [
                        VaultColors.cyan.withValues(alpha: 0.25),
                        VaultColors.gold.withValues(alpha: 0.55),
                        VaultColors.magenta.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
                Container(width: 2, height: 16, color: Colors.white),
                AnimatedAlign(
                  alignment: Alignment(t, 0),
                  duration: const Duration(milliseconds: 110),
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: VaultColors.gold.withValues(alpha: 0.85),
                            blurRadius: 14,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('LATE', style: labelStyle),
      ],
    );
  }
}

/// PERFECT / GOOD / MISS plus the millisecond offset.
class JudgementLine extends StatelessWidget {
  const JudgementLine({
    super.key,
    required this.judgement,
    required this.deltaMs,
    required this.judgementToken,
  });

  final Judgement? judgement;
  final int deltaMs;
  final int judgementToken;

  @override
  Widget build(BuildContext context) {
    if (judgement == null) return const SizedBox(height: 30);

    final (label, color) = switch (judgement!) {
      Judgement.perfect => ('PERFECT', VaultColors.cyan),
      Judgement.good => ('GOOD', VaultColors.gold),
      Judgement.miss => ('MISS', VaultColors.missRed),
    };

    return SizedBox(
      height: 30,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(judgementToken),
        tween: Tween(begin: 0.8, end: 1),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: vaultDisplay(size: 22, color: color, letterSpacing: 3.1)
                  .copyWith(
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.7), blurRadius: 18),
                ],
              ),
            ),
            if (judgement != Judgement.miss) ...[
              const SizedBox(width: 8),
              Text(
                '${deltaMs > 0 ? '+' : ''}$deltaMs MS',
                style: vaultLabel(
                  size: 11,
                  color: VaultColors.paper.withValues(alpha: 0.5),
                  tracking: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
