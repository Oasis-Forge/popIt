import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../theme/game_theme.dart';
import '../../theme/vault_palette.dart';
import 'bubble.dart';

/// The vault plate: aubergine lacquer, hairline gold rim, grid of stones.
class PopItBoard extends StatelessWidget {
  const PopItBoard({
    super.key,
    required this.rows,
    required this.cols,
    required this.stateForBubble,
    required this.onBubbleTap,
    this.dimIdle = true,
    this.boardScale = BoardScale.standard,
  });

  final int rows;
  final int cols;
  final BubbleVisualState Function(int bubbleId) stateForBubble;
  final void Function(int bubbleId) onBubbleTap;
  final bool dimIdle;
  final BoardScale boardScale;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<VaultPalette>() ?? VaultPalette.discoVault;
    final platePad = switch (boardScale) {
      BoardScale.compact => 10.0,
      BoardScale.standard => 14.0,
      BoardScale.chunky => 18.0,
    };
    final bubblePad = switch (boardScale) {
      BoardScale.compact => 0.5,
      BoardScale.standard => 1.0,
      BoardScale.chunky => 2.0,
    };

    return AspectRatio(
      aspectRatio: cols / rows,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: palette.plateGradient,
          border: Border.all(
            color: palette.gold.withValues(alpha: 0.34),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 54,
              offset: const Offset(0, 26),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(platePad),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(bubblePad),
                            child: PopBubble(
                              bubbleId: r * cols + c,
                              tints: VaultColors
                                  .stones[c % VaultColors.stones.length],
                              state: stateForBubble(r * cols + c),
                              onTap: () => onBubbleTap(r * cols + c),
                              dimIdle: dimIdle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
