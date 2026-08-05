import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';
import '../game/widgets/vault_decor.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _deltas = <int>[];
  DateTime? _lastBeat;
  bool _running = false;

  void _toggle() {
    setState(() {
      _running = !_running;
      if (_running) {
        _deltas.clear();
        _scheduleBeat();
      }
    });
  }

  void _scheduleBeat() {
    if (!_running) return;
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_running) return;
      _lastBeat = DateTime.now();
      HapticFeedback.selectionClick();
      setState(() {});
      _scheduleBeat();
    });
  }

  void _tap() {
    final beat = _lastBeat;
    if (beat == null) return;
    final delta = DateTime.now().difference(beat).inMilliseconds;
    // Negative => tapped early relative to beat.
    final signed = delta > 250 ? delta - 500 : delta;
    setState(() => _deltas.add(signed));
  }

  int get _median {
    if (_deltas.isEmpty) return 0;
    final sorted = [..._deltas]..sort();
    return sorted[sorted.length ~/ 2];
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    final services = AppScope.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: v.roomGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: v.paper,
                    ),
                    const Spacer(),
                    Text('CALIBRATION', style: vaultLabel(size: 12, color: v.gold)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const Spacer(),
                Text(
                  _deltas.length < 16
                      ? 'Tap with the pulse ($_deltas.length / 16)'
                      : 'You tap ${_median}ms ${_median <= 0 ? "early" : "late"}',
                  textAlign: TextAlign.center,
                  style: vaultDisplay(size: 22),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _running ? _tap : null,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: v.ctaGradient,
                    ),
                    alignment: Alignment.center,
                    child: Text('TAP', style: vaultDisplay(size: 28, color: v.ink)),
                  ),
                ),
                const Spacer(),
                VaultCta(
                  label: _running ? 'STOP' : 'START',
                  onPressed: _toggle,
                ),
                const SizedBox(height: 12),
                if (_deltas.length >= 8)
                  VaultCta(
                    label: 'SAVE OFFSET ($_median ms)',
                    onPressed: () {
                      services.settings.update((s) => s.audioOffsetMs = _median);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
