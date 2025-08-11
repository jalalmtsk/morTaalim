import 'package:just_audio/just_audio.dart';

import 'cashedAudioManager.dart';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioPlayerWidget extends StatefulWidget {
  final MusicPlayer musicPlayer;
  final String assetPath;

  const AudioPlayerWidget({
    super.key,
    required this.musicPlayer,
    required this.assetPath,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<PlayerState> _stateSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final source = await CachedAudioManager().getAudioSource(widget.assetPath);
      final player = widget.musicPlayer.player;

      await player.setAudioSource(source);
      player.setLoopMode(LoopMode.off);

      // Update UI when duration is available
      player.durationStream.listen((d) {
        if (d != null) {
          setState(() {
            _duration = d;
          });
        }
      });

      // Listen to position updates
      _positionSub = player.positionStream.listen((pos) {
        setState(() {
          _position = pos;
        });
      });

      // Listen to playback state
      _stateSub = player.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
        });
      });
    } catch (e) {
      print("Error initializing audio: $e");
    }
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _stateSub.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    final player = widget.musicPlayer.player;
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seekTo(double seconds) {
    widget.musicPlayer.player.seek(Duration(seconds: seconds.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '🎵 تشغيل الصوت',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _position.inSeconds.toDouble(),
          min: 0,
          max: _duration.inSeconds.toDouble() + 1,
          onChanged: _seekTo,
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.deepPurple.shade100,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        IconButton(
          iconSize: 48,
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
          color: Colors.deepPurple,
          onPressed: _togglePlayPause,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}




class MusicPlayer {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

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


