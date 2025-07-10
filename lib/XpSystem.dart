import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExperienceManager extends ChangeNotifier with WidgetsBindingObserver {
  int _xp = 0;
  int _stars = 5;
  int Tolims = 20;

  List<String> _unlockedAvatars = ['😀'];
  String _selectedAvatar = '😀';
  List<String> _unlockedCourses = [];
  List<String> _unlockedLanguages = ['arabic', 'french'];

  int _recentlyAddedTokens = 0;
  int _recentlyAddedStars = 0;
  bool _showTokenFlash = false;
  bool _showStarFlash = false;

  Timer? _rewardTimer;
  Timer? _delayedRestartTimer;

  static const rewardCooldown = Duration(minutes: 30);
  static const inactivityRestartDelay = Duration(seconds: 5);

  ExperienceManager() {
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startRewardTimer();
  }

  // 🔁 Exponential XP System --------------------------

  /// XP needed to reach a given level (e.g., level 3 → 450 XP)
  int getXPForLevel(int level) {
    return level * level * 50; // Feel free to change multiplier (e.g., 60)
  }

  /// Returns the current level
  int get level {
    int lvl = 1;
    while (_xp >= getXPForLevel(lvl)) {
      lvl++;
    }
    return lvl;
  }

  /// Current progress between two levels [0.0 - 1.0]
  double get levelProgress {
    int currentLevel = level;
    int prevXP = getXPForLevel(currentLevel - 1);
    int nextXP = getXPForLevel(currentLevel);
    return ((_xp - prevXP) / (nextXP - prevXP)).clamp(0.0, 1.0);
  }

  /// For displaying progress like "300 / 450 XP"
  int get currentLevelXP => _xp - getXPForLevel(level - 1);
  int get requiredXPForNextLevel => getXPForLevel(level) - getXPForLevel(level - 1);

  // --------------------------------------------------

  int get xp => _xp;
  int get stars => _stars;
  List<String> get unlockedAvatars => _unlockedAvatars;
  String get selectedAvatar => _selectedAvatar;
  List<String> get unlockedCourses => _unlockedCourses;
  List<String> get unlockedLanguages => _unlockedLanguages;
  int get recentlyAddedTokens => _recentlyAddedTokens;
  int get recentlyAddedStars => _recentlyAddedStars;
  bool get showTokenFlash => _showTokenFlash;
  bool get showStarFlash => _showStarFlash;
  int get saveTokenCount => Tolims;

  void _startRewardTimer() {
    _rewardTimer?.cancel();
    _rewardTimer = Timer.periodic(rewardCooldown, (_) {
      _giveReward();
    });
  }

  void _stopRewardTimer() {
    _rewardTimer?.cancel();
    _rewardTimer = null;
  }

  void _giveReward() {
    addTokens(2);
    addStars(1);
  }

  void addTokens(int amount) {
    Tolims += amount;
    _recentlyAddedTokens = amount;
    _showTokenFlash = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 300), () {
      _showTokenFlash = false;
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 2), () {
      _recentlyAddedTokens = 0;
      notifyListeners();
    });

    _saveData();
  }

  void addStars(int amount) {
    _stars += amount;
    _recentlyAddedStars = amount;
    _showStarFlash = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 600), () {
      _showStarFlash = false;
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 1), () {
      _recentlyAddedStars = 0;
      notifyListeners();
    });

    _saveData();
  }

  void addXP(int amount, {BuildContext? context}) {
    final int oldLevel = level;
    _xp += amount;
    final int newLevel = level;

    if (newLevel > oldLevel) {
      addStars(newLevel - oldLevel);
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

  bool isCourseUnlocked(String title) => _unlockedCourses.contains(title);

  void unlockCourse(String title, int cost) {
    if (!_unlockedCourses.contains(title) && _stars >= cost) {
      _unlockedCourses.add(title);
      _stars -= cost;
      _saveData();
      notifyListeners();
    }
  }

  bool isLanguageUnlocked(String code) => _unlockedLanguages.contains(code);

  void unlockLanguage(String code, int cost) {
    if (!_unlockedLanguages.contains(code) && _stars >= cost) {
      _unlockedLanguages.add(code);
      _stars -= cost;
      _saveData();
      notifyListeners();
    }
  }

  bool buySaveTokens() {
    if (Tolims >= 3) {
      Tolims -= 3;
      _stars += 1;
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
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
    Tolims = 20;
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
    _stars = prefs.getInt('stars') ?? 5;
    Tolims = prefs.getInt('saveTokens') ?? 20;
    _selectedAvatar = prefs.getString('selectedAvatar') ?? '😀';
    _unlockedAvatars = prefs.getStringList('unlockedAvatars') ?? ['😀'];
    _unlockedCourses = prefs.getStringList('unlockedCourses') ?? [];
    _unlockedLanguages = prefs.getStringList('unlockedLanguages') ?? ['arabic', 'french'];
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', _xp);
    await prefs.setInt('stars', _stars);
    await prefs.setInt('saveTokens', Tolims);
    await prefs.setString('selectedAvatar', _selectedAvatar);
    await prefs.setStringList('unlockedAvatars', _unlockedAvatars);
    await prefs.setStringList('unlockedCourses', _unlockedCourses);
    await prefs.setStringList('unlockedLanguages', _unlockedLanguages);
  }

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
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopRewardTimer();
    } else if (state == AppLifecycleState.resumed) {
      _stopRewardTimer();
      _startRewardTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRewardTimer();
    _delayedRestartTimer?.cancel();
    super.dispose();
  }
}
