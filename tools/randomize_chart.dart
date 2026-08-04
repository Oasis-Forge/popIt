import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final raw = jsonDecode(File('assets/charts/demo.json').readAsStringSync())
      as Map<String, dynamic>;
  final notes = (raw['notes'] as List).cast<Map<String, dynamic>>();
  final rng = Random(42);
  var prev = -1;
  for (final note in notes) {
    var id = rng.nextInt(20);
    var guard = 0;
    while (id == prev && guard < 10) {
      id = rng.nextInt(20);
      guard++;
    }
    note['bubbleId'] = id;
    prev = id;
  }
  const encoder = JsonEncoder.withIndent('  ');
  File('assets/charts/demo.json').writeAsStringSync('${encoder.convert(raw)}\n');
  stdout.writeln('Rewrote ${notes.length} notes with random bubbleIds');
}
