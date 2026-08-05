import 'package:flutter/foundation.dart';

import 'game_rules.dart';
import 'models.dart';

class RhythmController extends ChangeNotifier {
  RhythmController({
    required Chart chart,
    TimingConfig? timing,
    GameRules rules = const ClassicRules(),
  })  : _chart = chart,
        _baseTiming = timing ??
            const TimingConfig(
              perfectWindowMs: RhythmTiming.perfectWindowMs,
              goodWindowMs: RhythmTiming.goodWindowMs,
              cueLeadMs: RhythmTiming.cueLeadMs,
            ),
        _rules = rules {
    _pending = List<Note>.from(chart.notes);
    _lives = rules.startingLives;
  }

  final Chart _chart;
  final TimingConfig _baseTiming;
  final GameRules _rules;
  late List<Note> _pending;
  final Set<int> _resolvedIds = {};
  final Set<int> _cuedBubbleIds = {};
  final Set<int> _poppedBubbleIds = {};

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _perfectCount = 0;
  int _goodCount = 0;
  int _missCount = 0;
  int _positionMs = 0;
  int _lastDeltaMs = 0;
  int _loop = 0;
  int _lives = 0;
  bool _finished = false;
  Judgement? _lastJudgement;
  int _judgementToken = 0;

  final ValueNotifier<int> position = ValueNotifier<int>(0);

  Chart get chart => _chart;
  GameRules get rules => _rules;
  TimingConfig get timing => _rules.timingForLoop(_loop, _baseTiming);
  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get perfectCount => _perfectCount;
  int get goodCount => _goodCount;
  int get missCount => _missCount;
  int get positionMs => _positionMs;
  int get lastDeltaMs => _lastDeltaMs;
  int get loop => _loop;
  int get lives => _lives;
  bool get finished => _finished;
  Judgement? get lastJudgement => _lastJudgement;
  int get judgementToken => _judgementToken;
  Set<int> get cuedBubbleIds => _cuedBubbleIds;
  Set<int> get poppedBubbleIds => _poppedBubbleIds;
  int get totalNotes => _chart.notes.length;

  double get accuracy {
    final denom = _perfectCount + _goodCount + _missCount;
    if (denom == 0) return 0;
    return (_perfectCount + _goodCount) / denom;
  }

  void updateTime(int positionMs) {
    if (_finished) return;
    final duration = _chart.durationMs;
    var localPos = positionMs;
    if (_rules.loops && duration > 0) {
      _loop = positionMs ~/ duration;
      localPos = positionMs % duration;
    }
    _positionMs = localPos;
    position.value = positionMs;
    _refreshCues();
    _autoMissExpired();
    final chartDone = !_rules.loops &&
        positionMs >= duration &&
        _pending.isEmpty;
    if (_rules.isRunOver(
          lives: _lives,
          missCount: _missCount,
          chartFinished: chartDone,
        )) {
      _finished = true;
    }
    // Keep HUD / approach rings live on the audio clock.
    notifyListeners();
  }

  /// 0 → just lit, 1 → on the beat. Null if bubble is not cued.
  double? cueProgressFor(int bubbleId) {
    final t = timing;
    Note? nearest;
    var bestAbs = 1 << 30;
    for (final note in _pending) {
      if (note.bubbleId != bubbleId) continue;
      final start = note.tMs - t.cueLeadMs;
      final end = note.tMs + t.goodWindowMs;
      if (_positionMs < start || _positionMs >= end) continue;
      final abs = (_positionMs - note.tMs).abs();
      if (abs < bestAbs) {
        bestAbs = abs;
        nearest = note;
      }
    }
    if (nearest == null) return null;
    final lead = t.cueLeadMs;
    if (lead <= 0) return 1;
    final elapsed = (_positionMs - (nearest.tMs - lead)).clamp(0, lead);
    return (elapsed / lead).clamp(0.0, 1.0);
  }

