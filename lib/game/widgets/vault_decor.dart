import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/game_theme.dart';
import '../../theme/vault_palette.dart';

/// A slowly rotating, heavily blurred spectrum disc — the light source of the
/// whole design. Used behind the wordmark and behind cued stones.
class SpectrumBloom extends StatefulWidget {
  const SpectrumBloom({
    super.key,
    this.size = 380,
    this.blur = 52,
    this.opacity = 0.5,
    this.period = const Duration(seconds: 12),
  });

  final double size;
  final double blur;
  final double opacity;
  final Duration period;

  @override
  State<SpectrumBloom> createState() => _SpectrumBloomState();
}

class _SpectrumBloomState extends State<SpectrumBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spectrum = context.vault.spectrum;
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: RotationTransition(
            turns: _spin,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: spectrum),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints [child] with a gradient instead of a flat colour.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    required this.gradient,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, textAlign: textAlign, style: style),
    );
  }
}

/// Endless horizontal ticker used for the track meta on the home screen.
class VaultMarquee extends StatefulWidget {
  const VaultMarquee({
    super.key,
    required this.text,
    this.style,
    this.period = const Duration(seconds: 14),
  });

  final String text;
  final TextStyle? style;
  final Duration period;

  @override
  State<VaultMarquee> createState() => _VaultMarqueeState();
}

class _VaultMarqueeState extends State<VaultMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = Text(widget.text, maxLines: 1, style: widget.style);
    return ClipRect(
      child: SizedBox(
        height: 22,
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _run,
            builder: (context, child) {
              return FractionalTranslation(
                translation: Offset(-_run.value * 0.5, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [line, line],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft highlight band that travels across a surface — the "glint" on the
/// primary CTA.
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({
    super.key,
    this.period = const Duration(milliseconds: 2600),
  });

  final Duration period;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep =
        AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_sweep.value);
          return FractionalTranslation(
            translation: Offset(-1.2 + t * 3.4, 0),
            child: Transform.rotate(
              angle: 0.31,
              child: FractionallySizedBox(
                widthFactor: 0.34,
                heightFactor: 2.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The gradient pill used for PLAY / AGAIN.
class VaultCta extends StatelessWidget {
  const VaultCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 17,
    this.verticalPadding = 22,
    this.shimmer = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double fontSize;
  final double verticalPadding;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: v.ctaGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: v.magenta.withValues(alpha: 0.4),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (shimmer) const Positioned.fill(child: ShimmerSweep()),
              Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: Center(
                  child: Text(
                    label,
                    style: vaultDisplay(
                      size: fontSize,
                      color: v.ink,
                      letterSpacing: fontSize * 0.28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
