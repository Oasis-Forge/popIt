import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class _PopSlot {
  _PopSlot() : player = AudioPlayer();

  final AudioPlayer player;
  Future<void> chain = Future<void>.value();
}

/// Background music + short pop / lose SFX.
class AudioController {
  AudioController()
      : _music = AudioPlayer(),
        _lose = AudioPlayer(),
        _popPool = List.generate(4, (_) => _PopSlot());

  final AudioPlayer _music;
  final AudioPlayer _lose;
  final List<_PopSlot> _popPool;

  double _musicVolume = 0.55;
  double _sfxVolume = 0.9;
  bool _musicMuted = false;
  bool _sfxMuted = false;
  bool _popsReady = false;
  int _poolCursor = 0;

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
    await _warmupPopPool(popSfxAsset);
    await _applyVolumes();
  }

  Future<void> loadSfxOnly({
    required String popSfxAsset,
    required String loseSfxAsset,
  }) async {
    await _lose.setAsset(loseSfxAsset);
    await _warmupPopPool(popSfxAsset);
    await _applyVolumes();
  }

  Future<void> _warmupPopPool(String popSfxAsset) async {
    if (_popsReady) return;
    try {
      for (final slot in _popPool) {
        await slot.player.setAsset(popSfxAsset);
        await slot.player.setVolume(0);
      }
      _popsReady = true;
    } catch (e) {
      debugPrint('Pop pool warmup failed: $e');
      _popsReady = false;
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

  /// Short pop on a correct bubble tap. Non-blocking for rapid hits.
  void playPop() {
    if (_sfxMuted || _sfxVolume <= 0) return;
    final slot = _popPool[_poolCursor++ % _popPool.length];
    slot.chain = slot.chain.then((_) => _triggerPop(slot));
  }

  Future<void> _triggerPop(_PopSlot slot) async {
    try {
      if (!_popsReady) return;
      await slot.player.setVolume(_sfxVolume);
      await slot.player.pause();
      await slot.player.seek(Duration.zero);
      unawaited(slot.player.play());
    } catch (e) {
      debugPrint('Pop trigger failed: $e');
    }
  }

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
    for (final slot in _popPool) {
      await slot.player.dispose();
    }
  }
}
