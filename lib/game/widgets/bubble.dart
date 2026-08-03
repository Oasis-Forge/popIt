import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/game_theme.dart';

enum BubbleVisualState { idle, cued, popped, miss }

class PopBubble extends StatefulWidget {
  const PopBubble({
    super.key,
    required this.bubbleId,
    required this.color,
    required this.state,
    required this.onTap,
  });

  final int bubbleId;
  final Color color;
  final BubbleVisualState state;
  final VoidCallback onTap;

  @override
  State<PopBubble> createState() => _PopBubbleState();
}

class _PopBubbleState extends State<PopBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant PopBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == BubbleVisualState.cued) {
      if (!_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      }
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popped = widget.state == BubbleVisualState.popped;
    final miss = widget.state == BubbleVisualState.miss;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final cueScale = widget.state == BubbleVisualState.cued
              ? 1.0 + (_pulse.value * 0.08)
              : 1.0;
          final popScale = popped ? 0.88 : 1.0;
          return Transform.scale(
            scale: cueScale * popScale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: miss
                ? GameColors.miss.withValues(alpha: 0.85)
                : widget.color,
            boxShadow: [
              if (!popped)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  offset: const Offset(0, 6),
                  blurRadius: 8,
                ),
              if (widget.state == BubbleVisualState.cued)
                BoxShadow(
                  color: GameColors.perfect.withValues(alpha: 0.85),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
            gradient: popped
                ? null
                : RadialGradient(
                    center: const Alignment(-0.35, -0.4),
                    radius: 0.95,
                    colors: [
                      Color.lerp(widget.color, Colors.white, 0.35)!,
                      widget.color,
                      Color.lerp(widget.color, Colors.black, 0.12)!,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: EdgeInsets.all(popped ? 10 : 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: popped
                  ? Color.lerp(widget.color, Colors.black, 0.22)
                  : Colors.transparent,
              boxShadow: popped
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
