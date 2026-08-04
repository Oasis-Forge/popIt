import 'models.dart';

export 'chart_shaper.dart' show applyDensity;

class RunConfig {
  const RunConfig({
    required this.chartId,
    this.difficulty = Difficulty.normal,
    this.mode = GameMode.classic,
    this.board = BoardLayout.standard,
    this.versusRoom,
    this.isDaily = false,
  });

  final String chartId;
  final Difficulty difficulty;
  final GameMode mode;
  final BoardLayout board;
  final String? versusRoom;
  final bool isDaily;

  DifficultyConfig get difficultyConfig => DifficultyConfig.map[difficulty]!;
}
