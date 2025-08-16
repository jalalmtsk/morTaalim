import 'package:just_audio/just_audio.dart';
import 'dart:async';


class MusicPlayers {
  // We no longer keep a single player instance.
  // Instead, each play call creates and manages its own player.

  // Optional: Keep track of active players to dispose later if needed.
  final List<AudioPlayer> _activePlayers = [];

  Future<void> play(String assetPath, {bool loop = false}) async {
    final player = AudioPlayer();
    _activePlayers.add(player);


    try {
      print('Loading asset: $assetPath');
      await player.setAsset(assetPath);
      await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await player.play();
      print('Playing audio.');

      // When playback finishes, dispose player and remove it from active list
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
          _activePlayers.remove(player);
          print('Disposed a player after completion.');
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
      await player.dispose();
      _activePlayers.remove(player);
    }
  }

  Future<void> stopAll() async {
    // Stops all active players and disposes them
    for (var player in List<AudioPlayer>.from(_activePlayers)) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
      _activePlayers.remove(player);
    }
  }

  void dispose() {
    for (var player in _activePlayers) {
      player.dispose();
    }
    _activePlayers.clear();
  }
}


