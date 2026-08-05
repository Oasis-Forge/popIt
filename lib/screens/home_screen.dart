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

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  Future<void> _openRhythmSetup() async {
    final services = AppScope.of(context);
    Difficulty difficulty = Difficulty.values.firstWhere(
      (d) => d.name == services.settings.lastDifficulty,
      orElse: () => Difficulty.normal,
    );
    GameMode mode = GameMode.values.firstWhere(
      (m) => m.name == services.settings.lastMode,
      orElse: () => GameMode.classic,
    );

    final config = await showModalBottomSheet<RunConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A0C36), VaultColors.plateDeep],
                ),
                border: Border(
                  top: BorderSide(color: VaultColors.gold, width: 2),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                18,
                24,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'RHYTHM SETUP',
                    textAlign: TextAlign.center,
                    style: vaultLabel(size: 12, color: VaultColors.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Difficulty and mode only apply to Rhythm.',
                    textAlign: TextAlign.center,
                    style: vaultLabel(
                      size: 10,
                      color: VaultColors.paper.withValues(alpha: 0.5),
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<Difficulty>(
                    initialValue: difficulty,
                    dropdownColor: VaultColors.plateMid,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final d in Difficulty.values)
                        DropdownMenuItem(value: d, child: Text(d.name)),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheet(() => difficulty = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GameMode>(
                    initialValue: mode,
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
                      if (v != null) setSheet(() => mode = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  VaultCta(
                    label: 'PLAY',
                    shimmer: true,
                    onPressed: () {
                      Navigator.of(context).pop(
                        RunConfig(
                          chartId: services.settings.lastChartId,
                          difficulty: difficulty,
                          mode: mode,
                          board: services.settings.casualBoard
                              ? BoardLayout.casual
                              : BoardLayout.standard,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || config == null) return;
    services.settings.update((s) {
      s.lastDifficulty = config.difficulty.name;
      s.lastMode = config.mode.name;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(config: config)),
    );
  }

  static String _modeLabel(GameMode m) => switch (m) {
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
                      const SizedBox(height: 32),
                      VaultCta(
                        label: 'RHYTHM',
                        shimmer: true,
                        onPressed: _openRhythmSetup,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick difficulty & mode before you play',
                        textAlign: TextAlign.center,
                        style: vaultLabel(
                          size: 9,
                          color: VaultColors.paper.withValues(alpha: 0.4),
                          weight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 6),
                      Text(
                        'Survival climb — separate rules',
                        textAlign: TextAlign.center,
                        style: vaultLabel(
                          size: 9,
                          color: VaultColors.paper.withValues(alpha: 0.4),
                          weight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 6),
                      Text(
                        'Friend match · classic rules',
                        textAlign: TextAlign.center,
                        style: vaultLabel(
                          size: 9,
                          color: VaultColors.paper.withValues(alpha: 0.4),
                          weight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          final seed = VersusService.dailySeed();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GameScreen(
                                config: RunConfig(
                                  chartId: services.settings.lastChartId,
                                  difficulty: Difficulty.normal,
                                  mode: GameMode.classic,
                                  isDaily: true,
                                ),
                                dailySeed: seed,
                              ),
                            ),
                          );
                        },
                        child: const Text('DAILY CHALLENGE'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Same chart for everyone today · classic / normal',
                        textAlign: TextAlign.center,
                        style: vaultLabel(
                          size: 9,
                          color: VaultColors.paper.withValues(alpha: 0.4),
                          weight: FontWeight.w400,
                        ),
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
