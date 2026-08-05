import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_scope.dart';
import '../audio/audio_controller.dart';
import '../data/player_profile.dart';
import '../data/theme_unlocks.dart';
import '../game/chart_library.dart';
import '../game/daily_challenge.dart';
import '../game/game_rules.dart';
import '../game/models.dart';
import '../game/rhythm_controller.dart';
import '../game/run_config.dart';
import '../game/widgets/bubble.dart';
import '../game/widgets/hud.dart';
import '../game/widgets/pop_it_board.dart';
import '../game/widgets/results_sheet.dart';
import '../game/widgets/vault_decor.dart';
import '../services/versus_service.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.config = const RunConfig(chartId: 'demo_beat'),
    this.dailySeed,
    this.isCoach = false,
  });

  final RunConfig config;
  final String? dailySeed;
  final bool isCoach;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
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
  int _comboFlash = 0;
  late final AnimationController _comboBloom;

  @override
  void initState() {
    super.initState();
    _comboBloom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
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
        title: widget.isCoach
            ? 'Coach'
            : widget.dailySeed == null
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

  String get _bestKey {
    if (widget.config.isDaily && widget.dailySeed != null) {
      return 'daily|${widget.dailySeed}';
    }
    return '${widget.config.chartId}|${widget.config.difficulty.name}|${widget.config.mode.name}';
  }

  void _maybeShowResults() {
    final rhythm = _rhythm;
    if (rhythm == null || !rhythm.finished || _resultsShown) return;
    _resultsShown = true;
    _audio.pause();
    final services = AppScope.of(context);
    final result = rhythm.buildResult();
    final prev = services.profile.bests[_bestKey];
    final prevScore = prev?.score;
    final isNewBest = services.profile.recordRun(
      key: _bestKey,
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
    if (widget.config.isDaily && widget.dailySeed != null) {
      services.profile.markDailyCompleted(widget.dailySeed!);
    }
    if (widget.isCoach) {
      services.profile.markCoachCompleted();
    }
    final newly = applyThemeUnlocks(
      profile: services.profile,
      result: result,
      versus: widget.config.versusRoom != null,
    );
    if (widget.config.versusRoom == null && !widget.isCoach) {
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
    final progress = nextUnlockProgress(
      profile: services.profile,
      result: result,
      versus: widget.config.versusRoom != null,
    );
    List<VersusPlayerState>? ranking;
    if (widget.config.versusRoom != null) {
      ranking = [
        services.versusService.local,
        ...services.versusService.rivals,
      ]..sort((a, b) => b.score.compareTo(a.score));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showResults(
        result,
        isNewBest: isNewBest,
        previousBestScore: prevScore,
        newly: newly,
        progress: progress,
        ranking: ranking,
      );
      for (final u in newly) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unlocked ${u.name} — ${u.rule}',
              style: vaultLabel(size: 12),
            ),
            backgroundColor: context.vault.plateDeep,
          ),
        );
      }
    });
  }

  static String _clock(int ms, int durationMs) {
    final secs = (ms.clamp(0, durationMs)) ~/ 1000;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  Difficulty? _nextHarder() {
    const order = Difficulty.values;
    final i = order.indexOf(widget.config.difficulty);
    if (i < 0 || i >= order.length - 1) return null;
    return order[i + 1];
  }

  Future<void> _showResults(
    RunResult result, {
    required bool isNewBest,
    required int? previousBestScore,
    required List<ThemeUnlockInfo> newly,
    required UnlockProgress? progress,
    required List<VersusPlayerState>? ranking,
  }) async {
    final delta = previousBestScore == null
        ? null
        : result.score - previousBestScore;
    final harder = _nextHarder();
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
      onShare: widget.isCoach ? null : _shareScore,
      meta: ResultsMeta(
        isNewBest: isNewBest,
        previousBestScore: previousBestScore,
        scoreDelta: delta,
        unlockProgress: newly.isEmpty ? progress : null,
        newlyUnlocked: newly,
        versusRanking: ranking,
        onDaily: widget.config.isDaily || widget.isCoach
            ? null
            : () {
                final nav = Navigator.of(context);
                final services = AppScope.of(context);
                final daily =
                    DailyChallenge.forToday(services.chartLibrary);
                nav.pop(); // close sheet
                nav.pop(); // leave game
                if (services.profile.hasPlayedDaily(daily.ymd)) return;
                // Home is under the popped routes; push from root after frame.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final homeCtx = nav.context;
                  if (!homeCtx.mounted) return;
                  Navigator.of(homeCtx).push(
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
                });
              },
        onHarder: harder == null || widget.isCoach
            ? null
            : () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(
                      config: RunConfig(
                        chartId: widget.config.chartId,
                        difficulty: harder,
                        mode: widget.config.mode,
                        board: widget.config.board,
                        isDaily: false,
                      ),
                    ),
                  ),
                );
              },
      ),
    );
  }

  Future<void> _shareScore() async {
    final rhythm = _rhythm;
    if (rhythm == null) return;
    final r = rhythm.buildResult();
    final text =
        'Pop It ${r.grade}: ${r.score} pts · x${r.maxCombo} · ${rhythm.chart.title}';
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.5);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          await SharePlus.instance.share(
            ShareParams(
              text: text,
              files: [
                XFile.fromData(
                  bytes,
                  mimeType: 'image/png',
                  name: 'popit_${r.grade.toLowerCase()}.png',
                ),
              ],
            ),
          );
          return;
        }
      }
    } catch (_) {
      // Fall through to text share.
    }
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _replay() async {
    _resultsShown = false;
    _comboFlash = 0;
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

  void _celebrateCombo(int combo, bool reduceMotion) {
    const milestones = {10, 25, 50, 100};
    if (!milestones.contains(combo) || combo == _comboFlash) return;
    _comboFlash = combo;
    if (reduceMotion) return;
    _comboBloom.forward(from: 0);
  }

  void _onBubbleTap(int bubbleId) {
    final rhythm = _rhythm;
    if (rhythm == null || rhythm.finished || _paused || _countdown > 0) return;
    final result = rhythm.onBubbleTapped(bubbleId);
    if (result == null) return;
    final services = AppScope.of(context);
    final haptics = services.settings.hapticsEnabled;
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
      _celebrateCombo(rhythm.combo, services.settings.reduceMotion);
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
    _comboBloom.dispose();
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
    final precision = widget.config.mode == GameMode.precision;
    final survivalish = _rhythm!.rules.startingLives > 0;

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
            if (survivalish && _rhythm!.lives <= 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          v.missRed.withValues(alpha: 0.22),
                        ],
                        radius: 1.05,
                      ),
                    ),
                  ),
                ),
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
                      final showGood = !(precision &&
                          rhythm.lastJudgement == Judgement.good);

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
                              if (widget.isCoach) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap when the ring peaks',
                                  style: vaultLabel(
                                    size: 11,
                                    color: v.cyan,
                                  ),
                                ),
                              ],
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
                              if (survivalish || rhythm.rules.loops) ...[
                                const SizedBox(height: 8),
                                ModeStatusRow(
                                  lives: survivalish ? rhythm.lives : null,
                                  maxLives: survivalish
                                      ? rhythm.rules.startingLives
                                      : null,
                                  loop: rhythm.rules.loops
                                      ? rhythm.loop + 1
                                      : null,
                                  precision: precision,
                                ),
                              ] else if (precision) ...[
                                const SizedBox(height: 8),
                                ModeStatusRow(precision: true),
                              ],
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
                                    rhythm.lastJudgement != Judgement.miss &&
                                    showGood,
                                goodWindowMs: widget.config.difficultyConfig
                                    .timing.goodWindowMs,
                              ),
                              const SizedBox(height: 6),
                              JudgementLine(
                                judgement: rhythm.lastJudgement,
                                deltaMs: rhythm.lastDeltaMs,
                                judgementToken: rhythm.judgementToken,
                                precisionMode: precision,
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
                                      cueProgressFor: rhythm.cueProgressFor,
                                      precisionMode: precision,
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
            AnimatedBuilder(
              animation: _comboBloom,
              builder: (context, _) {
                if (_comboBloom.isDismissed || _comboFlash == 0) {
                  return const SizedBox.shrink();
                }
                final t = Curves.easeOut.transform(_comboBloom.value);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.85 + t * 0.55,
                          child: Text(
                            '×$_comboFlash',
                            style: vaultDisplay(
                              size: 64,
                              color: v.gold,
                            ).copyWith(
                              shadows: [
                                Shadow(
                                  color: v.magenta.withValues(alpha: 0.8),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
