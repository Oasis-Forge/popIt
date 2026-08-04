import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_controller.dart';
import '../game/road_to_glory_controller.dart';
import '../game/widgets/bubble.dart';
import '../game/widgets/pop_it_board.dart';
import '../game/widgets/vault_decor.dart';
import '../theme/game_theme.dart';

class RoadToGloryScreen extends StatefulWidget {
  const RoadToGloryScreen({super.key});

  @override
  State<RoadToGloryScreen> createState() => _RoadToGloryScreenState();
}

class _RoadToGloryScreenState extends State<RoadToGloryScreen> {
  final RoadToGloryController _game = RoadToGloryController();
  final AudioController _audio = AudioController();
  bool _loading = true;
  String? _error;
  bool _failModalOpen = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _audio.loadSfxOnly(
        popSfxAsset: 'assets/audio/pop.wav',
        loseSfxAsset: 'assets/audio/lose.wav',
      );
      _game.start();
      _game.addListener(_onGameChanged);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onGameChanged() {
    if (!mounted) return;
    if (_game.phase == RoadPhase.failed && !_failModalOpen) {
      _failModalOpen = true;
      _audio.playLose();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFailModal();
      });
    }
    if (_game.banner != null) {
      final message = _game.banner!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: vaultLabel(size: 12)),
          backgroundColor: VaultColors.plateDeep,
          duration: const Duration(milliseconds: 1400),
        ),
      );
      _game.clearBanner();
    }
    setState(() {});
  }

  Future<void> _showFailModal() async {
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
          ),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MISSED',
                style: vaultDisplay(size: 34, color: VaultColors.missRed),
              ),
              const SizedBox(height: 8),
              Text(
                'One wrong stone ends the run. Restart this stage?',
                textAlign: TextAlign.center,
                style: vaultLabel(
                  size: 13,
                  color: VaultColors.paper.withValues(alpha: 0.65),
                  weight: FontWeight.w400,
                ),
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
                      label: 'RESTART',
                      fontSize: 13,
                      verticalPadding: 17,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _failModalOpen = false;
                        _game.restartStage();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    _failModalOpen = false;
  }

  void _onBubbleTap(int bubbleId) {
    if (_game.phase != RoadPhase.playing) return;
    final ok = _game.onBubbleTapped(bubbleId);
    if (ok) {
      HapticFeedback.lightImpact();
      _audio.playPop();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  BubbleVisualState _stateFor(int bubbleId) {
    if (_game.activeBatch.contains(bubbleId)) {
      return BubbleVisualState.cued;
    }
    if (_game.popped.contains(bubbleId)) {
      return BubbleVisualState.popped;
    }
    return BubbleVisualState.idle;
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
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
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VaultColors.roomGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: VaultColors.paper,
                    ),
                    const Spacer(),
                    Text(
                      'ROAD TO GLORY',
                      style: vaultLabel(
                        size: 12,
                        color: VaultColors.gold,
                        tracking: 0.28,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _HudChip(
                        label: 'GRID',
                        value: _game.gridLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HudChip(
                        label: 'BATCH',
                        value: '×${_game.batchSize}',
                        emphasize: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HudChip(
                        label: 'LEFT',
                        value: '${_game.remaining}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap every glowing stone — any order. Miss once and restart.',
                  textAlign: TextAlign.center,
                  style: vaultLabel(
                    size: 11,
                    color: VaultColors.paper.withValues(alpha: 0.5),
                    weight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: PopItBoard(
                        key: ValueKey(_game.gridLabel),
                        rows: _game.rows,
                        cols: _game.cols,
                        stateForBubble: _stateFor,
                        onBubbleTap: _onBubbleTap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: emphasize
            ? VaultColors.magenta.withValues(alpha: 0.18)
            : VaultColors.paper.withValues(alpha: 0.06),
        border: Border.all(
          color: emphasize
              ? VaultColors.magenta.withValues(alpha: 0.35)
              : VaultColors.paper.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: vaultLabel(
              size: 9,
              color: VaultColors.paper.withValues(alpha: 0.45),
              tracking: 0.24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: vaultDisplay(
              size: 20,
              color: emphasize ? VaultColors.gold : VaultColors.paper,
            ),
          ),
        ],
      ),
    );
  }
}
