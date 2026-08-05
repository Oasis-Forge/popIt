import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_scope.dart';
import '../audio/audio_controller.dart';
import '../data/player_profile.dart';
import '../game/chart_library.dart';
import '../game/game_rules.dart';
import '../game/models.dart';
import '../game/rhythm_controller.dart';
import '../game/run_config.dart';
import '../game/widgets/bubble.dart';
import '../game/widgets/hud.dart';
import '../game/widgets/pop_it_board.dart';
import '../game/widgets/results_sheet.dart';
import '../game/widgets/vault_decor.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.config = const RunConfig(chartId: 'demo_beat'),
    this.dailySeed,
  });

  final RunConfig config;
  final String? dailySeed;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AudioController _audio = AudioController();
  final GlobalKey _shareKey = GlobalKey();
  RhythmController? _rhythm;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool _loading = true;
  String? _error;
  bool _resultsShown = false;
  bool _paused = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    try {
      final services = AppScope.of(context);
      final meta = services.chartLibrary.byId(widget.config.chartId);
      var chart = await loadChart(meta);
      final shaped = applyDensity(
        chart.notes,
        widget.config.difficultyConfig.density,
      );
      chart = Chart(
        id: chart.id,
        title: widget.dailySeed == null
            ? chart.title
            : 'Daily ${widget.dailySeed}',
        artist: chart.artist,
        bpm: chart.bpm,
        audioAsset: chart.audioAsset,
        durationMs: chart.durationMs,
        notes: shaped,
      );
      final rules = rulesFor(widget.config.mode);
      final rhythm = RhythmController(
        chart: chart,
        timing: widget.config.difficultyConfig.timing,
        rules: rules,
      );
      await _audio.load(
        musicAsset: chart.audioAsset,
        popSfxAsset: 'assets/audio/pop.wav',
        loseSfxAsset: 'assets/audio/lose.wav',
      );
      await _audio.applyMix(
        musicVolume: services.settings.musicVolume,
        sfxVolume: services.settings.sfxVolume,
        musicMuted: services.settings.musicMuted,
        sfxMuted: services.settings.sfxMuted,
      );
      await _audio.setLoopOne(rules.loops);
      if (!mounted) return;
      setState(() {
        _rhythm = rhythm;
        _loading = false;
        _countdown = 3;
      });
      _positionSub = _audio.positionStream.listen((pos) {
        final offset = services.settings.audioOffsetMs;
        _rhythm?.updateTime(pos.inMilliseconds - offset);
        if (widget.config.versusRoom != null && _rhythm != null) {
          services.versusService.publishLocal(
            score: _rhythm!.score,
            combo: _rhythm!.combo,
            accuracy: _rhythm!.accuracy,
            posMs: _rhythm!.positionMs,
          );
        }
        _maybeShowResults();
      });
      _stateSub = _audio.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed &&
            !rules.loops) {
          _rhythm?.updateTime(_rhythm!.chart.durationMs);
          _maybeShowResults();
        }
      });
      await _runCountdownThenPlay();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _runCountdownThenPlay() async {
    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _countdown = 0);
    await _audio.play();
  }

  void _maybeShowResults() {
    final rhythm = _rhythm;
    if (rhythm == null || !rhythm.finished || _resultsShown) return;
    _resultsShown = true;
    _audio.pause();
    final services = AppScope.of(context);
    final result = rhythm.buildResult();
    final key =
        '${widget.config.chartId}|${widget.config.difficulty.name}|${widget.config.mode.name}';
    services.profile.recordRun(
      key: key,
      best: RunBest(
        score: result.score,
        accuracy: result.accuracy,
        maxCombo: result.maxCombo,
        perfect: result.perfect,
        good: result.good,
        miss: result.miss,
        grade: result.grade,
        atEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _unlockThemes(services, result);
    // Versus never feeds global leaderboards.
    if (widget.config.versusRoom == null) {
      final lbId =
          'lb_${widget.config.mode.name}_${widget.config.difficulty.name}';
      services.gamesService.queueOrSubmit(
        leaderboardId: lbId,
        score: result.score,
        enqueue: (pending) {
          services.profileController.enqueueLeaderboard(pending);
        },
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showResults(result);
    });
  }

  void _unlockThemes(AppServices services, RunResult result) {
    final p = services.profile;
    if (p.lifetimeScore >= 50000) p.unlockTheme('neon_arcade');
    if (result.maxCombo >= 100) p.unlockTheme('aurora_ice');
    if (result.grade == 'FLAWLESS') p.unlockTheme('sunset_bakery');
    if (widget.config.versusRoom != null && result.score > 0) {
      p.unlockTheme('midnight_mono');
    }
  }

  static String _clock(int ms, int durationMs) {
    final secs = (ms.clamp(0, durationMs)) ~/ 1000;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _showResults(RunResult result) async {
    await showResultsSheet(
      context: context,
      result: result,
      onHome: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
      onReplay: () {
        Navigator.of(context).pop();
        _replay();
      },
      onShare: _shareScore,
    );
  }

  Future<void> _shareScore() async {
    final rhythm = _rhythm;
    if (rhythm == null) return;
    final r = rhythm.buildResult();
    await SharePlus.instance.share(
      ShareParams(text: 'Pop It ${r.grade}: ${r.score} pts · x${r.maxCombo}'),
    );
  }

  Future<void> _replay() async {
    _resultsShown = false;
    _rhythm?.reset();
    await _audio.seekZero();
    await _runCountdownThenPlay();
    setState(() {});
  }

  void _togglePause() {
    final services = AppScope.of(context);
    setState(() => _paused = !_paused);
    if (_paused) {
      _audio.pause();
    } else {
      _audio.resume();
    }
    if (services.settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _onBubbleTap(int bubbleId) {
    final rhythm = _rhythm;
    if (rhythm == null || rhythm.finished || _paused || _countdown > 0) return;
    final result = rhythm.onBubbleTapped(bubbleId);
    if (result == null) return;
    final haptics = AppScope.of(context).settings.hapticsEnabled;
    if (result.judgement == Judgement.perfect ||
        result.judgement == Judgement.good) {
      if (haptics) HapticFeedback.lightImpact();
      _audio.playHitTone(
        combo: rhythm.combo,
        perfect: result.judgement == Judgement.perfect,
      );
      if (rhythm.combo > 0 && rhythm.combo % 10 == 0 && haptics) {
        HapticFeedback.mediumImpact();
      }
    } else {
      if (haptics) HapticFeedback.heavyImpact();
      _audio.playLose();
    }
  }

  BubbleVisualState _stateFor(int bubbleId) {
    final rhythm = _rhythm!;
    if (rhythm.cuedBubbleIds.contains(bubbleId)) {
      return BubbleVisualState.cued;
    }
    if (rhythm.poppedBubbleIds.contains(bubbleId)) {
      return BubbleVisualState.popped;
    }
    return BubbleVisualState.idle;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _rhythm?.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: v.gold),
        ),
      );
    }
    if (_error != null || _rhythm == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? 'Failed to load game', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final services = AppScope.of(context);
    final board = widget.config.board;
    final maxW = services.settings.boardMaxWidth;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: v.roomGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -140,
              left: 0,
              right: 0,
              child: Center(child: SpectrumBloom(opacity: 0.32)),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ListenableBuilder(
                    listenable: _rhythm!,
                    builder: (context, _) {
                      final v = context.vault;
                      final rhythm = _rhythm!;
                      final progress =
                          (rhythm.positionMs / rhythm.chart.durationMs)
                              .clamp(0.0, 1.0);
                      final fresh = rhythm.lastJudgement != null;
                      final versus = widget.config.versusRoom != null
                          ? services.versusService
                          : null;

                      return RepaintBoundary(
                        key: _shareKey,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'CLOSE',
                                      style: vaultLabel(
                                        size: 10,
                                        color: v.paper
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    rhythm.chart.title.toUpperCase(),
                                    style: vaultLabel(
                                      size: 10,
                                      color: v.gold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (rhythm.rules.startingLives > 0)
                                        Text(
                                          '♥${rhythm.lives} ',
                                          style: vaultLabel(
                                            size: 10,
                                            color: v.magenta,
                                          ),
                                        ),
                                      GestureDetector(
                                        onTap: _togglePause,
                                        child: Text(
                                          _paused ? 'RESUME' : 'PAUSE',
                                          style: vaultLabel(
                                            size: 10,
                                            color: v.paper
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: SizedBox(
                                  height: 6,
                                  child: Stack(
                                    children: [
                                      ColoredBox(
                                        color: v.paper
                                            .withValues(alpha: 0.12),
                                        child: const SizedBox.expand(),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progress,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                v.cyan,
                                                v.magenta,
                                                v.gold,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GameHud(
                                score: rhythm.score,
                                combo: rhythm.combo,
                                accuracy: rhythm.accuracy,
                              ),
                              if (versus != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  [
                                    'You ${versus.local.score}',
                                    for (final r in versus.rivals)
                                      '${r.displayName} ${r.score}',
                                  ].join(' · '),
                                  textAlign: TextAlign.center,
                                  style: vaultLabel(
                                    size: 11,
                                    color: v.cyan,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              TimingBar(
                                deltaMs: rhythm.lastDeltaMs,
                                visible: fresh &&
                                    rhythm.lastJudgement != Judgement.miss,
                                goodWindowMs: widget.config.difficultyConfig
                                    .timing.goodWindowMs,
                              ),
                              const SizedBox(height: 6),
                              JudgementLine(
                                judgement: rhythm.lastJudgement,
                                deltaMs: rhythm.lastDeltaMs,
                                judgementToken: rhythm.judgementToken,
                              ),
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: maxW),
                                    child: PopItBoard(
                                      rows: board.rows,
                                      cols: board.cols,
                                      boardScale: services.settings.boardScale,
                                      stateForBubble: _stateFor,
                                      onBubbleTap: _onBubbleTap,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                _clock(
                                  rhythm.positionMs,
                                  rhythm.chart.durationMs,
                                ),
                                style: vaultLabel(
                                  size: 10,
                                  color: v.paper
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_countdown > 0)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: vaultDisplay(size: 96, color: v.gold),
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
