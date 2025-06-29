import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String assetPath, {bool loop = false}) async {
    try {
      await _player.setAsset(assetPath);
      if (loop) {
        await _player.setLoopMode(LoopMode.one);
      }
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> stop() async {
    await _player.pause();
  }

  void dispose() {
    _player.dispose();
  }
}
