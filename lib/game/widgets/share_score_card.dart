import 'package:flutter/material.dart';

import '../../theme/game_theme.dart';
import '../../theme/vault_palette.dart';

/// Offscreen share card — grade / score / combo / track, not the live HUD.
class ShareScoreCard extends StatelessWidget {
  const ShareScoreCard({
    super.key,
    required this.grade,
    required this.score,
    required this.maxCombo,
    required this.accuracy,
    required this.chartTitle,
    this.isDaily = false,
    this.dailyYmd,
  });

  final String grade;
  final int score;
  final int maxCombo;
  final double accuracy;
  final String chartTitle;
  final bool isDaily;
  final String? dailyYmd;

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [v.bgTop, v.bgMid, v.bgDeep],
          ),
          border: Border.all(color: v.gold.withValues(alpha: 0.55), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'POP IT',
              style: vaultLabel(size: 11, color: v.gold, tracking: 0.4),
            ),
            const SizedBox(height: 6),
            if (isDaily)
              Text(
                'DAILY ${dailyYmd ?? ''}',
                style: vaultLabel(size: 10, color: v.cyan),
              ),
            const SizedBox(height: 14),
            Text(
              grade,
              style: vaultDisplay(size: 36, color: v.gold),
            ),
            const SizedBox(height: 10),
            Text(
              '$score',
              style: vaultDisplay(size: 42, color: v.paper),
            ),
            Text(
              'SCORE',
              style: vaultLabel(
                size: 10,
                color: v.paper.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '×$maxCombo  ·  ${(accuracy * 100).round()}%',
              style: vaultLabel(size: 13, color: v.magenta),
            ),
            const SizedBox(height: 10),
            Text(
              chartTitle,
              textAlign: TextAlign.center,
              style: vaultLabel(
                size: 12,
                color: v.paper.withValues(alpha: 0.7),
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
