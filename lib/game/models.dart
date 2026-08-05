enum Judgement { perfect, good, miss }

enum Difficulty { easy, normal, hard, expert }

enum GameMode { classic, survival, precision, endlessRush }

class Note {
  const Note({
    required this.id,
    required this.tMs,
    required this.bubbleId,
    this.weight = 1,
  });

  final int id;
  final int tMs;
  final int bubbleId;
  final int weight;

  factory Note.fromJson(Map<String, dynamic> json, int id) {
    return Note(
      id: id,
      tMs: json['tMs'] as int,
      bubbleId: json['bubbleId'] as int,
      weight: json['weight'] as int? ?? 1,
    );
  }

  Note copyWith({int? id, int? tMs, int? bubbleId, int? weight}) => Note(
        id: id ?? this.id,
        tMs: tMs ?? this.tMs,
        bubbleId: bubbleId ?? this.bubbleId,
        weight: weight ?? this.weight,
      );
}

class Chart {
  const Chart({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.audioAsset,
    required this.durationMs,
    required this.notes,
  });

  final String id;
  final String title;
  final String artist;
  final int bpm;
  final String audioAsset;
  final int durationMs;
  final List<Note> notes;
}

class HitResult {
  const HitResult({
    required this.judgement,
    required this.deltaMs,
    required this.bubbleId,
    required this.points,
  });

  final Judgement judgement;
  final int deltaMs;
  final int bubbleId;
  final int points;
}

class TimingConfig {
  const TimingConfig({
    required this.perfectWindowMs,
    required this.goodWindowMs,
    required this.cueLeadMs,
  });

  final int perfectWindowMs;
  final int goodWindowMs;
  final int cueLeadMs;
}

class DensityProfile {
  const DensityProfile({required this.maxWeight, required this.minGapMs});
  final int maxWeight;
  final int minGapMs;
}

class DifficultyConfig {
  const DifficultyConfig({
    required this.difficulty,
    required this.timing,
    required this.density,
  });

  final Difficulty difficulty;
  final TimingConfig timing;
  final DensityProfile density;

  static const map = <Difficulty, DifficultyConfig>{
    Difficulty.easy: DifficultyConfig(
      difficulty: Difficulty.easy,
      timing: TimingConfig(perfectWindowMs: 70, goodWindowMs: 170, cueLeadMs: 700),
      density: DensityProfile(maxWeight: 1, minGapMs: 400),
    ),
    Difficulty.normal: DifficultyConfig(
      difficulty: Difficulty.normal,
      timing: TimingConfig(perfectWindowMs: 45, goodWindowMs: 120, cueLeadMs: 550),
      density: DensityProfile(maxWeight: 2, minGapMs: 260),
    ),
    Difficulty.hard: DifficultyConfig(
      difficulty: Difficulty.hard,
      timing: TimingConfig(perfectWindowMs: 32, goodWindowMs: 95, cueLeadMs: 450),
      density: DensityProfile(maxWeight: 3, minGapMs: 150),
    ),
    Difficulty.expert: DifficultyConfig(
      difficulty: Difficulty.expert,
      timing: TimingConfig(perfectWindowMs: 22, goodWindowMs: 70, cueLeadMs: 380),
      density: DensityProfile(maxWeight: 3, minGapMs: 0),
    ),
  };
}

/// Legacy alias used until all call sites migrate to TimingConfig.
class RhythmTiming {
  static const perfectWindowMs = 45;
  static const goodWindowMs = 120;
  static const cueLeadMs = 550;
  static const perfectScore = 100;
  static const goodScore = 50;
}

class BoardLayout {
  const BoardLayout(this.rows, this.cols);
  final int rows;
  final int cols;
  int get total => rows * cols;
  static const standard = BoardLayout(4, 5);
  static const casual = BoardLayout(3, 3);
}

class RunResult {
  const RunResult({
    required this.score,
    required this.maxCombo,
    required this.perfect,
    required this.good,
    required this.miss,
    required this.accuracy,
    required this.grade,
    this.livesRemaining,
    this.loopsCompleted = 0,
  });

  final int score;
  final int maxCombo;
  final int perfect;
  final int good;
  final int miss;
  final double accuracy;
  final String grade;
  final int? livesRemaining;
  final int loopsCompleted;
}
