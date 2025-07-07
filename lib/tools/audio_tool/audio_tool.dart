import 'package:just_audio/just_audio.dart';

import 'cashedAudioManager.dart';

class MusicPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String assetPath, {bool loop = false}) async {
    try {
      final source = await CachedAudioManager().getAudioSource(assetPath);
      await _player.setAudioSource(source);
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }


  Future<void> preload(String assetPath) async {
    try {
      await CachedAudioManager().getAudioSource(assetPath);
      print('Preloaded: $assetPath');
    } catch (e) {
      print('Error preloading audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      print('Music paused.');
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.play();
      print('Music resumed.');
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

class MusicPlayerOne {
  final AudioPlayer _player = AudioPlayer();
  final Map<String, AudioSource> _cache = {};

  Future<void> preload(String assetPath) async {
    try {
      final source = await CachedAudioManager().getAudioSource(assetPath);
      _cache[assetPath] = source;
      print('Preloaded $assetPath');
    } catch (e) {
      print('Error preloading $assetPath: $e');
    }
  }

  Future<void> play(String assetPath, {bool loop = false}) async {
    try {
      final source = _cache[assetPath];
      if (source == null) {
        print('Warning: asset not preloaded, loading now...');
        final loadedSource = await CachedAudioManager().getAudioSource(assetPath);
        _cache[assetPath] = loadedSource;
        await _player.setAudioSource(loadedSource);
      } else {
        await _player.setAudioSource(source);
      }

      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}


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


