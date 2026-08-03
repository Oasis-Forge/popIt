import 'package:flutter/material.dart';

import '../../theme/game_theme.dart';
import 'bubble.dart';

class PopItBoard extends StatelessWidget {
  const PopItBoard({
    super.key,
    required this.rows,
    required this.cols,
    required this.stateForBubble,
    required this.onBubbleTap,
  });

  final int rows;
  final int cols;
  final BubbleVisualState Function(int bubbleId) stateForBubble;
  final void Function(int bubbleId) onBubbleTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: cols / rows,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GameColors.boardBase, GameColors.boardDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.boardDeep.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: PopBubble(
                              bubbleId: r * cols + c,
                              color: GameColors.bubblePalette[c %
                                  GameColors.bubblePalette.length],
                              state: stateForBubble(r * cols + c),
                              onTap: () => onBubbleTap(r * cols + c),
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
