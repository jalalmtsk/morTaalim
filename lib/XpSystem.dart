import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ManagerTools/AnimatedSpendingStarBanner.dart';
import 'ManagerTools/AnimatedSpendingTolimBanner.dart';
import 'ManagerTools/AnimatedStarBanner.dart';
import 'ManagerTools/AnimatedTolimBanner.dart';
import 'ManagerTools/AnimatedXpBanner.dart';
import 'package:mortaalim/ManagerTools/LevelUpOverlayHelper.dart';

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

//MUSIC SOUND--------------------------------////



  ///-------------------------------------------------------------

  //Banner
  List<String> _unlockedBanners = [''
      'assets/images/Banners/CuteBr/Banner1.png',
      'assets/images/Banners/CuteBr/Banner2.png',
  ];
  String _selectedBannerImage = 'assets/images/Banners/CuteBr/Banner1.png';

  List<String> get unlockedBanners => _unlockedBanners;
  String get selectedBannerImage => _selectedBannerImage;

  void unlockBanner(String path) {
    if (!_unlockedBanners.contains(path)) {
      _unlockedBanners.add(path);
      _saveData();
      notifyListeners();
    }
  }

  void selectBannerImage(String path) {
    if (_unlockedBanners.contains(path)) {
      _selectedBannerImage = path;
      _saveData();
      notifyListeners();
    }
  }
  //-----------------------------------------------------------------------


  // ✅ Avatar Frame Logic
  String _selectedAvatarFrame = ''; // optional: can be asset path or mood string
  List<String> _unlockedAvatarFrames = [];

  String get selectedAvatarFrame => _selectedAvatarFrame;
  List<String> get unlockedAvatarFrames => _unlockedAvatarFrames;

  void unlockAvatarFrame(String path) {
    if (!_unlockedAvatarFrames.contains(path)) {
      _unlockedAvatarFrames.add(path);
      _saveData();
      notifyListeners();
    }
  }

  void selectAvatarFrame(String path) {
    if (_unlockedAvatarFrames.contains(path)) {
      _selectedAvatarFrame = path;
      _saveData();
      notifyListeners();
    }
  }
  /// --------------------------------------------------------------



  void addTokenBanner(BuildContext context, int amount) {
    Tolims += amount;
    _recentlyAddedTokens = amount;
    _showTokenFlash = true;
    notifyListeners();

    // Show token banner overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final overlay = Overlay.of(context);
      if (overlay == null) return;

      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (ctx) => AnimatedTokenBanner(
          tokenAmount: amount,
          onDismiss: () => entry.remove(),
        ),
      );

      overlay.insert(entry);
    });

    // Flash animation cleanup
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

  void SpendTokenBanner(BuildContext context, int amount) {

    Tolims += amount;
    _recentlyAddedTokens = amount;
    _showTokenFlash = true;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context);
      if (overlay == null || !context.mounted) return;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => AnimatedTokenSpentBanner(
          tokenAmount: amount,
          onDismiss: () => entry.remove(),
        ),
      );

      overlay.insert(entry);
    });
  }




  void addStarBanner(BuildContext context, int amount) {
    _stars += amount;
    _recentlyAddedStars = amount;
    _showStarFlash = true;
    notifyListeners();

    // Animate flash
    Future.delayed(const Duration(milliseconds: 600), () {
      _showStarFlash = false;
      notifyListeners();
    });

    // Reset recently added
    Future.delayed(const Duration(seconds: 1), () {
      _recentlyAddedStars = 0;
      notifyListeners();
    });

    _saveData();

    // Show animated star banner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final overlay = Overlay.of(context);
      if (overlay == null) return;

      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (ctx) => AnimatedStarBanner(
          starAmount: amount,
          onDismiss: () => entry.remove(),
        ),
      );

      overlay.insert(entry);
    });
  }

  void SpendStarBanner(BuildContext context, int amount) {
    _stars += amount;
    _recentlyAddedStars = amount;
    _showStarFlash = true;
    notifyListeners();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context);
      if (overlay == null || !context.mounted) return;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => AnimatedStarSpentBanner(
          starAmount: amount,
          onDismiss: () => entry.remove(),
        ),
      );

      overlay.insert(entry);
    });
  }




  void addXP(int amount, {BuildContext? context}) {
    final int oldLevel = level;
    _xp += amount;
    final int newLevel = level;

    if (newLevel > oldLevel) {
      addStarBanner(context!, newLevel - oldLevel);
    }

    _saveData();
    notifyListeners();

    if (context != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          _showOverlayXPAddedBanner(context, amount);
        }
      });

      if (newLevel > oldLevel) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            Provider.of<AudioManager>(context, listen: false)
                .playSfx("assets/audios/sound_effects/correct_anwser.mp3");
            Provider.of<AudioManager>(context, listen: false)
                .playSfx("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
            LevelUpOverlayHelper.showOverlayLevelUpBanner(context, newLevel);
          }
        });
      }
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
    _selectedBannerImage = prefs.getString('selectedBannerImage') ?? 'assets/images/Banners/CuteBr/Banner1.png';
    _unlockedBanners = prefs.getStringList('unlockedBanners') ?? ['assets/images/Banners/CuteBr/Banner1.png'];
    _selectedAvatarFrame = prefs.getString('selectedAvatarFrame') ?? '';
    _unlockedAvatarFrames = prefs.getStringList('unlockedAvatarFrames') ?? [];
    _adsEnabled = prefs.getBool('adsEnabled') ?? true;
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
    await prefs.setString('selectedBannerImage', _selectedBannerImage);
    await prefs.setStringList('unlockedBanners', _unlockedBanners);
    await prefs.setString('selectedAvatarFrame', _selectedAvatarFrame);
    await prefs.setStringList('unlockedAvatarFrames', _unlockedAvatarFrames);
    await prefs.setBool('adsEnabled', _adsEnabled);
  }

  final MusicPlayer LvlUp = MusicPlayer();
  final MusicPlayer LvlUp2 = MusicPlayer();

  //ADDING XP
  void _showOverlayXPAddedBanner(BuildContext context, int xpAmount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final overlay = Overlay.of(context);
      if (overlay == null) return;

      Provider.of<AudioManager>(context, listen: false)
          .playSfx("assets/audios/sound_effects/correct_anwser.mp3");

      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (ctx) {
          return AnimatedXPBanner(
            xpAmount: xpAmount,
            onDismiss: () => entry.remove(),
          );
        },
      );

      overlay.insert(entry);
    });
  }

////----------------------------------------------------------------------


  //ADS MANAGER
  bool _adsEnabled = true; // default to true

  bool get adsEnabled => _adsEnabled;

  void setAdsEnabled(bool value) {
    _adsEnabled = value;
    _saveAdsPreference(); // Save to SharedPreferences
    notifyListeners();
  }

  Future<void> _saveAdsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adsEnabled', _adsEnabled);
  }
  /////////////////////////////////////////////////////////

  //MUSIC MANAGER //


  ////





  void init(BuildContext context) {

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _delayedRestartTimer?.cancel();
    super.dispose();
  }
}
