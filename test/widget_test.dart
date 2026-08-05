import 'package:flutter_test/flutter_test.dart';
import 'package:pop_it/app/app_scope.dart';
import 'package:pop_it/data/player_profile.dart';
import 'package:pop_it/game/chart_library.dart';
import 'package:pop_it/game/chart_shaper.dart';
import 'package:pop_it/game/game_rules.dart';
import 'package:pop_it/game/models.dart';
import 'package:pop_it/game/rhythm_controller.dart';
import 'package:pop_it/main.dart';
import 'package:pop_it/services/games_service.dart';
import 'package:pop_it/services/settings_controller.dart';
import 'package:pop_it/services/versus_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> testServices() async {
  SharedPreferences.setMockInitialValues({});
  return AppServices(
    settingsController: SettingsController(SettingsStore(), AppSettings()),
    profileController: ProfileController(ProfileStore(), PlayerProfile()),
    chartLibrary: ChartLibrary(const [
      ChartMeta(
        id: 'demo_beat',
        title: 'Demo Beat',
        artist: 'Pop It',
        bpm: 120,
        durationMs: 32000,
        audioAsset: 'assets/audio/demo_beat.wav',
        chartAsset: 'assets/charts/demo.json',
      ),
    ]),
    gamesService: GamesService(),
    versusService: VersusService(),
  );
}

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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows Pop It brand and modes', (WidgetTester tester) async {
    final services = await testServices();
    await tester.pumpWidget(PopItApp(services: services));
    await tester.pump();

    expect(find.textContaining('POP'), findsWidgets);
    expect(find.text('RHYTHM'), findsOneWidget);
    expect(find.text('ROAD TO GLORY'), findsOneWidget);
  });

  group('RhythmController', () {
    test('Perfect hit scores and pops bubble', () {
      final rhythm = RhythmController(
        chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 3)]),
      )..updateTime(1000);
      final hit = rhythm.onBubbleTapped(3)!;
      expect(hit.judgement, Judgement.perfect);
      expect(rhythm.combo, 1);
    });

    test('Wrong tap is a miss and breaks combo', () {
      final rhythm = RhythmController(
        chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 3)]),
      )..updateTime(1000);
      rhythm.onBubbleTapped(3);
      final miss = rhythm.onBubbleTapped(7)!;
      expect(miss.judgement, Judgement.miss);
      expect(rhythm.combo, 0);
    });

    test('Expired note auto-misses', () {
      final rhythm = RhythmController(
        chart: chartWith([const Note(id: 0, tMs: 1000, bubbleId: 2)]),
      )..updateTime(1000 + RhythmTiming.goodWindowMs + 1);
      expect(rhythm.missCount, 1);
    });

    test('Track completes when duration elapses and notes resolve', () {
      final rhythm = RhythmController(
        chart: chartWith(
          [const Note(id: 0, tMs: 500, bubbleId: 1)],
          durationMs: 1000,
        ),
      );
      rhythm.updateTime(500);
      rhythm.onBubbleTapped(1);
      rhythm.updateTime(1000);
      expect(rhythm.finished, isTrue);
    });

    test('Survival ends after 5 misses', () {
      final notes = [
        for (var i = 0; i < 5; i++)
          Note(id: i, tMs: 1000 + i * 400, bubbleId: i),
      ];
      final rhythm = RhythmController(
        chart: chartWith(notes, durationMs: 10000),
        rules: const SurvivalRules(),
      );
      for (var i = 0; i < 5; i++) {
        rhythm.updateTime(1000 + i * 400);
        rhythm.onBubbleTapped(99);
      }
      expect(rhythm.finished, isTrue);
      expect(rhythm.lives, 0);
    });
  });

  test('applyDensity is deterministic', () {
    final master = [
      for (var i = 0; i < 20; i++)
        Note(id: i, tMs: i * 100, bubbleId: i % 5, weight: (i % 3) + 1),
    ];
    final a =
        applyDensity(master, const DensityProfile(maxWeight: 2, minGapMs: 150));
    final b =
        applyDensity(master, const DensityProfile(maxWeight: 2, minGapMs: 150));
    expect(
      a.map((n) => '${n.tMs}:${n.bubbleId}').toList(),
      b.map((n) => '${n.tMs}:${n.bubbleId}').toList(),
    );
  });
}
