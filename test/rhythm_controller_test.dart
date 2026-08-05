import 'package:flutter_test/flutter_test.dart';
import 'package:pop_it/game/models.dart';
import 'package:pop_it/game/rhythm_controller.dart';

Chart chartWith(List<Note> notes, {int durationMs = 5000}) {
  return Chart(
    id: 'test',
    title: 'Test',
    artist: 'QA',
    bpm: 120,
    audioAsset: 'assets/audio/demo_beat.wav',
    durationMs: durationMs,
    notes: notes,
  );
}

void main() {
  test('Perfect hit within perfect window', () {
    final rhythm = RhythmController(
      chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 3)]),
    )..updateTime(1000);
    final hit = rhythm.onBubbleTapped(3)!;
    expect(hit.judgement, Judgement.perfect);
    expect(hit.points, RhythmTiming.perfectScore);
    expect(rhythm.combo, 1);
  });

  test('Good hit at perfect boundary edge', () {
    final rhythm = RhythmController(
      chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 3)]),
    )..updateTime(1000 + RhythmTiming.perfectWindowMs + 1);
    final hit = rhythm.onBubbleTapped(3)!;
    expect(hit.judgement, Judgement.good);
    expect(hit.points, RhythmTiming.goodScore);
  });

  test('Miss outside good window via wrong bubble', () {
    final rhythm = RhythmController(
      chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 3)]),
    )..updateTime(1000);
    final hit = rhythm.onBubbleTapped(7)!;
    expect(hit.judgement, Judgement.miss);
    expect(rhythm.combo, 0);
    expect(rhythm.missCount, 1);
  });

  test('Auto-miss past good window', () {
    final rhythm = RhythmController(
      chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 2)]),
    )..updateTime(1000 + RhythmTiming.goodWindowMs + 1);
    expect(rhythm.missCount, 1);
  });

  test('Combo multiplier steps every 10', () {
    final notes = [
      for (var i = 0; i < 11; i++)
        Note(id: i, tMs: 1000 + i * 500, bubbleId: i % 20),
    ];
    final rhythm = RhythmController(chart: chartWith(notes, durationMs: 20000));
    var expectedScore = 0;
    for (var i = 0; i < 11; i++) {
      rhythm.updateTime(1000 + i * 500);
      final hit = rhythm.onBubbleTapped(i % 20)!;
      expect(hit.judgement, Judgement.perfect);
      final combo = i + 1;
      final multiplier = 1 + (combo ~/ 10) * 0.1;
      expectedScore += (RhythmTiming.perfectScore * multiplier).round();
      expect(rhythm.score, expectedScore);
    }
    expect(rhythm.combo, 11);
    expect(rhythm.maxCombo, 11);
  });

  test('Re-cue clears popped state for same bubble', () {
    final rhythm = RhythmController(
      chart: chartWith([
        const Note(id: 0, tMs: 1000, bubbleId: 5),
        const Note(id: 1, tMs: 2000, bubbleId: 5),
      ], durationMs: 4000),
    );
    rhythm.updateTime(1000);
    rhythm.onBubbleTapped(5);
    expect(rhythm.poppedBubbleIds.contains(5), isTrue);
    rhythm.updateTime(2000 - RhythmTiming.cueLeadMs);
    expect(rhythm.cuedBubbleIds.contains(5), isTrue);
    expect(rhythm.poppedBubbleIds.contains(5), isFalse);
  });

  test('reset clears score and pending notes', () {
    final rhythm = RhythmController(
      chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 1)]),
    )..updateTime(1000);
    rhythm.onBubbleTapped(1);
    rhythm.reset();
    expect(rhythm.score, 0);
    expect(rhythm.combo, 0);
    expect(rhythm.poppedBubbleIds, isEmpty);
    expect(rhythm.finished, isFalse);
    rhythm.updateTime(1000);
    expect(rhythm.cuedBubbleIds.contains(1), isTrue);
  });
}
