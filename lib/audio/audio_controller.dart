import 'package:just_audio/just_audio.dart';

class AudioController {
  AudioController()
      : _music = AudioPlayer(),
        _pop = AudioPlayer(),
        _lose = AudioPlayer();

  final AudioPlayer _music;
  final AudioPlayer _pop;
  final AudioPlayer _lose;

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
    await _pop.setAsset(popSfxAsset);
    await _pop.setVolume(0.85);
    if (loseSfxAsset != null) {
      await _lose.setAsset(loseSfxAsset);
      await _lose.setVolume(0.9);
    }
  }

  Future<void> loadSfxOnly({
    required String popSfxAsset,
    required String loseSfxAsset,
  }) async {
    await _pop.setAsset(popSfxAsset);
    await _pop.setVolume(0.85);
    await _lose.setAsset(loseSfxAsset);
    await _lose.setVolume(0.9);
  }

  Future<void> play() => _music.play();

  Future<void> stop() async {
    await _music.stop();
    await _music.seek(Duration.zero);
  }

  Future<void> seekZero() => _music.seek(Duration.zero);

  Future<void> playPop() async {
    try {
      await _pop.seek(Duration.zero);
      await _pop.play();
    } catch (_) {
      // SFX should never break gameplay.
    }
  }

  Future<void> playLose() async {
    try {
      await _lose.seek(Duration.zero);
      await _lose.play();
    } catch (_) {
      // SFX should never break gameplay.
    }
  }

  Future<void> dispose() async {
    await _music.dispose();
    await _pop.dispose();
    await _lose.dispose();
  }
}
