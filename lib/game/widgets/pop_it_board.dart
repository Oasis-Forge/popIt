import 'package:flutter/material.dart';

import '../../theme/game_theme.dart';
import 'bubble.dart';

/// The vault plate: aubergine lacquer, hairline gold rim, 4x5 stones.
class PopItBoard extends StatelessWidget {
  const PopItBoard({
    super.key,
    required this.rows,
    required this.cols,
    required this.stateForBubble,
    required this.onBubbleTap,
    this.dimIdle = true,
  });

  final int rows;
  final int cols;
  final BubbleVisualState Function(int bubbleId) stateForBubble;
  final void Function(int bubbleId) onBubbleTap;
  final bool dimIdle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: cols / rows,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: VaultColors.plateGradient,
          border: Border.all(
            color: VaultColors.gold.withValues(alpha: 0.34),
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
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(1),
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
