import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../game/daily_challenge.dart';
import '../game/models.dart';
import '../game/run_config.dart';
import '../game/widgets/vault_decor.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';
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
  bool _coachPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferCoach());
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  Future<void> _maybeOfferCoach() async {
    if (!mounted || _coachPromptShown) return;
    final services = AppScope.of(context);
    if (services.profile.coachCompleted) return;
    _coachPromptShown = true;
    final v = context.vault;
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [v.plateTop, v.plateDeep],
            ),
            border: Border(top: BorderSide(color: v.gold, width: 2)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            22,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QUICK COACH', style: vaultDisplay(size: 22, color: v.gold)),
              const SizedBox(height: 8),
              Text(
                'Eight easy notes. Tap when the ring peaks on the beat.',
                textAlign: TextAlign.center,
                style: vaultLabel(
                  size: 12,
                  color: v.paper.withValues(alpha: 0.65),
                  weight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              VaultCta(
                label: 'START COACH',
                shimmer: true,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('SKIP'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (go == true) {
      await _openCoach();
    } else if (go == false) {
      services.profile.markCoachCompleted();
    }
  }

  Future<void> _openCoach() async {
    final services = AppScope.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          config: RunConfig(
            chartId: 'coach_intro',
            difficulty: Difficulty.easy,
            mode: GameMode.classic,
            board: services.settings.casualBoard
                ? BoardLayout.casual
                : BoardLayout.standard,
          ),
          isCoach: true,
        ),
      ),
    );
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
    String chartId = services.settings.lastChartId;
    final charts = services.chartLibrary.songCharts;
    if (!charts.any((c) => c.id == chartId) && charts.isNotEmpty) {
      chartId = charts.first.id;
    }

    final config = await showModalBottomSheet<RunConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final v = context.vault;
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [v.plateTop, v.plateDeep],
                ),
                border: Border(
                  top: BorderSide(color: v.gold, width: 2),
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
                    style: vaultLabel(size: 12, color: v.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track, difficulty, and mode for this run.',
                    textAlign: TextAlign.center,
                    style: vaultLabel(
                      size: 10,
                      color: v.paper.withValues(alpha: 0.5),
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: chartId,
                    dropdownColor: v.plateMid,
                    decoration: const InputDecoration(
                      labelText: 'Track',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in charts)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.title} · ${c.bpm} BPM'
                            '${_bestSuffix(services, c.id, difficulty, mode)}',
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) setSheet(() => chartId = id);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Difficulty>(
                    initialValue: difficulty,
                    dropdownColor: v.plateMid,
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
                    dropdownColor: v.plateMid,
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
                  const SizedBox(height: 8),
                  Text(
                    _modeBlurb(mode),
                    textAlign: TextAlign.center,
                    style: vaultLabel(
                      size: 10,
                      color: v.paper.withValues(alpha: 0.5),
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  VaultCta(
                    label: 'PLAY',
                    shimmer: true,
                    onPressed: () {
                      Navigator.of(context).pop(
                        RunConfig(
                          chartId: chartId,
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
      s.lastChartId = config.chartId;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(config: config)),
    );
  }

  static String _bestSuffix(
    AppServices services,
    String chartId,
    Difficulty difficulty,
    GameMode mode,
  ) {
    final key = '$chartId|${difficulty.name}|${mode.name}';
    final best = services.profile.bests[key];
    if (best == null) return '';
    return ' · ${best.grade} ${best.score}';
  }

  static String _modeLabel(GameMode m) => switch (m) {
        GameMode.classic => 'Classic',
        GameMode.survival => 'Survival',
        GameMode.precision => 'Precision',
        GameMode.endlessRush => 'Endless Rush',
      };

  static String _modeBlurb(GameMode m) => switch (m) {
        GameMode.classic => 'Full chart · Good & Perfect both score',
        GameMode.survival => '5 hearts · miss costs a life',
        GameMode.precision => 'Perfect-only · Good breaks combo',
        GameMode.endlessRush => 'Loops forever · windows tighten each loop',
      };

  Future<void> _openDaily() async {
    final services = AppScope.of(context);
    final daily = DailyChallenge.forToday(services.chartLibrary);
    if (services.profile.hasPlayedDaily(daily.ymd)) {
      final best = services.profile.bests[daily.bestKey];
      final v = context.vault;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            best == null
                ? 'Daily already played today'
                : 'Today’s best: ${best.grade} ${best.score}',
            style: vaultLabel(size: 12),
          ),
          backgroundColor: v.plateDeep,
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          config: daily.toConfig(
            board: services.settings.casualBoard
                ? BoardLayout.casual
                : BoardLayout.standard,
          ),
          dailySeed: daily.ymd,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    final services = AppScope.of(context);
    final daily = DailyChallenge.forToday(services.chartLibrary);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: v.roomGradient),
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
                  child: ListenableBuilder(
                    listenable: services.profileController,
                    builder: (context, _) {
                      final profile = services.profile;
                      final done = profile.hasPlayedDaily(daily.ymd);
                      return ListView(
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
                              color: v.paper.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'THE DISCO VAULT',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 10,
                              color: v.gold,
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
                              gradient: v.wordmarkGradient,
                              style: vaultDisplay(
                                size: 64,
                                height: 0.86,
                                letterSpacing: -2.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.streakCurrent > 0
                                ? 'Day ${profile.streakCurrent} streak · ${profile.lifetimeScore} pts'
                                : '${profile.lifetimeScore} pts · start a streak today',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 11,
                              color: v.paper.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            done
                                ? () {
                                    final best =
                                        profile.bests[daily.bestKey];
                                    return best == null
                                        ? 'Daily done · come back tomorrow'
                                        : 'Daily done · ${best.grade} ${best.score}';
                                  }()
                                : 'Daily today · ${daily.blurb(services.chartLibrary)}',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 10,
                              color: v.cyan.withValues(alpha: 0.85),
                              weight: FontWeight.w400,
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
                            'Classic → Survival → Daily',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 9,
                              color: v.paper.withValues(alpha: 0.4),
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
                            profile.roadBestCleared > 0
                                ? 'Best clear ${profile.roadBestCleared} · stage ${profile.roadBestStage + 1}'
                                : 'Survival climb — feeds your streak',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 9,
                              color: v.paper.withValues(alpha: 0.4),
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
                            '2–4 players · bots now, friends soon',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 9,
                              color: v.paper.withValues(alpha: 0.4),
                              weight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: done ? null : _openDaily,
                            child: Text(
                              done ? 'DAILY DONE' : 'DAILY CHALLENGE',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            done
                                ? 'Come back tomorrow · ${DailyChallenge.forTomorrow(services.chartLibrary).blurb(services.chartLibrary)}'
                                : 'One try · ${daily.blurb(services.chartLibrary)}',
                            textAlign: TextAlign.center,
                            style: vaultLabel(
                              size: 9,
                              color: v.paper.withValues(alpha: 0.4),
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
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
