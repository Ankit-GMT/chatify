import 'package:just_audio/just_audio.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playOutgoing() async {
    if (_isPlaying) return;

    _isPlaying = true;
    await _player.setLoopMode(LoopMode.one);
    await _player.setAsset('assets/sounds/ringing.mp3');
    await _player.play();
  }

  // Future<void> playIncoming() async {
  //   if (_isPlaying) return;
  //
  //   _isPlaying = true;
  //   await _player.setLoopMode(LoopMode.one);
  //   await _player.setAsset('assets/sounds/incoming_ring.mp3');
  //   await _player.play();
  // }

  Future<void> stop() async {
    if (!_isPlaying) return;

    _isPlaying = false;
    await _player.stop();
  }
}
