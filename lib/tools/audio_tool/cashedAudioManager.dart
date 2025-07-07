import 'package:just_audio/just_audio.dart';

class CachedAudioManager {
  static final CachedAudioManager _instance = CachedAudioManager._internal();
  factory CachedAudioManager() => _instance;
  CachedAudioManager._internal();

  final _cache = <String, AudioSource>{};

  Future<AudioSource> getAudioSource(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath]!;
    }
    final source = AudioSource.asset(assetPath);
    _cache[assetPath] = source;
    return source;
  }

  void clear() {
    _cache.clear();
  }
}
