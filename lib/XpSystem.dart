import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExperienceManager extends ChangeNotifier {
  int _xp = 0;
  int _stars = 5;
  List<String> _unlockedAvatars = ['😀']; // default
  String _selectedAvatar = '😀';

  int get xp => _xp;
  int get stars => _stars;
  int get level => (_xp ~/ 100) + 1;
  double get levelProgress => (_xp % 100) / 100;

  List<String> get unlockedAvatars => _unlockedAvatars;
  String get selectedAvatar => _selectedAvatar;

  List<String> _unlockedCourses = [];
  List<String> get unlockedCourses => _unlockedCourses;

  // Animation helpers for UI feedback on adding stars and tokens
  int _recentlyAddedTokens = 0;
  int _recentlyAddedStars = 0;

  int get recentlyAddedTokens => _recentlyAddedTokens;
  int get recentlyAddedStars => _recentlyAddedStars;

  void addTokens(int amount) {
    Tolims += amount;
    _recentlyAddedTokens = amount;
    _saveData();
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _recentlyAddedTokens = 0;
      notifyListeners();
    });
  }

  void addStars(int amount) {
    _stars += amount;
    _recentlyAddedStars = amount;
    _saveData();
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _recentlyAddedStars = 0;
      notifyListeners();
    });
  }

  bool isCourseUnlocked(String title) {
    return _unlockedCourses.contains(title);
  }

  void unlockCourse(String title, int cost) {
    if (!_unlockedCourses.contains(title) && _stars >= cost) {
      _unlockedCourses.add(title);
      _stars -= cost;
      _saveData();
      notifyListeners();
    }
  }

  /////////// Trace Game Unlock Feature
  List<String> _unlockedLanguages = ['arabic', 'french'];
  List<String> get unlockedLanguages => _unlockedLanguages;

  bool isLanguageUnlocked(String code) {
    return _unlockedLanguages.contains(code);
  }

  void unlockLanguage(String code, int cost) {
    if (!_unlockedLanguages.contains(code) && _stars >= cost) {
      _unlockedLanguages.add(code);
      _stars -= cost;
      _saveData();
      notifyListeners();
    }
  }

  ExperienceManager() {
    _loadData();
  }

  void addXP(int amount, {BuildContext? context}) {
    final int oldLevel = level;
    _xp += amount;
    final int newLevel = level;

    if (newLevel > oldLevel) {
      _stars += (newLevel - oldLevel);
    }

    _saveData();
    notifyListeners();

    if (context != null && newLevel > oldLevel) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          _showOverlayLevelUpBanner(context, newLevel);
        }
      });
    }
  }

  /// Tokens System
  int Tolims = 20;
  int get saveTokens => Tolims;

  bool buySaveTokens() {
    if (Tolims >= 3) {
      Tolims -= 3;      // Spend 3 tokens
      _stars += 1;      // Gain 1 star
      _saveData();
      notifyListeners();
      return true;
    }
    return false;       // Not enough tokens
  }

  int get saveTokenCount => Tolims;

  void _showOverlayLevelUpBanner(BuildContext context, int newLevel) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade700.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upgrade, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Level $newLevel Unlocked! +1 ⭐',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
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
    _unlockedCourses = [];
    _unlockedLanguages = ['arabic', 'french'];
    _saveData();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('xp') ?? 0;
    _stars = prefs.getInt('stars') ?? 0;
    _selectedAvatar = prefs.getString('selectedAvatar') ?? '😀';
    _unlockedAvatars = prefs.getStringList('unlockedAvatars') ?? ['😀'];
    _unlockedCourses = prefs.getStringList('unlockedCourses') ?? [];
    notifyListeners();
    _unlockedLanguages = prefs.getStringList('unlockedLanguages') ?? ['arabic', 'french'];
    Tolims = prefs.getInt('saveTokens') ?? 0;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', _xp);
    await prefs.setInt('stars', _stars);
    await prefs.setString('selectedAvatar', _selectedAvatar);
    await prefs.setStringList('unlockedAvatars', _unlockedAvatars);
    await prefs.setStringList('unlockedCourses', _unlockedCourses);
    await prefs.setStringList('unlockedLanguages', _unlockedLanguages);
    await prefs.setInt('saveTokens', Tolims);
  }
}

// --------- AdManager for Rewarded Ads ------------

