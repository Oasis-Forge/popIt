import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  Directory('assets/audio').createSync(recursive: true);
  File('assets/audio/pop.wav').writeAsBytesSync(makePop());
  File('assets/audio/lose.wav').writeAsBytesSync(makeLose());
  File('assets/audio/demo_beat.wav').writeAsBytesSync(makeBeat());
  stdout.writeln('Wrote pop.wav, lose.wav, and demo_beat.wav');
}

Uint8List makePop() {
  const sampleRate = 22050;
  const durationSec = 0.09;
  final n = (sampleRate * durationSec).round();
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = exp(-38 * t);
    final tone = sin(2 * pi * 520 * t) * 0.55 + sin(2 * pi * 180 * t) * 0.35;
    samples[i] = tone * env;
  }
  return encodeWav(samples, sampleRate);
}

Uint8List makeLose() {
  const sampleRate = 22050;
  const durationSec = 0.35;
  final n = (sampleRate * durationSec).round();
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = exp(-6 * t);
    final freq = 320 - 180 * (t / durationSec);
    final tone = sin(2 * pi * freq * t) * 0.7 + sin(2 * pi * freq * 0.5 * t) * 0.3;
    samples[i] = tone * env;
  }
  return encodeWav(samples, sampleRate);
}

Uint8List makeBeat() {
  const sampleRate = 22050;
  const bpm = 120;
  const beats = 64;
  final beatMs = (60000 / bpm).round();
  final totalSamples = (sampleRate * (beats * beatMs / 1000)).round();
  final samples = Float64List(totalSamples);

  for (var beat = 0; beat < beats; beat++) {
    final start = ((beat * beatMs) / 1000 * sampleRate).round();
    final isDownbeat = beat % 4 == 0;
    final freq = isDownbeat ? 90.0 : 140.0;
    final amp = isDownbeat ? 0.9 : 0.55;
    final clickLen = (sampleRate * 0.08).round();
    for (var i = 0; i < clickLen && start + i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-45 * t);
      samples[start + i] += sin(2 * pi * freq * t) * amp * env;
      samples[start + i] += sin(2 * pi * 900 * t) * 0.12 * env;
    }
  }
  return encodeWav(samples, sampleRate);
}

Uint8List encodeWav(Float64List samples, int sampleRate) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}
