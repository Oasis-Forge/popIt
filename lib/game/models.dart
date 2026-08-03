enum Judgement { perfect, good, miss }

class Note {
  const Note({
    required this.id,
    required this.tMs,
    required this.bubbleId,
  });

  final int id;
  final int tMs;
  final int bubbleId;

  factory Note.fromJson(Map<String, dynamic> json, int id) {
    return Note(
      id: id,
      tMs: json['tMs'] as int,
      bubbleId: json['bubbleId'] as int,
    );
  }
}

class Chart {
  const Chart({
    required this.title,
    required this.audioAsset,
    required this.durationMs,
    required this.notes,
  });

  final String title;
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

class RhythmTiming {
  static const perfectWindowMs = 45;
  static const goodWindowMs = 120;
  static const cueLeadMs = 350;
  static const perfectScore = 100;
  static const goodScore = 50;
}
