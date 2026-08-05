import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/game_theme.dart';
import '../../theme/vault_palette.dart';

enum BubbleVisualState { idle, cued, popped, miss }

/// A mirror-tile stone set in a gold bezel.
///
/// Idle stones sit under a dark veil so the cued stone reads instantly: it
/// un-dims, scales up 14% and gains a pulsing gold ring plus a warm bloom.
class PopBubble extends StatefulWidget {
  const PopBubble({
    super.key,
    required this.bubbleId,
    required this.tints,
    required this.state,
    required this.onTap,
    this.dimIdle = true,
    this.cueProgress,
    this.precisionMode = false,
  });

  final int bubbleId;

  /// Highlight / body / shadow, from [VaultColors.stones].
  final List<Color> tints;
  final BubbleVisualState state;
  final VoidCallback onTap;
  final bool dimIdle;

  /// 0 → cue start, 1 → on the beat. Drives approach ring when cued.
  final double? cueProgress;
  final bool precisionMode;

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
      duration: const Duration(milliseconds: 425),
    );
  }

  @override
  void didUpdateWidget(covariant PopBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == BubbleVisualState.cued) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
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

  List<Color> _pressedTints({required double darken}) {
    return [
      for (final c in widget.tints) Color.lerp(c, const Color(0xFF1A0A14), darken)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vault;
    final cued = widget.state == BubbleVisualState.cued;
    final popped = widget.state == BubbleVisualState.popped;
    final miss = widget.state == BubbleVisualState.miss;
    final pressed = popped || miss;

    // Keep the stone's own hue when pressed — just sink it deeper.
    final stoneTints = miss
        ? _pressedTints(darken: 0.55)
        : popped
            ? _pressedTints(darken: 0.42)
            : widget.tints;

    final veil = cued
        ? 0.0
        : pressed
            ? 0.48
            : (widget.dimIdle ? 0.62 : 0.12);
    final scale = cued
        ? 1.14
        : pressed
            ? 0.78
            : 1.0;
    final facetOpacity = cued
        ? 0.95
        : pressed
            ? 0.08
            : 0.32;
    final glossAlpha = pressed ? 0.12 : 0.5;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Warm bloom behind a cued stone.
          AnimatedOpacity(
            opacity: cued ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: FractionallySizedBox(
              widthFactor: 1.12,
              child: AspectRatio(
                aspectRatio: 1,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.gold.withValues(alpha: 0.85),
                          palette.magenta.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.46, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bezel + stone.
          FractionallySizedBox(
            widthFactor: 0.78,
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: VaultColors.bezel,
                      stops: [0.0, 0.48, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: pressed ? 0.25 : 0.6),
                        offset: Offset(0, pressed ? 1 : 4),
                        blurRadius: pressed ? 3 : 9,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: pressed
                                  ? const Alignment(0.2, 0.25)
                                  : const Alignment(-0.32, -0.48),
                              radius: 0.95,
                              colors: stoneTints,
                              stops: const [0.0, 0.44, 1.0],
                            ),
                          ),
                        ),
                        // Inner well shadow when pressed in.
                        if (pressed)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.85,
                                colors: [
                                  Colors.transparent,
                                  Color.lerp(
                                    widget.tints.last,
                                    Colors.black,
                                    0.65,
                                  )!.withValues(alpha: 0.55),
                                ],
                                stops: const [0.35, 1.0],
                              ),
                            ),
                          ),
                        // Mirror facets.
                        AnimatedOpacity(
                          opacity: facetOpacity,
                          duration: const Duration(milliseconds: 120),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xD9FFFFFF),
                                  const Color(0x00FFFFFF),
                                  palette.magenta.withValues(alpha: 0.55),
                                  const Color(0x00FFFFFF),
                                  palette.cyan.withValues(alpha: 0.6),
                                  const Color(0x00FFFFFF),
                                  palette.gold.withValues(alpha: 0.6),
                                  const Color(0x00FFFFFF),
                                ],
                                stops: const [
                                  0.0,
                                  0.09,
                                  0.2,
                                  0.32,
                                  0.45,
                                  0.57,
                                  0.7,
                                  0.83,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Top gloss.
                        Align(
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            heightFactor: 0.44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: glossAlpha),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Idle / pressed veil (hue-preserving, never red).
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          color: Color.lerp(
                            widget.tints[1],
                            palette.dimVeil,
                            0.7,
                          )!.withValues(alpha: veil),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Pulsing cue ring + approach fill toward the beat.
          if (cued)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Transform.scale(
                scale: 1 + _pulse.value * 0.14,
                child: child,
              ),
              child: FractionallySizedBox(
                widthFactor: 0.96,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _CueRingPainter(
                      progress: (widget.cueProgress ?? 0.5).clamp(0.0, 1.0),
                      color: widget.precisionMode ? palette.gold : palette.gold,
                      accent: widget.precisionMode
                          ? palette.gold
                          : palette.cyan,
                      precision: widget.precisionMode,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CueRingPainter extends CustomPainter {
  _CueRingPainter({
    required this.progress,
    required this.color,
    required this.accent,
    required this.precision,
  });

  final double progress;
  final Color color;
  final Color accent;
  final bool precision;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = precision ? 3.5 : 3;
    canvas.drawCircle(center, radius, track);

    final sweep = progress * 6.283185307179586;
    final arc = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = precision ? 4 : 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      sweep,
      false,
      arc,
    );

    final glow = Paint()
      ..color = accent.withValues(alpha: 0.55 + 0.35 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      sweep,
      false,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _CueRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.accent != accent ||
      oldDelegate.precision != precision;
}
