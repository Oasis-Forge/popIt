import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/game_theme.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF1F5),
              GameColors.cream,
              Color(0xFFFFE0EA),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  'Pop It',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    height: 0.95,
                    color: GameColors.candyPink,
                    shadows: const [
                      Shadow(
                        color: Color(0x66E85A7C),
                        offset: Offset(0, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap the glowing bubbles on the beat.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: GameColors.ink.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GameScreen(),
                        ),
                      );
                    },
                    child: const Text('Play'),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
