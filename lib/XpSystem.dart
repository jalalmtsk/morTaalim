import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExperienceManager extends ChangeNotifier {
  int _xp = 0;
  int _stars = 0;
  List<String> _unlockedAvatars = ['😀']; // default
  String _selectedAvatar = '😀';

  int get xp => _xp;
  int get stars => _stars;
  int get level => (_xp ~/ 100) + 1;
  double get levelProgress => (_xp % 100) / 100;

  List<String> get unlockedAvatars => _unlockedAvatars;
  String get selectedAvatar => _selectedAvatar;

  ExperienceManager() {
    _loadData();
  }

  void addXP(int amount) {
    _xp += amount;
    _saveData();
    notifyListeners();
  }

  void addStars(int amount) {
    _stars += amount;
    _saveData();
    notifyListeners();
  }

  void unlockAvatar(String emoji) {
    if (!_unlockedAvatars.contains(emoji)) {
      _unlockedAvatars.add(emoji);
      _saveData();
      notifyListeners();
    }
  }

  void selectAvatar(String emoji) {
    if (_unlockedAvatars.contains(emoji)) {
      _selectedAvatar = emoji;
      _saveData();
      notifyListeners();
    }
  }

  void resetData() {
    _xp = 0;
    _stars = 0;
    _unlockedAvatars = ['😀'];
    _selectedAvatar = '😀';
    _saveData();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('xp') ?? 0;
    _stars = prefs.getInt('stars') ?? 0;
    _selectedAvatar = prefs.getString('selectedAvatar') ?? '😀';
    _unlockedAvatars = prefs.getStringList('unlockedAvatars') ?? ['😀'];
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', _xp);
    await prefs.setInt('stars', _stars);
    await prefs.setString('selectedAvatar', _selectedAvatar);
    await prefs.setStringList('unlockedAvatars', _unlockedAvatars);
  }
}
