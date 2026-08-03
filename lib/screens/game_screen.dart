import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_controller.dart';
import '../game/chart.dart';
import '../game/models.dart';
import '../game/rhythm_controller.dart';
import '../game/widgets/bubble.dart';
import '../game/widgets/hud.dart';
import '../game/widgets/pop_it_board.dart';
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

  Future<void> _showResults() async {
    final rhythm = _rhythm!;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: GameColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nice pops!',
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: GameColors.candyPink,
                ),
              ),
              const SizedBox(height: 16),
              _ResultRow(label: 'Score', value: '${rhythm.score}'),
              _ResultRow(label: 'Max combo', value: '${rhythm.maxCombo}'),
              _ResultRow(
                label: 'Accuracy',
                value: '${(rhythm.accuracy * 100).round()}%',
              ),
              _ResultRow(
                label: 'Perfect / Good / Miss',
                value:
                    '${rhythm.perfectCount} / ${rhythm.goodCount} / ${rhythm.missCount}',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(this.context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameColors.ink,
                        side: const BorderSide(color: GameColors.ink),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Home',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _replay();
                      },
                      child: const Text('Replay'),
                    ),
                  ),
                ],
              ),
            ],
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
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        rhythm.clearTransientFlash(bubbleId);
      });
    }
  }

  BubbleVisualState _stateFor(int bubbleId) {
    final rhythm = _rhythm!;
    if (rhythm.missFlashBubbleIds.contains(bubbleId)) {
      return BubbleVisualState.miss;
    }
    if (rhythm.poppedBubbleIds.contains(bubbleId)) {
      return BubbleVisualState.popped;
    }
    if (rhythm.cuedBubbleIds.contains(bubbleId)) {
      return BubbleVisualState.cued;
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
        body: Center(child: CircularProgressIndicator()),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6F0), Color(0xFFFFE4EC)],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _rhythm!,
            builder: (context, _) {
              final rhythm = _rhythm!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: GameColors.ink,
                        ),
                        const Spacer(),
                        Text(
                          rhythm.chart.title,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: GameColors.ink.withValues(alpha: 0.55),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GameHud(
                      score: rhythm.score,
                      combo: rhythm.combo,
                      judgement: rhythm.lastJudgement,
                      judgementToken: rhythm.judgementToken,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
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
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              color: GameColors.ink.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
