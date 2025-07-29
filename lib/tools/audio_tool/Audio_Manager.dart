import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'cashedAudioManager.dart';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _bgPlayer = AudioPlayer(); // For background music
  final AudioPlayer _sfxPlayer = AudioPlayer(); // For sound effects

  bool _isBgPlaying = false;
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  AudioManager() {
    _init();
  }

  void _init() {
    _bgPlayer.playerStateStream.listen((state) {
      _isBgPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> playBackground(String assetPath, {bool loop = true}) async {
    try {
      final source = await CachedAudioManager().getAudioSource(assetPath);
      await _bgPlayer.setAudioSource(source);
      await _bgPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _bgPlayer.play();
    } catch (e) {
      print('Error playing background: $e');
    }
  }

  Future<void> playSfx(String assetPath) async {
    try {
      final source = await CachedAudioManager().getAudioSource(assetPath);
      await _sfxPlayer.setAudioSource(source);
      await _sfxPlayer.play();
    } catch (e) {
      print('Error playing SFX: $e');
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _bgPlayer.setVolume(_isMuted ? 0 : 1);
    _sfxPlayer.setVolume(_isMuted ? 0 : 1);
    notifyListeners();
  }

  void pauseBackground() => _bgPlayer.pause();

  void resumeBackground() => _bgPlayer.play();

  void stopAll() {
    _bgPlayer.stop();
    _sfxPlayer.stop();
  }

  @override
  void dispose() {
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
