import 'package:flutter/material.dart';

import '../models.dart';
import '../../theme/game_theme.dart';
import 'vault_decor.dart';

Future<void> showResultsSheet({
  required BuildContext context,
  required RunResult result,
  required VoidCallback onHome,
  required VoidCallback onReplay,
  VoidCallback? onShare,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: const Border(
            top: BorderSide(color: VaultColors.gold, width: 2),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0C36), VaultColors.plateDeep],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.grade, style: vaultDisplay(size: 28, color: VaultColors.gold)),
            const SizedBox(height: 8),
            Text('SCORE ${result.score}', style: vaultDisplay(size: 22)),
            const SizedBox(height: 6),
            Text(
              'ACC ${(result.accuracy * 100).round()}%  ·  COMBO ${result.maxCombo}  ·  P/G/M ${result.perfect}/${result.good}/${result.miss}',
              textAlign: TextAlign.center,
              style: vaultLabel(
                size: 11,
                color: VaultColors.paper.withValues(alpha: 0.6),
                weight: FontWeight.w400,
              ),
            ),
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
            ),
          ],
        ),
      );
    },
  );
}
