import 'package:flutter/material.dart';

import '../game/widgets/vault_decor.dart';
import '../theme/game_theme.dart';
import 'game_screen.dart';
import 'road_to_glory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VaultColors.roomGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -140,
              left: 0,
              right: 0,
              child: Center(child: SpectrumBloom()),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Text(
                          'THE DISCO VAULT',
                          textAlign: TextAlign.center,
                          style: vaultLabel(
                            size: 10,
                            color: VaultColors.gold,
                            tracking: 0.46,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _bob,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              0,
                              -9 * Curves.easeInOut.transform(_bob.value),
                            ),
                            child: child,
                          ),
                          child: GradientText(
                            'POP\nIT',
                            gradient: VaultColors.wordmarkGradient,
                            style: vaultDisplay(
                              size: 76,
                              height: 0.86,
                              letterSpacing: -2.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Two ways in. Same stones. Different glory.',
                          textAlign: TextAlign.center,
                          style: vaultLabel(
                            size: 13,
                            color: VaultColors.paper.withValues(alpha: 0.6),
                            weight: FontWeight.w400,
                            tracking: 0.1,
                          ).copyWith(height: 1.7),
                        ),
                        const Spacer(flex: 2),
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color:
                                    VaultColors.paper.withValues(alpha: 0.14),
                              ),
                              bottom: BorderSide(
                                color:
                                    VaultColors.paper.withValues(alpha: 0.14),
                              ),
                            ),
                          ),
                          child: VaultMarquee(
                            text:
                                'RHYTHM  \u2726  ROAD TO GLORY  \u2726  POP STONES  \u2726  ',
                            style: vaultLabel(
                              size: 10,
                              color:
                                  VaultColors.paper.withValues(alpha: 0.45),
                              tracking: 0.34,
                            ),
                          ),
                        ),
                        VaultCta(
                          label: 'RHYTHM',
                          shimmer: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GameScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        VaultCta(
                          label: 'ROAD TO GLORY',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const RoadToGloryScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 34),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
