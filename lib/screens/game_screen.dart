import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_controller.dart';
import '../game/chart.dart';
import '../game/models.dart';
import '../game/rhythm_controller.dart';
import '../game/widgets/bubble.dart';
import '../game/widgets/hud.dart';
import '../game/widgets/pop_it_board.dart';
import '../game/widgets/vault_decor.dart';
import '../theme/game_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const rows = 4;
  static const cols = 5;

  final AudioController _audio = AudioController();
  RhythmController? _rhythm;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool _loading = true;
  String? _error;
  bool _resultsShown = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final chart = await loadDemoChart();
      final rhythm = RhythmController(chart: chart);
      await _audio.load(
        musicAsset: chart.audioAsset,
        popSfxAsset: 'assets/audio/pop.wav',
      );
      if (!mounted) return;
      setState(() {
        _rhythm = rhythm;
        _loading = false;
      });
      _positionSub = _audio.positionStream.listen((pos) {
        _rhythm?.updateTime(pos.inMilliseconds);
        _maybeShowResults();
      });
      _stateSub = _audio.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _rhythm?.updateTime(_rhythm!.chart.durationMs);
          _maybeShowResults();
        }
      });
      await _audio.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _maybeShowResults() {
    final rhythm = _rhythm;
    if (rhythm == null || !rhythm.finished || _resultsShown) return;
    _resultsShown = true;
    _audio.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showResults();
    });
  }

  static String _grade(double acc) {
    if (acc >= 0.98) return 'FLAWLESS';
    if (acc >= 0.9) return 'BRILLIANT';
    if (acc >= 0.75) return 'POLISHED';
    if (acc >= 0.5) return 'ROUGH CUT';
    return 'UNCUT';
  }

  static String _clock(int ms, int durationMs) {
    final secs = (ms.clamp(0, durationMs)) ~/ 1000;
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _showResults() async {
    final rhythm = _rhythm!;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: const Border(
              top: BorderSide(color: VaultColors.gold, width: 2),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A0C36), VaultColors.plateDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 60,
                offset: const Offset(0, -22),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "THAT'S A SET",
                    style: vaultLabel(
                      size: 10,
                      color: VaultColors.gold,
                      tracking: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GradientText(
                    '${rhythm.score}',
                    gradient: VaultColors.scoreGradient,
                    style: vaultDisplay(size: 60),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _grade(rhythm.accuracy),
                    style: vaultLabel(
                      size: 13,
                      color: VaultColors.paper.withValues(alpha: 0.6),
                      tracking: 0.26,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultTile(
                          label: 'ACC',
                          value: '${(rhythm.accuracy * 100).round()}%',
                          color: VaultColors.lime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResultTile(
                          label: 'COMBO',
                          value: '${rhythm.maxCombo}',
                          color: VaultColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResultTile(
                          label: 'P/G/M',
                          value:
                              '${rhythm.perfectCount}/${rhythm.goodCount}/${rhythm.missCount}',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(this.context).pop();
                          },
                          child: const Text('HOME'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: VaultCta(
                          label: 'AGAIN',
                          fontSize: 13,
                          verticalPadding: 17,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _replay();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _replay() async {
    _resultsShown = false;
    _rhythm?.reset();
    await _audio.seekZero();
    await _audio.play();
    setState(() {});
  }

  void _onBubbleTap(int bubbleId) {
    final rhythm = _rhythm;
    if (rhythm == null || rhythm.finished) return;
    final result = rhythm.onBubbleTapped(bubbleId);
    if (result == null) return;

    if (result.judgement == Judgement.perfect ||
        result.judgement == Judgement.good) {
      HapticFeedback.lightImpact();
      _audio.playPop();
    } else {
      HapticFeedback.heavyImpact();
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
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: VaultColors.gold),
        ),
      );
    }
    if (_error != null || _rhythm == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Failed to load game',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VaultColors.roomGradient),
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
                      final rhythm = _rhythm!;
                      final progress = (rhythm.positionMs /
                              rhythm.chart.durationMs)
                          .clamp(0.0, 1.0);
                      final fresh = rhythm.lastJudgement != null;

                      return Padding(
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
                                      color: VaultColors.paper
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                ),
                                Text(
                                  rhythm.chart.title.toUpperCase(),
                                  style: vaultLabel(
                                    size: 10,
                                    color: VaultColors.gold,
                                  ),
                                ),
                                Text(
                                  _clock(
                                    rhythm.positionMs,
                                    rhythm.chart.durationMs,
                                  ),
                                  style: vaultLabel(
                                    size: 10,
                                    color: VaultColors.paper
                                        .withValues(alpha: 0.45),
                                  ),
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
                                      color: VaultColors.paper
                                          .withValues(alpha: 0.12),
                                      child: const SizedBox.expand(),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progress,
                                      child: const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              VaultColors.cyan,
                                              VaultColors.magenta,
                                              VaultColors.gold,
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
                            const SizedBox(height: 14),
                            TimingBar(
                              deltaMs: rhythm.lastDeltaMs,
                              visible: fresh &&
                                  rhythm.lastJudgement != Judgement.miss,
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
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: PopItBoard(
                                    rows: rows,
                                    cols: cols,
                                    stateForBubble: _stateFor,
                                    onBubbleTap: _onBubbleTap,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: VaultColors.paper.withValues(alpha: 0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: vaultLabel(
              size: 8.5,
              color: VaultColors.paper.withValues(alpha: 0.45),
              tracking: 0.24,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            style: vaultDisplay(size: 23, color: color),
          ),
        ],
      ),
    );
  }
}
