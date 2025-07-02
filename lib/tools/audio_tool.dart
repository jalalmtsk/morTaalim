import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String assetPath, {bool loop = false}) async {
    try {
      print('Loading asset: $assetPath');
      await _player.setAsset(assetPath);
      if (loop) {
        await _player.setLoopMode(LoopMode.one);
      } else {
        await _player.setLoopMode(LoopMode.off);
      }
      await _player.play();
      print('Playing audio.');
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
