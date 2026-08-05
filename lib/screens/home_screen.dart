import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../game/models.dart';
import '../game/run_config.dart';
import '../game/widgets/vault_decor.dart';
import '../services/versus_service.dart';
import '../theme/game_theme.dart';
import 'game_screen.dart';
import 'road_to_glory_screen.dart';
import 'settings_screen.dart';
import 'versus_lobby_screen.dart';

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

  Difficulty _difficulty = Difficulty.normal;
  GameMode _mode = GameMode.classic;

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  String _modeLabel(GameMode m) => switch (m) {
        GameMode.classic => 'Classic',
        GameMode.survival => 'Survival',
        GameMode.precision => 'Precision',
        GameMode.endlessRush => 'Endless Rush',
      };

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings_rounded),
                          color: VaultColors.paper.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            size: 64,
                            height: 0.86,
                            letterSpacing: -2.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Streak ${services.profile.streakCurrent} · ${services.profile.lifetimeScore} pts',
                        textAlign: TextAlign.center,
                        style: vaultLabel(
                          size: 11,
                          color: VaultColors.paper.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 28),
                      DropdownButtonFormField<Difficulty>(
                        initialValue: _difficulty,
                        dropdownColor: VaultColors.plateMid,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final d in Difficulty.values)
                            DropdownMenuItem(
                              value: d,
                              child: Text(d.name),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _difficulty = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<GameMode>(
                        initialValue: _mode,
                        dropdownColor: VaultColors.plateMid,
                        decoration: const InputDecoration(
                          labelText: 'Mode',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final m in GameMode.values)
                            DropdownMenuItem(
                              value: m,
                              child: Text(_modeLabel(m)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _mode = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      VaultCta(
                        label: 'RHYTHM',
                        shimmer: true,
                        onPressed: () {
                          final config = RunConfig(
                            chartId: services.settings.lastChartId,
                            difficulty: _difficulty,
                            mode: _mode,
                            board: services.settings.casualBoard
                                ? BoardLayout.casual
                                : BoardLayout.standard,
                          );
                          services.settings.update((s) {
                            s.lastDifficulty = _difficulty.name;
                            s.lastMode = _mode.name;
                          });
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GameScreen(config: config),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      VaultCta(
                        label: 'VERSUS',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const VersusLobbyScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          final seed = VersusService.dailySeed();
                          final config = RunConfig(
                            chartId: services.settings.lastChartId,
                            difficulty: Difficulty.normal,
                            mode: GameMode.classic,
                            isDaily: true,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GameScreen(
                                config: config,
                                dailySeed: seed,
                              ),
                            ),
                          );
                        },
                        child: const Text('DAILY CHALLENGE'),
                      ),
                    ],
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