  HitResult? onBubbleTapped(int bubbleId) {
    if (_finished) return null;
    final t = timing;
    // Web/mobile audio clocks often lag a frame or two behind the tap.
    const lateGraceMs = 40;
    final hitWindow = t.goodWindowMs + lateGraceMs;

    Note? best;
    var bestAbs = 1 << 30;
    Note? earlyNote;
    var earlyDelta = 1 << 30; // how early (positive ms before note)

    for (final note in _pending) {
      if (note.bubbleId != bubbleId) continue;
      final delta = _positionMs - note.tMs; // negative = early
      final abs = delta.abs();
      if (abs <= hitWindow && abs < bestAbs) {
        best = note;
        bestAbs = abs;
      } else if (delta < 0 && -delta <= t.cueLeadMs && -delta < earlyDelta) {
        // Correct bubble is lit, but player tapped before the hit window.
        earlyNote = note;
        earlyDelta = -delta;
      }
    }

    if (best == null) {
      if (earlyNote != null) {
        // Too early on the right bubble — ignore, do not punish as a miss.
        return null;
      }
      _registerMiss(bubbleId: bubbleId, fromTap: true);
      _poppedBubbleIds.add(bubbleId);
      notifyListeners();
      return HitResult(
        judgement: Judgement.miss,
        deltaMs: 0,
        bubbleId: bubbleId,
        points: 0,
      );
    }

    final delta = _positionMs - best.tMs;
    final abs = delta.abs();
    // Perfect uses the authored window; late grace only expands Good, not Perfect.
    var judgement =
        abs <= t.perfectWindowMs ? Judgement.perfect : Judgement.good;
    if (_rules.requirePerfect && judgement == Judgement.good) {
      // Precision: GOOD awards no points and breaks combo.
      _resolveNote(best);
      _combo = 0;
      _goodCount += 1;
      _lastDeltaMs = delta;
      _setJudgement(Judgement.good);
      _poppedBubbleIds.add(bubbleId);
      _refreshCues();
      notifyListeners();
      return HitResult(
        judgement: Judgement.good,
        deltaMs: delta,
        bubbleId: bubbleId,
        points: 0,
      );
    }

    _resolveNote(best);
    _combo += 1;
    if (_combo > _maxCombo) _maxCombo = _combo;
    final points = _rules.scoreFor(judgement, _combo);
    _score += points;
    if (judgement == Judgement.perfect) {
      _perfectCount += 1;
    } else {
      _goodCount += 1;
    }
    _poppedBubbleIds.add(bubbleId);
    _lastDeltaMs = delta;
    _setJudgement(judgement);
    _refreshCues();
    notifyListeners();

    return HitResult(
      judgement: judgement,
      deltaMs: delta,
      bubbleId: bubbleId,
      points: points,
    );
  }

  void reset() {
    _pending = List<Note>.from(_chart.notes);
    _resolvedIds.clear();
    _cuedBubbleIds.clear();
    _poppedBubbleIds.clear();
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _perfectCount = 0;
    _goodCount = 0;
    _missCount = 0;
    _positionMs = 0;
    _lastDeltaMs = 0;
    _loop = 0;
    _lives = _rules.startingLives;
    _finished = false;
    _lastJudgement = null;
    _judgementToken = 0;
    position.value = 0;
    notifyListeners();
  }

  RunResult buildResult() {
    final grade = () {
      if (accuracy >= 0.98) return 'FLAWLESS';
      if (accuracy >= 0.9) return 'BRILLIANT';
      if (accuracy >= 0.75) return 'POLISHED';
      if (accuracy >= 0.5) return 'ROUGH CUT';
      return 'UNCUT';
    }();
    return RunResult(
      score: _score,
      maxCombo: _maxCombo,
      perfect: _perfectCount,
      good: _goodCount,
      miss: _missCount,
      accuracy: accuracy,
      grade: grade,
      livesRemaining: _rules.startingLives > 0 ? _lives : null,
      loopsCompleted: _loop,
    );
  }

  void _refreshCues() {
    final t = timing;
    _cuedBubbleIds.clear();
    for (final note in _pending) {
      final start = note.tMs - t.cueLeadMs;
      final end = note.tMs + t.goodWindowMs;
      if (_positionMs >= start && _positionMs < end) {
        _cuedBubbleIds.add(note.bubbleId);
      }
    }
    _poppedBubbleIds.removeAll(_cuedBubbleIds);
  }

  void _autoMissExpired() {
    final t = timing;
    final expired = <Note>[];
    for (final note in _pending) {
      if (_positionMs > note.tMs + t.goodWindowMs) {
        expired.add(note);
      }
    }
    for (final note in expired) {
      _resolveNote(note);
      _registerMiss(bubbleId: note.bubbleId, fromTap: false);
    }
  }

  void _resolveNote(Note note) {
    _pending.removeWhere((n) => n.id == note.id);
    _resolvedIds.add(note.id);
  }

  void _registerMiss({required int bubbleId, required bool fromTap}) {
    _combo = 0;
    _missCount += 1;
    _lastDeltaMs = 0;
    if (_rules.startingLives > 0) {
      _lives = (_lives - 1).clamp(0, 99);
    }
    _setJudgement(Judgement.miss);
    if (fromTap) {
      _poppedBubbleIds.add(bubbleId);
    }
    if (_rules.isRunOver(
      lives: _lives,
      missCount: _missCount,
      chartFinished: false,
    )) {
      _finished = true;
    }
  }

  void _setJudgement(Judgement judgement) {
    _lastJudgement = judgement;
    _judgementToken += 1;
  }

  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }
}
