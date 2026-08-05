import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates distinctive WAV tracks, hit-note bank, and matching charts.
void main() {
  Directory('assets/audio').createSync(recursive: true);
  Directory('assets/audio/hits').createSync(recursive: true);
  Directory('assets/charts').createSync(recursive: true);

  File('assets/audio/pop.wav').writeAsBytesSync(_makeSoftClick());
  File('assets/audio/lose.wav').writeAsBytesSync(_makeLose());

  // C major pentatonic: C4 D4 E4 G4 A4 C5 D5 E5
  const freqs = [
    261.63,
    293.66,
    329.63,
    392.00,
    440.00,
    523.25,
    587.33,
    659.25,
  ];
  for (var i = 0; i < freqs.length; i++) {
    File('assets/audio/hits/hit_$i.wav')
        .writeAsBytesSync(_makeHitNote(freqs[i], bright: i >= 4));
  }

  final tracks = <_TrackSpec>[
    _TrackSpec(
      id: 'demo_beat',
      title: 'Demo Beat',
      artist: 'Pop It',
      bpm: 120,
      durationMs: 32000,
      style: _BeatStyle.classic,
    ),
    _TrackSpec(
      id: 'neon_pulse',
      title: 'Neon Pulse',
      artist: 'Vault Labs',
      bpm: 128,
      durationMs: 30000,
      style: _BeatStyle.neon,
    ),
    _TrackSpec(
      id: 'velvet_groove',
      title: 'Velvet Groove',
      artist: 'Disco Room',
      bpm: 100,
      durationMs: 33600,
      style: _BeatStyle.velvet,
    ),
    _TrackSpec(
      id: 'rush_hour',
      title: 'Rush Hour',
      artist: 'Arcade Wire',
      bpm: 140,
      durationMs: 28800,
      style: _BeatStyle.rush,
    ),
  ];

  final manifestCharts = <Map<String, dynamic>>[];
  for (final track in tracks) {
    final audioPath = 'assets/audio/${track.id}.wav';
    final chartPath = 'assets/charts/${track.id}.json';
    File(audioPath).writeAsBytesSync(_makeTrack(track));
    final notes = _makeNotes(track);
    File(chartPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
            'title': track.title,
            'audioAsset': audioPath,
            'durationMs': track.durationMs,
            'notes': notes,
          })}\n',
    );
    manifestCharts.add({
      'id': track.id,
      'title': track.title,
      'artist': track.artist,
      'bpm': track.bpm,
      'durationMs': track.durationMs,
      'audioAsset': audioPath,
      'chartAsset': chartPath,
    });
    stdout.writeln('Wrote ${track.id}: ${notes.length} notes @ ${track.bpm}bpm');
  }

  File('assets/charts/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'charts': manifestCharts})}\n',
  );
  stdout.writeln('Wrote tracks, hit bank (8 notes), charts, manifest');
}

enum _BeatStyle { classic, neon, velvet, rush }

class _TrackSpec {
  const _TrackSpec({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.durationMs,
    required this.style,
  });

  final String id;
  final String title;
  final String artist;
  final int bpm;
  final int durationMs;
  final _BeatStyle style;
}

Uint8List _makeSoftClick() {
  const sampleRate = 22050;
  final n = (sampleRate * 0.05).round();
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = exp(-55 * t);
    samples[i] = sin(2 * pi * 680 * t) * 0.35 * env;
  }
  return _encodeWav(samples, sampleRate);
}

Uint8List _makeLose() {
  const sampleRate = 22050;
  final n = (sampleRate * 0.28).round();
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = exp(-7 * t);
    final freq = 240 - 120 * (i / n);
    samples[i] = (sin(2 * pi * freq * t) * 0.55 +
            sin(2 * pi * freq * 0.5 * t) * 0.25) *
        env;
  }
  return _encodeWav(samples, sampleRate);
}

