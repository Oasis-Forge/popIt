import 'package:flutter/material.dart';

import '../../data/theme_unlocks.dart';
import '../../services/versus_service.dart';
import '../../theme/game_theme.dart';
import '../../theme/vault_palette.dart';
import '../models.dart';
import 'vault_decor.dart';

class ResultsMeta {
  const ResultsMeta({
    this.isNewBest = false,
    this.previousBestScore,
    this.scoreDelta,
    this.unlockProgress,
    this.newlyUnlocked = const [],
    this.versusRanking,
    this.footerHint,
    this.onDaily,
    this.onHarder,
    this.onTryNext,
    this.tryNextLabel,
  });

  final bool isNewBest;
  final int? previousBestScore;
  final int? scoreDelta;
  final UnlockProgress? unlockProgress;
  final List<ThemeUnlockInfo> newlyUnlocked;
  final List<VersusPlayerState>? versusRanking;
  final String? footerHint;
  final VoidCallback? onDaily;
  final VoidCallback? onHarder;
  final VoidCallback? onTryNext;
  final String? tryNextLabel;
}

Future<void> showResultsSheet({
  required BuildContext context,
  required RunResult result,
  required VoidCallback onHome,
  VoidCallback? onReplay,
  VoidCallback? onShare,
  ResultsMeta meta = const ResultsMeta(),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final v = context.vault;
      final hasSecondary = meta.onDaily != null ||
          meta.onHarder != null ||
          meta.onTryNext != null;
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: v.gold, width: 2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [v.plateTop, v.plateDeep],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          22,
          24,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(result.grade, style: vaultDisplay(size: 28, color: v.gold)),
              const SizedBox(height: 8),
              Text('SCORE ${result.score}', style: vaultDisplay(size: 22)),
              if (meta.isNewBest) ...[
                const SizedBox(height: 8),
                Text(
                  meta.scoreDelta != null && meta.scoreDelta! > 0
                      ? 'NEW BEST  ·  +${meta.scoreDelta}'
                      : 'NEW BEST',
                  style: vaultLabel(size: 12, color: v.lime),
                ),
              ] else if (meta.previousBestScore != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Best ${meta.previousBestScore}'
                  '${meta.scoreDelta != null ? '  ·  ${meta.scoreDelta! >= 0 ? '+' : ''}${meta.scoreDelta}' : ''}',
                  style: vaultLabel(
                    size: 11,
                    color: v.paper.withValues(alpha: 0.55),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'ACC ${(result.accuracy * 100).round()}%  ·  COMBO ${result.maxCombo}  ·  P/G/M ${result.perfect}/${result.good}/${result.miss}',
                textAlign: TextAlign.center,
                style: vaultLabel(
                  size: 11,
                  color: v.paper.withValues(alpha: 0.6),
                  weight: FontWeight.w400,
                ),
              ),
              if (meta.footerHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  meta.footerHint!,
                  textAlign: TextAlign.center,
                  style: vaultLabel(
                    size: 12,
                    color: v.cyan,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
              if (meta.newlyUnlocked.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final u in meta.newlyUnlocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Unlocked ${u.name}',
                      style: vaultLabel(size: 12, color: v.cyan),
                    ),
                  ),
              ],
              if (meta.unlockProgress != null) ...[
                const SizedBox(height: 14),
                _UnlockProgressRow(progress: meta.unlockProgress!),
              ],
              if (meta.versusRanking != null &&
                  meta.versusRanking!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('PODIUM', style: vaultLabel(size: 11, color: v.gold)),
                const SizedBox(height: 8),
                for (var i = 0; i < meta.versusRanking!.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '#${i + 1}',
                            style: vaultLabel(
                              size: 12,
                              color: i == 0
                                  ? v.gold
                                  : v.paper.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            meta.versusRanking![i].displayName,
                            style: vaultLabel(
                              size: 12,
                              color: meta.versusRanking![i].isLocal
                                  ? v.cyan
                                  : v.paper,
                            ),
                          ),
                        ),
                        Text(
                          '${meta.versusRanking![i].score}',
                          style: vaultLabel(size: 12, color: v.paper),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onHome,
                      child: const Text('HOME'),
                    ),
                  ),
                  if (onShare != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onShare,
                        child: const Text('SHARE'),
                      ),
                    ),
                  ],
                  if (onReplay != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: VaultCta(
                        label: 'AGAIN',
                        fontSize: 13,
                        verticalPadding: 17,
                        onPressed: onReplay,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasSecondary) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (meta.onDaily != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: meta.onDaily,
                          child: const Text('DAILY'),
                        ),
                      ),
                    if (meta.onDaily != null &&
                        (meta.onHarder != null || meta.onTryNext != null))
                      const SizedBox(width: 8),
                    if (meta.onHarder != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: meta.onHarder,
                          child: const Text('HARDER'),
                        ),
                      ),
                    if (meta.onHarder != null && meta.onTryNext != null)
                      const SizedBox(width: 8),
                    if (meta.onTryNext != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: meta.onTryNext,
                          child: Text(meta.tryNextLabel ?? 'TRY NEXT'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _UnlockProgressRow extends StatelessWidget {
  const _UnlockProgressRow({required this.progress});

  final UnlockProgress progress;

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    final done = progress.current >= progress.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          done
              ? '${progress.themeName} ready'
              : '${progress.themeName}: ${progress.current}/${progress.target} ${progress.label}',
          textAlign: TextAlign.center,
          style: vaultLabel(
            size: 11,
            color: v.paper.withValues(alpha: 0.7),
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 6,
            backgroundColor: v.paper.withValues(alpha: 0.12),
            color: v.magenta,
          ),
        ),
      ],
    );
  }
}
