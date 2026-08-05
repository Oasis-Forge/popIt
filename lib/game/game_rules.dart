import 'models.dart';

abstract class GameRules {
  const GameRules();

  int get startingLives;
  bool get requirePerfect;
  bool get loops;

  TimingConfig timingForLoop(int loop, TimingConfig base);

  int scoreFor(Judgement judgement, int combo) {
    if (judgement == Judgement.miss) return 0;
    if (requirePerfect && judgement != Judgement.perfect) return 0;
    final base = judgement == Judgement.perfect ? 100 : 50;
    final multiplier = 1 + (combo ~/ 10) * 0.1;
    return (base * multiplier).round();
  }

  bool isRunOver({
    required int lives,
    required int missCount,
    required bool chartFinished,
  });
}

class ClassicRules extends GameRules {
  const ClassicRules();

  @override
  int get startingLives => 0;

  @override
  bool get requirePerfect => false;

  @override
  bool get loops => false;

  @override
  TimingConfig timingForLoop(int loop, TimingConfig base) => base;

  @override
  bool isRunOver({
    required int lives,
    required int missCount,
    required bool chartFinished,
  }) =>
      chartFinished;
}

class SurvivalRules extends GameRules {
  const SurvivalRules();

  @override
  int get startingLives => 5;

  @override
  bool get requirePerfect => false;

  @override
  bool get loops => false;

  @override
  TimingConfig timingForLoop(int loop, TimingConfig base) => base;

  @override
  bool isRunOver({
    required int lives,
    required int missCount,
    required bool chartFinished,
  }) =>
      lives <= 0 || chartFinished;
}

class PrecisionRules extends GameRules {
  const PrecisionRules();

  @override
  int get startingLives => 0;

  @override
  bool get requirePerfect => true;

  @override
  bool get loops => false;

  @override
  TimingConfig timingForLoop(int loop, TimingConfig base) => base;

  @override
  bool isRunOver({
    required int lives,
    required int missCount,
    required bool chartFinished,
  }) =>
      chartFinished;
}

class EndlessRushRules extends GameRules {
  const EndlessRushRules();

  @override
  int get startingLives => 3;

  @override
  bool get requirePerfect => false;

  @override
  bool get loops => true;

  @override
  TimingConfig timingForLoop(int loop, TimingConfig base) {
    final scale = (1 - 0.08 * loop).clamp(0.4, 1.0);
    return TimingConfig(
      perfectWindowMs: (base.perfectWindowMs * scale).round(),
      goodWindowMs: (base.goodWindowMs * scale).round(),
      cueLeadMs: base.cueLeadMs,
    );
  }

  @override
  bool isRunOver({
    required int lives,
    required int missCount,
    required bool chartFinished,
  }) =>
      lives <= 0;
}

GameRules rulesFor(GameMode mode) => switch (mode) {
      GameMode.classic => const ClassicRules(),
      GameMode.survival => const SurvivalRules(),
      GameMode.precision => const PrecisionRules(),
      GameMode.endlessRush => const EndlessRushRules(),
    };