/// Musical bubble hit — pitched tone with soft pluck attack.
Uint8List _makeHitNote(double freq, {required bool bright}) {
  const sampleRate = 22050;
  final n = (sampleRate * 0.22).round();
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = exp(-9 * t) * (1 - 0.15 * (i / n));
    final pluck = exp(-70 * t);
    var s = sin(2 * pi * freq * t) * 0.55;
    s += sin(2 * pi * freq * 2 * t) * (bright ? 0.22 : 0.12);
    s += sin(2 * pi * freq * 3 * t) * (bright ? 0.08 : 0.04);
    s += sin(2 * pi * (freq * 1.01) * t) * 0.08; // slight chorus
    s += (sin(2 * pi * 1200 * t) * 0.12) * pluck; // click attack
    samples[i] = s * env;
  }
  return _encodeWav(samples, sampleRate);
}

Uint8List _makeTrack(_TrackSpec track) {
  const sampleRate = 22050;
  final beatMs = 60000 / track.bpm;
  final totalSamples = (sampleRate * (track.durationMs / 1000)).round();
  final samples = Float64List(totalSamples);
  final beats = (track.durationMs / beatMs).floor();

  switch (track.style) {
    case _BeatStyle.classic:
      for (var beat = 0; beat < beats; beat++) {
        final start = ((beat * beatMs) / 1000 * sampleRate).round();
        final down = beat % 4 == 0;
        _addKick(samples, start, sampleRate,
            freq: down ? 85.0 : 130.0, amp: down ? 0.95 : 0.5);
        if (beat % 4 == 2) {
          _addSnap(samples, start, sampleRate, amp: 0.35);
        }
      }
      break;

    case _BeatStyle.neon:
      // Bright arpeggio bed + four-on-floor + hats.
      const arp = [523.25, 659.25, 784.0, 1046.5, 784.0, 659.25];
      for (var beat = 0; beat < beats; beat++) {
        final start = ((beat * beatMs) / 1000 * sampleRate).round();
        _addKick(samples, start, sampleRate, freq: 100, amp: 0.7);
        _addHat(samples, start + (sampleRate * 0.01).round(), sampleRate,
            amp: 0.35);
        _addHat(
          samples,
          start + (sampleRate * beatMs / 2000).round(),
          sampleRate,
          amp: 0.22,
        );
        // 16th arpeggio blips
        for (var s = 0; s < 4; s++) {
          final at = start + (sampleRate * beatMs * s / 4000).round();
          _addTone(
            samples,
            at,
            sampleRate,
            freq: arp[(beat * 4 + s) % arp.length],
            amp: 0.14,
            decay: 28,
            durSec: 0.07,
          );
        }
      }
      break;

    case _BeatStyle.velvet:
      // Warm bass + sparse snare + long pads.
      for (var beat = 0; beat < beats; beat++) {
        final start = ((beat * beatMs) / 1000 * sampleRate).round();
        if (beat % 2 == 0) {
          _addTone(
            samples,
            start,
            sampleRate,
            freq: beat % 8 == 0 ? 55.0 : 73.4,
            amp: 0.55,
            decay: 5,
            durSec: 0.35,
          );
        }
        if (beat % 4 == 2) {
          _addSnap(samples, start, sampleRate, amp: 0.22);
        }
        if (beat % 8 == 0) {
          _addTone(
            samples,
            start,
            sampleRate,
            freq: 220,
            amp: 0.1,
            decay: 2.2,
            durSec: 0.9,
          );
          _addTone(
            samples,
            start,
            sampleRate,
            freq: 277.2,
            amp: 0.08,
            decay: 2.2,
            durSec: 0.9,
          );
        }
      }
      break;

    case _BeatStyle.rush:
      // Aggressive double-time percussion + rising stabs.
      for (var beat = 0; beat < beats; beat++) {
        final start = ((beat * beatMs) / 1000 * sampleRate).round();
        final down = beat % 4 == 0;
        _addKick(samples, start, sampleRate,
            freq: down ? 110.0 : 180.0, amp: down ? 1.0 : 0.55);
        for (var s = 0; s < 2; s++) {
          _addHat(
            samples,
            start + (sampleRate * beatMs * s / 2000).round(),
            sampleRate,
            amp: 0.3,
          );
        }
        if (beat % 4 == 2) {
          _addSnap(samples, start, sampleRate, amp: 0.5);
        }
        if (beat % 8 == 7) {
          _addTone(
            samples,
            start,
            sampleRate,
            freq: 440 + (beat % 16) * 20.0,
            amp: 0.2,
            decay: 18,
            durSec: 0.12,
          );
        }
      }
      break;
  }

  // Soft normalize to avoid clipping differences between styles.
  var peak = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > peak) peak = a;
  }
  if (peak > 1) {
    final scale = 0.92 / peak;
    for (var i = 0; i < samples.length; i++) {
      samples[i] *= scale;
    }
  }
  return _encodeWav(samples, sampleRate);
}

