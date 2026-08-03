import 'package:flutter/foundation.dart';

import 'models.dart';

class RhythmController extends ChangeNotifier {
  RhythmController({required Chart chart}) : _chart = chart {
    _pending = List<Note>.from(chart.notes);
  }

  final Chart _chart;
  late List<Note> _pending;
  final Set<int> _resolvedIds = {};
  final Set<int> _cuedBubbleIds = {};
  final Set<int> _poppedBubbleIds = {};
  final Set<int> _missFlashBubbleIds = {};

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _perfectCount = 0;
  int _goodCount = 0;
  int _missCount = 0;
  int _positionMs = 0;
  bool _finished = false;
  Judgement? _lastJudgement;
  int _judgementToken = 0;

  Chart get chart => _chart;
  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get perfectCount => _perfectCount;
  int get goodCount => _goodCount;
  int get missCount => _missCount;
  int get positionMs => _positionMs;
  bool get finished => _finished;
  Judgement? get lastJudgement => _lastJudgement;
  int get judgementToken => _judgementToken;
  Set<int> get cuedBubbleIds => _cuedBubbleIds;
  Set<int> get poppedBubbleIds => _poppedBubbleIds;
  Set<int> get missFlashBubbleIds => _missFlashBubbleIds;

  int get totalNotes => _chart.notes.length;

  double get accuracy {
    if (totalNotes == 0) return 0;
    final hits = _perfectCount + _goodCount;
    return hits / totalNotes;
  }

  void updateTime(int positionMs) {
    if (_finished) return;
    _positionMs = positionMs;
    _refreshCues();
    _autoMissExpired();
    if (positionMs >= _chart.durationMs && _pending.isEmpty) {
      _finished = true;
    }
    notifyListeners();
  }

  HitResult? onBubbleTapped(int bubbleId) {
    if (_finished) return null;

    Note? best;
    var bestAbs = 1 << 30;
    for (final note in _pending) {
      if (note.bubbleId != bubbleId) continue;
      final delta = _positionMs - note.tMs;
      final abs = delta.abs();
      if (abs <= RhythmTiming.goodWindowMs && abs < bestAbs) {
        best = note;
        bestAbs = abs;
      }
    }

    if (best == null) {
      _registerMiss(bubbleId: bubbleId, fromTap: true);
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
    final judgement = abs <= RhythmTiming.perfectWindowMs
        ? Judgement.perfect
        : Judgement.good;

    _resolveNote(best);
    final points = _applyHit(judgement);
    _poppedBubbleIds.add(bubbleId);
    _missFlashBubbleIds.remove(bubbleId);
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

  void clearTransientFlash(int bubbleId) {
    if (_missFlashBubbleIds.remove(bubbleId)) {
      notifyListeners();
    }
  }

  void reset() {
    _pending = List<Note>.from(_chart.notes);
    _resolvedIds.clear();
    _cuedBubbleIds.clear();
    _poppedBubbleIds.clear();
    _missFlashBubbleIds.clear();
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _perfectCount = 0;
    _goodCount = 0;
    _missCount = 0;
    _positionMs = 0;
    _finished = false;
    _lastJudgement = null;
    _judgementToken = 0;
    notifyListeners();
  }

  void _refreshCues() {
    _cuedBubbleIds.clear();
    for (final note in _pending) {
      final start = note.tMs - RhythmTiming.cueLeadMs;
      final end = note.tMs + RhythmTiming.goodWindowMs;
      if (_positionMs >= start && _positionMs < end) {
        _cuedBubbleIds.add(note.bubbleId);
      }
    }
    // Allow the same bubble to rise again for later notes.
    _poppedBubbleIds.removeAll(_cuedBubbleIds);
  }

  void _autoMissExpired() {
    final expired = <Note>[];
    for (final note in _pending) {
      if (_positionMs > note.tMs + RhythmTiming.goodWindowMs) {
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

  int _applyHit(Judgement judgement) {
    _combo += 1;
    if (_combo > _maxCombo) _maxCombo = _combo;
    final multiplier = 1 + (_combo ~/ 10) * 0.1;
    final base = judgement == Judgement.perfect
        ? RhythmTiming.perfectScore
        : RhythmTiming.goodScore;
    final points = (base * multiplier).round();
    _score += points;
    if (judgement == Judgement.perfect) {
      _perfectCount += 1;
    } else {
      _goodCount += 1;
    }
    return points;
  }

  void _registerMiss({required int bubbleId, required bool fromTap}) {
    _combo = 0;
    _missCount += 1;
    _missFlashBubbleIds.add(bubbleId);
    _setJudgement(Judgement.miss);
    if (!fromTap) {
      // Auto-miss still flashes the bubble that was expected.
    }
  }

  void _setJudgement(Judgement judgement) {
    _lastJudgement = judgement;
    _judgementToken += 1;
  }
}
