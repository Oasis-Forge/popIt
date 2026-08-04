import '../game/models.dart';

/// Deterministic density shaping from one master chart.
List<Note> applyDensity(List<Note> master, DensityProfile profile) {
  final kept = <Note>[
    for (final n in master)
      if (n.weight <= profile.maxWeight) n,
  ]..sort((a, b) => a.tMs.compareTo(b.tMs));

  if (profile.minGapMs <= 0) {
    return [
      for (var i = 0; i < kept.length; i++) kept[i].copyWith(id: i),
    ];
  }

  final out = <Note>[];
  for (final note in kept) {
    if (out.isEmpty || note.tMs - out.last.tMs >= profile.minGapMs) {
      out.add(note.copyWith(id: out.length));
    }
  }
  return out;
}