List<Map<String, dynamic>> _makeNotes(_TrackSpec track) {
  final beatMs = (60000 / track.bpm).round();
  final rng = Random(track.id.hashCode);
  final notes = <Map<String, dynamic>>[];
  var t = beatMs * 2;
  var prevBubble = -1;
  final end = track.durationMs - beatMs;
  final denser =
      track.style == _BeatStyle.rush || track.style == _BeatStyle.neon;

  while (t < end) {
    final stepBeats = denser
        ? (rng.nextBool() ? 1 : 2)
        : (track.style == _BeatStyle.velvet
            ? (rng.nextBool() ? 2 : 3)
            : 2);
    var bubble = rng.nextInt(20);
    var guard = 0;
    while (bubble == prevBubble && guard < 8) {
      bubble = rng.nextInt(20);
      guard++;
    }
    prevBubble = bubble;
    final weight = denser
        ? (t % (beatMs * 4) == 0 ? 1 : (rng.nextBool() ? 2 : 3))
        : (t % (beatMs * 4) == 0 ? 1 : 2);
    notes.add({'tMs': t, 'bubbleId': bubble, 'weight': weight});
    t += beatMs * stepBeats;
  }
  return notes;
}

void _addKick(
  Float64List samples,
  int start,
  int sampleRate, {
  required double freq,
  required double amp,
}) {
  final clickLen = (sampleRate * 0.09).round();
  for (var i = 0; i < clickLen && start + i < samples.length; i++) {
    final t = i / sampleRate;
    final env = exp(-42 * t);
    samples[start + i] += sin(2 * pi * freq * t) * amp * env;
    samples[start + i] += sin(2 * pi * 800 * t) * 0.08 * env;
  }
}

void _addHat(
  Float64List samples,
  int start,
  int sampleRate, {
  required double amp,
}) {
  final len = (sampleRate * 0.04).round();
  final rng = Random(start & 0x7fffffff);
  for (var i = 0; i < len && start + i < samples.length; i++) {
    final t = i / sampleRate;
    final env = exp(-95 * t);
    samples[start + i] += (rng.nextDouble() * 2 - 1) * amp * env;
  }
}

void _addSnap(
  Float64List samples,
  int start,
  int sampleRate, {
  required double amp,
}) {
  final len = (sampleRate * 0.055).round();
  for (var i = 0; i < len && start + i < samples.length; i++) {
    final t = i / sampleRate;
    final env = exp(-65 * t);
    samples[start + i] += sin(2 * pi * 200 * t) * amp * env;
    samples[start + i] += sin(2 * pi * 900 * t) * amp * 0.4 * env;
  }
}

void _addTone(
  Float64List samples,
  int start,
  int sampleRate, {
  required double freq,
  required double amp,
  required double decay,
  required double durSec,
}) {
  final len = (sampleRate * durSec).round();
  for (var i = 0; i < len && start + i < samples.length; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    samples[start + i] += sin(2 * pi * freq * t) * amp * env;
  }
}

Uint8List _encodeWav(Float64List samples, int sampleRate) {
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
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, s, Endian.little);
  }
  return data.buffer.asUint8List();
}
