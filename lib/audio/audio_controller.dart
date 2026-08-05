import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class _HitSlot {
  _HitSlot() : player = AudioPlayer();

  final AudioPlayer player;
  int? loadedNote;
  Future<void> chain = Future<void>.value();
}

/// Background music + melodic hit bank so correct taps form a phrase.
class AudioController {
  AudioController()
      : _music = AudioPlayer(),
        _lose = AudioPlayer(),
        _hitPool = List.generate(8, (_) => _HitSlot());

  final AudioPlayer _music;
  final AudioPlayer _lose;
  final List<_HitSlot> _hitPool;

  double _musicVolume = 0.55;
  double _sfxVolume = 0.9;
  bool _musicMuted = false;
  bool _sfxMuted = false;
  bool _hitsReady = false;
  int _poolCursor = 0;

  /// Pleasant looping phrase over an 8-note pentatonic bank.
  static const _phrase = [0, 2, 4, 3, 5, 4, 2, 3, 4, 6, 5, 4, 3, 2, 1, 0];

  Stream<Duration> get positionStream => _music.positionStream;
  Stream<PlayerState> get playerStateStream => _music.playerStateStream;
  Duration? get duration => _music.duration;
  bool get playing => _music.playing;

  Future<void> load({
    required String musicAsset,
    required String popSfxAsset,
    String? loseSfxAsset,
  }) async {
    await _music.setAsset(musicAsset);
    if (loseSfxAsset != null) {
      await _lose.setAsset(loseSfxAsset);
    }
    await _warmupHitPool();
    await _applyVolumes();
  }

  Future<void> loadSfxOnly({
    required String popSfxAsset,
    required String loseSfxAsset,
  }) async {
    await _lose.setAsset(loseSfxAsset);
    await _warmupHitPool();
    await _applyVolumes();
  }

  /// Preload every note into the pool so first taps aren't racing setAsset.
  Future<void> _warmupHitPool() async {
    if (_hitsReady) return;
    try {
      for (var i = 0; i < _hitPool.length; i++) {
        final note = i % 8;
        await _hitPool[i].player.setAsset('assets/audio/hits/hit_$note.wav');
        _hitPool[i].loadedNote = note;
        await _hitPool[i].player.setVolume(0);
      }
      _hitsReady = true;
    } catch (e) {
      debugPrint('Hit pool warmup failed: $e');
      _hitsReady = false;
    }
  }

  Future<void> play() => _music.play();
  Future<void> pause() => _music.pause();
  Future<void> resume() => _music.play();

  Future<void> stop() async {
    await _music.stop();
    await _music.seek(Duration.zero);
  }

  Future<void> seekZero() => _music.seek(Duration.zero);

  Future<void> applyMix({
    required double musicVolume,
    required double sfxVolume,
    required bool musicMuted,
    required bool sfxMuted,
  }) async {
    _musicVolume = musicVolume.clamp(0, 1);
    _sfxVolume = sfxVolume.clamp(0, 1);
    _musicMuted = musicMuted;
    _sfxMuted = sfxMuted;
    await _applyVolumes();
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0, 1);
    await _applyVolumes();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0, 1);
    await _applyVolumes();
  }

  Future<void> _applyVolumes() async {
    final musicGain = (_musicMuted ? 0.0 : _musicVolume) * 0.7;
    await _music.setVolume(musicGain);
    await _lose.setVolume(_sfxMuted ? 0 : _sfxVolume);
  }

  Future<void> setSpeed(double speed) => _music.setSpeed(speed);

  Future<void> setLoopOne(bool enabled) async {
    await _music.setLoopMode(enabled ? LoopMode.one : LoopMode.off);
  }

  /// Melodic reward for a correct hit — advances a phrase with combo.
  /// Non-blocking so rapid taps don't drop notes.
  void playHitTone({
    required int combo,
    required bool perfect,
  }) {
    if (_sfxMuted || _sfxVolume <= 0) return;
    final step = combo <= 0 ? 0 : (combo - 1) % _phrase.length;
    var note = _phrase[step];
    if (!perfect) {
      note = (note - 1).clamp(0, 7);
    }
    if (combo > 0 && combo % 10 == 0) {
      note = (_phrase[step] + 3).clamp(0, 7);
    }
    final gain = _sfxVolume * (perfect ? 1.0 : 0.72);
    final slot = _hitPool[_poolCursor++ % _hitPool.length];
    // Serialize per-slot only; other slots stay free for polyphony.
    slot.chain = slot.chain.then((_) => _triggerHit(slot, note, gain));
  }

  Future<void> _triggerHit(_HitSlot slot, int note, double gain) async {
    try {
      if (!_hitsReady) {
        await _warmupHitPool();
        if (!_hitsReady) return;
      }
      if (slot.loadedNote != note) {
        await slot.player.setAsset('assets/audio/hits/hit_$note.wav');
        slot.loadedNote = note;
      }
      await slot.player.setVolume(gain);
      // Reliable retrigger on web + mobile.
      await slot.player.pause();
      await slot.player.seek(Duration.zero);
      unawaited(slot.player.play());
    } catch (e) {
      debugPrint('Hit trigger failed (note $note): $e');
      slot.loadedNote = null;
    }
  }

  @Deprecated('Use playHitTone for melodic feedback')
  Future<void> playPop() async => playHitTone(combo: 1, perfect: true);

  Future<void> playLose() async {
    if (_sfxMuted || _sfxVolume <= 0) return;
    try {
      await _lose.pause();
      await _lose.seek(Duration.zero);
      unawaited(_lose.play());
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _music.dispose();
    await _lose.dispose();
    for (final slot in _hitPool) {
      await slot.player.dispose();
    }
  }
}
