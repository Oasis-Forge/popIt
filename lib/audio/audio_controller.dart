import 'package:just_audio/just_audio.dart';

class AudioController {
  AudioController()
      : _music = AudioPlayer(),
        _sfx = AudioPlayer();

  final AudioPlayer _music;
  final AudioPlayer _sfx;

  Stream<Duration> get positionStream => _music.positionStream;
  Stream<PlayerState> get playerStateStream => _music.playerStateStream;
  Duration? get duration => _music.duration;
  bool get playing => _music.playing;

  Future<void> load({
    required String musicAsset,
    required String popSfxAsset,
  }) async {
    await _music.setAsset(musicAsset);
    await _sfx.setAsset(popSfxAsset);
    await _sfx.setVolume(0.85);
  }

  Future<void> play() => _music.play();

  Future<void> stop() async {
    await _music.stop();
    await _music.seek(Duration.zero);
  }

  Future<void> seekZero() => _music.seek(Duration.zero);

  Future<void> playPop() async {
    try {
      await _sfx.seek(Duration.zero);
      await _sfx.play();
    } catch (_) {
      // SFX should never break gameplay.
    }
  }

  Future<void> dispose() async {
    await _music.dispose();
    await _sfx.dispose();
  }
}
