import 'dart:convert';

import 'chart_library.dart';
import 'models.dart';
import 'run_config.dart';
import '../services/versus_service.dart';

class DailyChallenge {
  const DailyChallenge({
    required this.ymd,
    required this.chartId,
    required this.difficulty,
    required this.mode,
  });

  final String ymd;
  final String chartId;
  final Difficulty difficulty;
  final GameMode mode;

  RunConfig toConfig({BoardLayout board = BoardLayout.standard}) => RunConfig(
        chartId: chartId,
        difficulty: difficulty,
        mode: mode,
        board: board,
        isDaily: true,
      );

  String get bestKey => 'daily|$ymd';

  static DailyChallenge forToday(ChartLibrary library, [DateTime? now]) {
    return resolve(library, VersusService.dailySeed(now));
  }

  static DailyChallenge resolve(ChartLibrary library, String ymd) {
    final charts = library.songCharts;
    if (charts.isEmpty) {
      return DailyChallenge(
        ymd: ymd,
        chartId: 'demo_beat',
        difficulty: Difficulty.normal,
        mode: GameMode.classic,
      );
    }
    final hash = utf8.encode(ymd).fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final chart = charts[hash % charts.length];
    const diffs = Difficulty.values;
    const modes = [
      GameMode.classic,
      GameMode.survival,
      GameMode.precision,
      GameMode.endlessRush,
    ];
    // Bias toward classic/survival; still rotate all four over the week.
    final difficulty = diffs[(hash ~/ 7) % diffs.length];
    final mode = modes[(hash ~/ 13) % modes.length];
    return DailyChallenge(
      ymd: ymd,
      chartId: chart.id,
      difficulty: difficulty,
      mode: mode,
    );
  }

  String blurb(ChartLibrary library) {
    final title = library.byId(chartId).title;
    return '$title · ${difficulty.name} · ${_modeShort(mode)}';
  }

  static String _modeShort(GameMode m) => switch (m) {
        GameMode.classic => 'Classic',
        GameMode.survival => 'Survival',
        GameMode.precision => 'Precision',
        GameMode.endlessRush => 'Endless',
      };
}
