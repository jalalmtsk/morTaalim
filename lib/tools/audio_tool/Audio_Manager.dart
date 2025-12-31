import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager extends ChangeNotifier with WidgetsBindingObserver{

  AudioManager() {
    WidgetsBinding.instance.addObserver(this); // ✅ Observe lifecycle
    _loadSettings();
  }
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get audioPlayer => _player;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _bgPlayer.pause();
      if (kDebugMode) print('[AudioManager] App paused → Music paused');
    } else if (state == AppLifecycleState.resumed && !_isBgMuted) {
      _bgPlayer.play();
      if (kDebugMode) print('[AudioManager] App resumed → Music resumed');
    }
  }

  // Map sound event keys to asset paths
  static const Map<String, String> eventSoundMap = {

    // ------------ ButtonSounds -------------

    'clickButton': 'assets/audios/UI_Audio/ButtonSounds/ClickButton_SB.mp3',
    'clickButton2': 'assets/audios/UI_Audio/ButtonSounds/ClickButton2_SB.mp3',
    'cancelButton': 'assets/audios/UI_Audio/ButtonSounds/CancelButton_SB.mp3',
    'PopButton': 'assets/audios/UI_Audio/ButtonSounds/PopButton_SB.mp3',
    'PopClick' : 'assets/audios/UI_Audio/ButtonSounds/PopClick_SB.mp3',
    'toggleButton': 'assets/audios/UI_Audio/ButtonSounds/ToggleButton_SB.mp3',

    // ------------ SFX Sounds -------------

    'xpWinSound': 'assets/audios/UI_Audio/SFX_Audio/XPWin.mp3',
    'starSound': 'assets/audios/UI_Audio/SFX_Audio/StarSound.mp3',
    'tolimSound': 'assets/audios/UI_Audio/SFX_Audio/TolimSound.mp3',
    'invalid': 'assets/audios/UI_Audio/SFX_Audio/Invalid_SFX.mp3',

    // ------------ Alert Sounds -------------

  };


  // Players
  final AudioPlayer _bgPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPlayers = List.generate(8, (_) => AudioPlayer());
  final AudioPlayer _buttonPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();

  // States
  bool _isBgMuted = false;
  bool _isSfxMuted = false;
  bool _isButtonMuted = false;
  bool _isAlertMuted = false;
  bool _hapticsEnabled = true;

  // Volumes
  double _bgVolume = 0.1;
  double _sfxVolume = 0.5;
  double _buttonVolume = 0.4;
  double _alertVolume = 0.6;

  // SharedPreferences keys
  static const String _prefBgVolumeKey = 'bgVolume';
  static const String _prefSfxVolumeKey = 'sfxVolume';
  static const String _prefButtonVolumeKey = 'buttonVolume';
  static const String _prefAlertVolumeKey = 'alertVolume';

  static const String _prefIsBgMutedKey = 'isBgMuted';
  static const String _prefIsSfxMutedKey = 'isSfxMuted';
  static const String _prefIsButtonMutedKey = 'isButtonMuted';
  static const String _prefIsAlertMutedKey = 'isAlertMuted';

  static const String _prefHapticsKey = 'hapticsEnabled';

  SharedPreferences? _prefs;


  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    _bgVolume = _prefs?.getDouble(_prefBgVolumeKey) ?? _bgVolume;
    _sfxVolume = _prefs?.getDouble(_prefSfxVolumeKey) ?? _sfxVolume;
    _buttonVolume = _prefs?.getDouble(_prefButtonVolumeKey) ?? _buttonVolume;
    _alertVolume = _prefs?.getDouble(_prefAlertVolumeKey) ?? _alertVolume;

    _isBgMuted = _prefs?.getBool(_prefIsBgMutedKey) ?? _isBgMuted;
    _isSfxMuted = _prefs?.getBool(_prefIsSfxMutedKey) ?? _isSfxMuted;
    _isButtonMuted = _prefs?.getBool(_prefIsButtonMutedKey) ?? _isButtonMuted;
    _isAlertMuted = _prefs?.getBool(_prefIsAlertMutedKey) ?? _isAlertMuted;

    _hapticsEnabled = _prefs?.getBool(_prefHapticsKey) ?? _hapticsEnabled;

    await _bgPlayer.setVolume(_isBgMuted ? 0 : _bgVolume);
    notifyListeners();

    if (kDebugMode) print('[AudioManager] Settings loaded');
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    if (_prefs == null) return;
    if (value is bool) await _prefs!.setBool(key, value);
    else if (value is double) await _prefs!.setDouble(key, value);
  }

  // ------------ BACKGROUND MUSIC -------------

  String? _currentBgMusic;

  String? get currentBgMusic => _currentBgMusic;

  Future<void> playBackgroundMusic(String assetPath, {bool loop = true}) async {
    if (_currentBgMusic == assetPath && _bgPlayer.playing) {
      // Same music is already playing, no need to restart
      return;
    }

    _currentBgMusic = assetPath;

    try {
      await _bgPlayer.stop(); // ✅ Stop any current loading/playing
      await _bgPlayer.setAsset(assetPath);
      await _bgPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _bgPlayer.setVolume(_isBgMuted ? 0 : _bgVolume);
      await _bgPlayer.play();
    } catch (e) {
      if (kDebugMode) print('Error playing background music: $e');
    }
  }


  Future<void> fadeVolume(AudioPlayer player, double targetVolume) async {
    final currentVolume = player.volume;
    final steps = 10;
    final step = (targetVolume - currentVolume) / steps;
    for (int i = 0; i < steps; i++) {
      await player.setVolume(player.volume + step);
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<void> toggleBgMute() async {
    _isBgMuted = !_isBgMuted;
    await _saveSetting(_prefIsBgMutedKey, _isBgMuted);
    await fadeVolume(_bgPlayer, _isBgMuted ? 0 : _bgVolume);
    if (kDebugMode) print('[AudioManager] Background mute toggled: $_isBgMuted');
    notifyListeners();
  }

  Future<void> setBgVolume(double volume) async {
    _bgVolume = volume.clamp(0.0, 1.0);
    await _saveSetting(_prefBgVolumeKey, _bgVolume);
    if (!_isBgMuted) await fadeVolume(_bgPlayer, _bgVolume);
    if (kDebugMode) print('[AudioManager] Background volume set to $_bgVolume');
    notifyListeners();
  }

  Future<void> stopMusic() async {
    try {
      await _bgPlayer.stop();
      if (kDebugMode) print('[AudioManager] Background music stopped');
    } catch (e) {
      if (kDebugMode) print('[AudioManager] Error stopping music: $e');
    }
    notifyListeners();
  }

  // ------------ EVENT SOUND -------------

  Future<void> playEventSound(String key) async {
    final path = eventSoundMap[key];
    if (path == null) {
      if (kDebugMode) print('[AudioManager] Sound key not found: $key');
      return;
    }

    try {
      if (key == 'clickButton' ||
          key == 'cancelButton' ||
          key == 'toggleButton' ||
          key == 'clickButton2' ||
          key == 'PopButton' ||
          key == 'PopClick') {
        await playButtonSound(path);
      } else {
        await playSfx(path);
      }
    } catch (e) {
      if (kDebugMode) print('[AudioManager] Failed to play sound "$key": $e');
    }
  }



  // ------------ SFX -------------

  Future<void> playSfx(String assetPath) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(assetPath);
      await player.setVolume(_isSfxMuted ? 0 : _sfxVolume);
      await player.play();
      if (kDebugMode) print('[AudioManager] Playing SFX: $assetPath');
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (kDebugMode) print('[AudioManager] SFX completed: $assetPath');
          player.dispose();
        }
      });
    } catch (e) {
      if (kDebugMode) print('[AudioManager] Error playing SFX: $e');
      await player.dispose();
    }
  }

  Future<void> toggleSfxMute() async {
    _isSfxMuted = !_isSfxMuted;
    await _saveSetting(_prefIsSfxMutedKey, _isSfxMuted);
    if (kDebugMode) print('[AudioManager] SFX mute toggled: $_isSfxMuted');
    notifyListeners();
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _saveSetting(_prefSfxVolumeKey, _sfxVolume);
    if (kDebugMode) print('[AudioManager] SFX volume set to $_sfxVolume');
    notifyListeners();
  }

  // ------------ BUTTON SOUNDS -------------

  Future<void> playButtonSound(String assetPath) async {
    try {
      await _buttonPlayer.setAsset(assetPath);
      await _buttonPlayer.setVolume(_isButtonMuted ? 0 : _buttonVolume);
      await _buttonPlayer.play();
      if (kDebugMode) print('[AudioManager] Playing button sound: $assetPath');
    } catch (e) {
      if (kDebugMode) print('[AudioManager] Error playing button sound: $e');
    }
  }


  Future<void> toggleButtonMute() async {
    _isButtonMuted = !_isButtonMuted;
    await _saveSetting(_prefIsButtonMutedKey, _isButtonMuted);
    if (kDebugMode) print('[AudioManager] Button mute toggled: $_isButtonMuted');
    notifyListeners();
  }

  Future<void> setButtonVolume(double volume) async {
    _buttonVolume = volume.clamp(0.0, 1.0);
    await _saveSetting(_prefButtonVolumeKey, _buttonVolume);
    if (kDebugMode) print('[AudioManager] Button volume set to $_buttonVolume');
    notifyListeners();
  }

  // ------------ ALERTS/NOTIFICATIONS -------------

  Future<void> playAlert(String assetPath) async {
    try {
      await _alertPlayer.setAsset(assetPath);
      await _alertPlayer.setVolume(_isAlertMuted ? 0 : _alertVolume);
      await _alertPlayer.play();
      if (kDebugMode) print('[AudioManager] Playing alert sound: $assetPath');
    } catch (e) {
      if (kDebugMode) print('[AudioManager] Error playing alert sound: $e');
    }
  }

  Future<void> toggleAlertMute() async {
    _isAlertMuted = !_isAlertMuted;
    await _saveSetting(_prefIsAlertMutedKey, _isAlertMuted);
    if (kDebugMode) print('[AudioManager] Alert mute toggled: $_isAlertMuted');
    notifyListeners();
  }

  Future<void> setAlertVolume(double volume) async {
    _alertVolume = volume.clamp(0.0, 1.0);
    await _saveSetting(_prefAlertVolumeKey, _alertVolume);
    if (kDebugMode) print('[AudioManager] Alert volume set to $_alertVolume');
    notifyListeners();
  }

  // ------------ HAPTICS -------------

  void toggleHaptics() {
    _hapticsEnabled = !_hapticsEnabled;
    _saveSetting(_prefHapticsKey, _hapticsEnabled);
    if (kDebugMode) print('[AudioManager] Haptics toggled: $_hapticsEnabled');
    notifyListeners();
  }

  // ------------ RESET TO DEFAULT -------------

  Future<void> resetAudioSettings() async {
    _bgVolume = 0.1;
    _sfxVolume = 0.5;
    _buttonVolume = 0.4;
    _alertVolume = 0.6;
    _isBgMuted = false;
    _isSfxMuted = false;
    _isButtonMuted = false;
    _isAlertMuted = false;
    _hapticsEnabled = true;

    await _saveSetting(_prefBgVolumeKey, _bgVolume);
    await _saveSetting(_prefSfxVolumeKey, _sfxVolume);
    await _saveSetting(_prefButtonVolumeKey, _buttonVolume);
    await _saveSetting(_prefAlertVolumeKey, _alertVolume);

    await _saveSetting(_prefIsBgMutedKey, _isBgMuted);
    await _saveSetting(_prefIsSfxMutedKey, _isSfxMuted);
    await _saveSetting(_prefIsButtonMutedKey, _isButtonMuted);
    await _saveSetting(_prefIsAlertMutedKey, _isAlertMuted);

    await _saveSetting(_prefHapticsKey, _hapticsEnabled);

    await _bgPlayer.setVolume(_bgVolume);

    if (kDebugMode) print('[AudioManager] Audio settings reset to default');
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    _bgPlayer.dispose();
    for (final p in _sfxPlayers) {
      p.dispose();
    }
    _buttonPlayer.dispose();
    _alertPlayer.dispose();
    super.dispose();
  }

  // Getters for external access
  bool get isBgMuted => _isBgMuted;
  bool get isSfxMuted => _isSfxMuted;
  bool get isButtonMuted => _isButtonMuted;
  bool get isAlertMuted => _isAlertMuted;
  bool get hapticsEnabled => _hapticsEnabled;

  double get bgVolume => _bgVolume;
  double get sfxVolume => _sfxVolume;
  double get buttonVolume => _buttonVolume;
  double get alertVolume => _alertVolume;
}
