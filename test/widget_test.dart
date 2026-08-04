import 'package:flutter_test/flutter_test.dart';

import 'package:pop_it/game/models.dart';
import 'package:pop_it/game/rhythm_controller.dart';
import 'package:pop_it/main.dart';

void main() {
  testWidgets('Home shows Pop It brand and Play', (WidgetTester tester) async {
    await tester.pumpWidget(const PopItApp());
    await tester.pump();

    expect(find.textContaining('POP'), findsWidgets);
    expect(find.text('RHYTHM'), findsOneWidget);
    expect(find.text('ROAD TO GLORY'), findsOneWidget);
  });

  group('RhythmController', () {
    Chart chartWith(List<Note> notes, {int durationMs = 5000}) {
      return Chart(
        title: 'Test',
        audioAsset: 'assets/audio/demo_beat.wav',
        durationMs: durationMs,
        notes: notes,
      );
    }

    test('Perfect hit scores and pops bubble', () {
      final chart = chartWith([
        const Note(id: 0, tMs: 1000, bubbleId: 3),
      ]);
      final rhythm = RhythmController(chart: chart);
      rhythm.updateTime(1000);
      expect(rhythm.cuedBubbleIds.contains(3), isTrue);

      final hit = rhythm.onBubbleTapped(3)!;
      expect(hit.judgement, Judgement.perfect);
      expect(hit.points, RhythmTiming.perfectScore);
      expect(rhythm.score, RhythmTiming.perfectScore);
      expect(rhythm.combo, 1);
      expect(rhythm.poppedBubbleIds.contains(3), isTrue);
    });

    test('Wrong tap is a miss and breaks combo', () {
      final chart = chartWith([
        const Note(id: 0, tMs: 1000, bubbleId: 3),
      ]);
      final rhythm = RhythmController(chart: chart);
      rhythm.updateTime(1000);
      rhythm.onBubbleTapped(3);
      expect(rhythm.combo, 1);

      rhythm.updateTime(1000);
      final miss = rhythm.onBubbleTapped(7)!;
      expect(miss.judgement, Judgement.miss);
      expect(rhythm.combo, 0);
      expect(rhythm.missCount, 1);
    });

    test('Expired note auto-misses', () {
      final chart = chartWith([
        const Note(id: 0, tMs: 1000, bubbleId: 2),
      ]);
      final rhythm = RhythmController(chart: chart);
      rhythm.updateTime(1000 + RhythmTiming.goodWindowMs + 1);
      expect(rhythm.missCount, 1);
      expect(rhythm.finished, isFalse);
    });

    test('Track completes when duration elapses and notes resolve', () {
      final chart = chartWith(
        [const Note(id: 0, tMs: 500, bubbleId: 1)],
        durationMs: 1000,
      );
      final rhythm = RhythmController(chart: chart);
      rhythm.updateTime(500);
      rhythm.onBubbleTapped(1);
      rhythm.updateTime(1000);
      expect(rhythm.finished, isTrue);
    });
  });
}
