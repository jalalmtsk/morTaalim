import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/tools/StarCountPulse.dart';
import 'package:mortaalim/tools/StarDeductionOverlay.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'ManagerTools/AnimatedSpendingStarBanner.dart';
import 'ManagerTools/AnimatedSpendingTolimBanner.dart';
import 'ManagerTools/AnimatedStarBanner.dart';
import 'ManagerTools/AnimatedTolimBanner.dart';
import 'ManagerTools/AnimatedXpBanner.dart';
import 'package:mortaalim/ManagerTools/LevelUpOverlayHelper.dart';
import 'package:uuid/uuid.dart';

import 'main.dart';

class ExperienceManager extends ChangeNotifier with WidgetsBindingObserver {
  // User progress & rewards
  int _xp = 0;
  int _stars = 5;
  int Tolims = 20;

  // Customization
  List<String> _unlockedAvatars = ["🐱", "🐻"];
  String _selectedAvatar = 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png';

  List<String> _unlockedCourses = [];
  List<String> _unlockedLanguages = ['arabic', 'french'];

  List<String> _unlockedBanners = [
    'assets/images/Banners/CuteBr/Banner1.png',
    'assets/images/Banners/CuteBr/Banner2.png',
    'assets/images/Banners/CuteBr/Banner3.png',
  ];
  String _selectedBannerImage = 'assets/images/Banners/CuteBr/Banner3.png';

  String _selectedAvatarFrame = '';
  List<String> _unlockedAvatarFrames = [];

  // User personal info
  String? _userId;

  String _fullName = '';
  int _age = 0;
  String _country = '';
  String _city = '';
  String _gender = '';
  String _email = '';

  String _preferredLanguage = 'fr';

  // UX & animations
  int _recentlyAddedTokens = 0;
  int _recentlyAddedStars = 0;
  bool _showTokenFlash = false;
  bool _showStarFlash = false;

  Timer? _rewardTimer;
  Timer? _delayedRestartTimer;

  static const rewardCooldown = Duration(minutes: 30);
  static const inactivityRestartDelay = Duration(seconds: 5);

  // Ads toggle
  bool _adsEnabled = true;

  // Login/logout tracking
  DateTime? _lastLogin;
  DateTime? _lastLogout;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExperienceManager() {
    WidgetsBinding.instance.addObserver(this);
    loadData();
  }

  // -------------- XP System -------------------

  int getXPForLevel(int level) => level * level * 50;

  int get level {
    int lvl = 1;
    while (_xp >= getXPForLevel(lvl)) {
      lvl++;
    }
    return lvl;
  }

  double get levelProgress {
    int currentLevel = level;
    int prevXP = getXPForLevel(currentLevel - 1);
    int nextXP = getXPForLevel(currentLevel);
    return ((_xp - prevXP) / (nextXP - prevXP)).clamp(0.0, 1.0);
  }

  int get currentLevelXP => _xp - getXPForLevel(level - 1);
  int get requiredXPForNextLevel => getXPForLevel(level) - getXPForLevel(level - 1);

  // -------------- Getters -------------------

  int get xp => _xp;
  int get stars => _stars;
  int get saveTokenCount => Tolims;

  List<String> get unlockedAvatars => _unlockedAvatars;
  String get selectedAvatar => _selectedAvatar;

  Locale get locale => Locale(_preferredLanguage);
  List<String> get unlockedCourses => _unlockedCourses;
  List<String> get unlockedLanguages => _unlockedLanguages;

  List<String> get unlockedBanners => _unlockedBanners;
  String get selectedBannerImage => _selectedBannerImage;

  String get selectedAvatarFrame => _selectedAvatarFrame;
  List<String> get unlockedAvatarFrames => _unlockedAvatarFrames;

  String get fullName => _fullName;
  int get age => _age;
  String get country => _country;
  String get city => _city;
  String get gender => _gender;
  String get email => _email;

  String get preferredLanguage => _preferredLanguage;

  int get recentlyAddedTokens => _recentlyAddedTokens;
  int get recentlyAddedStars => _recentlyAddedStars;

  bool get showTokenFlash => _showTokenFlash;
  bool get showStarFlash => _showStarFlash;

  bool get adsEnabled => _adsEnabled;

  DateTime? get lastLogin => _lastLogin;
  DateTime? get lastLogout => _lastLogout;

  // ---------------- User setters -------------------

  void setFullName(String name) {
    if (_fullName != name) {
      _fullName = name;
      _saveData(); // ✅ Save change
      notifyListeners();
    }
  }


  void setAge(int age) {
    _age = age;
    _saveData();
    notifyListeners();
  }

  void setCountry(String country) {
    _country = country;
    _saveData();
    notifyListeners();
  }

  void setCity(String city) {
    _city = city;
    _saveData();
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    _saveData();
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _saveData();
    notifyListeners();
  }


  // ---------------- Other setters (customization) -------------------

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

  void setPreferredLanguage(String lang) {
    if (_preferredLanguage != lang) {
      _preferredLanguage = lang;
      _saveData();
      notifyListeners();
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

  Future<void> changeLanguage(Locale locale) async {
    _preferredLanguage = locale.languageCode;
    await _saveData(); // save to SharedPreferences
    notifyListeners();
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

  // ---------------- Reward & Banner methods -------------------

  void addTokenBanner(BuildContext context, int amount) {
    if (_tokenBannerVisible) return;

    Tolims += amount;
    _recentlyAddedTokens = amount;
    _recentlyAddedStars = 0;
    _showTokenFlash = true;
    notifyListeners();

    _tokenBannerVisible = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      _showTokenFlash = false;
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 1), () {
      _recentlyAddedTokens = 0;
      _tokenBannerVisible = false;
      notifyListeners();
    });

    _saveData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final overlay = Overlay.of(context);
      if (overlay == null) return;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => AnimatedTokenBanner(
          tokenAmount: amount,
          onDismiss: () {
            entry.remove();
            _tokenBannerVisible = false;
          },
        ),
      );
      overlay.insert(entry);
    });
  }

  void SpendTokenBanner(BuildContext context, int amount) async{
    Tolims -= amount;
    _recentlyAddedTokens = -amount;
    _showTokenFlash = false;
    await _saveData(); // ✅ Save immediately
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

  bool _tokenBannerVisible = false;
  bool _starBannerVisible = false;


  void addStarBanner(
      BuildContext context,
      int amount, {
        GlobalKey? starIconKey,
        Offset? animationFrom,
        Offset? animationTo,
      }) {
    if (amount <= 0) return;

    final oldStars = _stars;
    _stars += amount;
    _recentlyAddedStars = amount;
    _recentlyAddedTokens = 0;
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

    // StarCountPulse overlay
    if (starIconKey != null && starIconKey.currentContext != null) {
      final overlay = Overlay.of(context);
      if (overlay != null) {
        final box = starIconKey.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;

        const animationSize = 26.0;
        final adjustedPosition = Offset(
          position.dx + size.width / 2 - animationSize / 2,
          position.dy + size.height / 2 - animationSize / 2,
        );

        late OverlayEntry pulseEntry;
        pulseEntry = OverlayEntry(
          builder: (_) => Positioned(
            top: adjustedPosition.dy - 7,
            left: adjustedPosition.dx + 15,
            child: Material(
              color: Colors.transparent,
              child: StarCountPulse(
                oldStars: oldStars,
                deduction: -amount,
                onFinish: () => pulseEntry.remove(),
              ),
            ),
          ),
        );
        overlay.insert(pulseEntry);
      }
    }

    // StarDeductionOverlay
    if (animationFrom != null && animationTo != null) {
      StarDeductionOverlay.showStarAnimation(
        context,
        from: animationFrom,
        to: animationTo,
        starCount: amount,
        onComplete: () {},
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final overlay = Overlay.of(context);
      if (overlay == null) return;

      late OverlayEntry bannerEntry;
      bannerEntry = OverlayEntry(
        builder: (ctx) => AnimatedStarBanner(
          starAmount: amount,
          onDismiss: () => bannerEntry.remove(),
        ),
      );
      overlay.insert(bannerEntry);
    });
  }

  void SpendStarBanner(BuildContext context, int amount) async{
    _stars -= amount;
    _recentlyAddedStars = -amount;
    _showStarFlash = false;
    await _saveData(); // ✅ Save immediately
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context);
      if (!context.mounted) return;

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

  void resetData() {
    _xp = 0;
    _stars = 0;
    Tolims = 20;
    _unlockedAvatars = ["🐱", "🐻"];
    _selectedAvatar = 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png';
    _unlockedCourses = [];
    _unlockedLanguages = ['arabic', 'french'];
    _saveData();
    notifyListeners();
  }


  Future<void> initUser() async {
    // 1. Always load local data first (instant offline loading)
    await loadData();

    // 2. If online, login Firebase (optional)
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _userId = 'offline_user';
      if (kDebugMode) print('Offline mode: Local data only');
      notifyListeners();
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        _userId = userCredential.user!.uid;
      } else {
        _userId = currentUser.uid;
      }

      // 3. Background cloud sync (doesn't block UI)
      syncWithFirebaseIfOnline();
    } catch (e) {
      _userId = 'offline_user';
      if (kDebugMode) print('Firebase login failed. Offline only: $e');
    }

    notifyListeners();
  }



  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        await syncWithFirebaseIfOnline();
      }
    });
  }



  // ---------------- Local Storage Load/Save -------------------

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('xp') ?? 0;
    _stars = prefs.getInt('stars') ?? 5;
    Tolims = prefs.getInt('saveTokens') ?? 20;

    _unlockedAvatars = prefs.getStringList('unlockedAvatars') ?? ["🐱", "🐻", 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png', 'assets/images/AvatarImage/OnlyAvatar/Avatar2.png', 'assets/images/AvatarImage/OnlyAvatar/Avatar3.png', 'assets/images/AvatarImage/OnlyAvatar/Avatar4.png'];
    _unlockedBanners = prefs.getStringList('unlockedBanners') ?? ['assets/images/Banners/CuteBr/Banner1.png', 'assets/images/Banners/CuteBr/Banner2.png', 'assets/images/Banners/CuteBr/Banner3.png'];
    _unlockedCourses = prefs.getStringList('unlockedCourses') ?? ['AlphaDraw', 'BrainQuest'];
    _unlockedLanguages = prefs.getStringList('unlockedLanguages') ?? ['arabic', 'french'];
    _selectedAvatar = prefs.getString('selectedAvatar') ?? 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png';
    _selectedBannerImage = prefs.getString('selectedBannerImage') ?? 'assets/images/Banners/CuteBr/Banner1.png';
    _selectedAvatarFrame = prefs.getString('selectedAvatarFrame') ?? '';
    _unlockedAvatarFrames = prefs.getStringList('unlockedAvatarFrames') ?? [''];

    _fullName = prefs.getString('fullName') ?? '';
    _age = prefs.getInt('age') ?? 0;
    _country = prefs.getString('country') ?? '';
    _city = prefs.getString('city') ?? '';
    _gender = prefs.getString('gender') ?? '';
    _email = prefs.getString('email') ?? '';
    _preferredLanguage = prefs.getString('preferredLanguage') ?? 'fr';

    _adsEnabled = prefs.getBool('adsEnabled') ?? true;

    notifyListeners();
  }


  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', _xp);
    await prefs.setInt('stars', _stars);
    await prefs.setInt('saveTokens', Tolims);
    await prefs.setStringList('unlockedAvatars', _unlockedAvatars);
    await prefs.setStringList('unlockedBanners', _unlockedBanners);
    await prefs.setStringList('unlockedCourses', _unlockedCourses);
    await prefs.setStringList('unlockedLanguages', _unlockedLanguages);
    await prefs.setString('selectedAvatar', _selectedAvatar);
    await prefs.setString('selectedBannerImage', _selectedBannerImage);
    await prefs.setString('selectedAvatarFrame', _selectedAvatarFrame);
    await prefs.setStringList('unlockedAvatarFrames', _unlockedAvatarFrames);

    // Personal info
    await prefs.setString('fullName', _fullName);
    await prefs.setInt('age', _age);
    await prefs.setString('country', _country);
    await prefs.setString('city', _city);
    await prefs.setString('gender', _gender);
    await prefs.setString('email', _email);
    await prefs.setString('preferredLanguage', _preferredLanguage);
  }

  // ---------------- Firebase Sync -------------------
  Future<void> syncWithFirebaseIfOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;
    if (_userId == null || _userId == 'offline_user') return;

    final userDoc = _firestore.collection('users').doc(_userId);

    try {
      // ✅ Do NOT read from Firebase for stars/tolims — local is always source of truth

      // Save locally before pushing
      await _saveData();

      // Always push local data to Firebase
      await userDoc.set({
        "xp": _xp,
        "stars": _stars,
        "tolims": Tolims,
        "unlockedAvatars": _unlockedAvatars,
        "unlockedBanners": _unlockedBanners,
        "unlockedLanguages": _unlockedLanguages,
        "unlockedCourses": _unlockedCourses,
        "unlockedAvatarFrames": _unlockedAvatarFrames,
        "selectedAvatar": _selectedAvatar,
        "selectedBannerImage": _selectedBannerImage,
        "selectedAvatarFrame": _selectedAvatarFrame,
        "fullName": _fullName,
        "age": _age,
        "country": _country,
        "city": _city,
        "gender": _gender,
        "email": _email,
        "preferredLanguage": _preferredLanguage,
        "adsEnabled": _adsEnabled,
      }, SetOptions(merge: true));

      print("✅ Local data pushed to Firebase");
    } catch (e) {
      if (kDebugMode) print("❌ Firebase sync failed: $e");
    }
  }



  String generateBackupCode({int length = 6}) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => characters[random.nextInt(characters.length)]).join();
  }

  Future<String> saveBackup() async {
    String backupCode;

    // Generate a unique backup code with timestamp if duplicate is found
    while (true) {
      backupCode = generateBackupCode(length: 6);
      final doc = await _firestore.collection('backups').doc(backupCode).get();

      if (!doc.exists) break; // Ensure no duplicate
      // Add timestamp if duplicate exists (extra uniqueness)
      backupCode = "${backupCode}_${DateTime.now().millisecondsSinceEpoch}";
      break;
    }

    await _firestore.collection('backups').doc(backupCode).set({
      "xp": _xp,
      "stars": _stars,
      "tolims": Tolims,
      "unlockedAvatars": _unlockedAvatars,
      "unlockedBanners": _unlockedBanners,
      "unlockedLanguages": _unlockedLanguages,
      "unlockedCourses": _unlockedCourses,
      "unlockedAvatarFrames": _unlockedAvatarFrames,
      "selectedAvatar": _selectedAvatar,
      "selectedBannerImage": _selectedBannerImage,
      "selectedAvatarFrame": _selectedAvatarFrame,
      "fullName": _fullName,
      "age": _age,
      "country": _country,
      "city": _city,
      "gender": _gender,
      "email": _email,
      "preferredLanguage": _preferredLanguage,
      "adsEnabled": _adsEnabled,
      "createdAt": FieldValue.serverTimestamp(),
    });

    print("✅ Backup saved with code: $backupCode");
    return backupCode;
  }


  Future<void> loadBackup(String backupCode) async {
    final backupDoc = await _firestore.collection('backups').doc(backupCode).get();

    if (!backupDoc.exists) {
      print("❌ Backup not found");
      return;
    }

    final data = backupDoc.data()!;

    _xp = data["xp"] ?? 0;
    _stars = data["stars"] ?? 0;
    Tolims = data["tolims"] ?? 0;
    _unlockedAvatars = List<String>.from(data["unlockedAvatars"] ?? []);
    _unlockedBanners = List<String>.from(data["unlockedBanners"] ?? []);
    _unlockedLanguages = List<String>.from(data["unlockedLanguages"] ?? []);
    _unlockedCourses = List<String>.from(data["unlockedCourses"] ?? []);
    _unlockedAvatarFrames = List<String>.from(data["unlockedAvatarFrames"] ?? []);
    _selectedAvatar = data["selectedAvatar"] ?? _selectedAvatar;
    _selectedBannerImage = data["selectedBannerImage"] ?? _selectedBannerImage;
    _selectedAvatarFrame = data["selectedAvatarFrame"] ?? _selectedAvatarFrame;
    _fullName = data["fullName"] ?? _fullName;
    _age = data["age"] ?? _age;
    _country = data["country"] ?? _country;
    _city = data["city"] ?? _city;
    _gender = data["gender"] ?? _gender;
    _email = data["email"] ?? _email;
    _preferredLanguage = data["preferredLanguage"] ?? _preferredLanguage;
    _adsEnabled = data["adsEnabled"] ?? _adsEnabled;

    await _saveData();
    print("✅ Backup loaded successfully from code: $backupCode");

    // 🔄 Restart app flow by navigating to Auth screen
    navigatorKey.currentState?.pushNamedAndRemoveUntil('Auth', (route) => false);
  }



  // ---------------- Track Login & Logout -------------------

  void onAppStart(String userId) {
    _lastLogin = DateTime.now();
    _userId = userId; // Assign the passed userId to the private field
    syncWithFirebaseIfOnline();
  }

  Future<void> onAppClose() async {
    _lastLogout = DateTime.now();
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).set({
        "lastLogout": _lastLogout?.toIso8601String(),
      }, SetOptions(merge: true));
    }
    await _saveData();
  }

  // ----------------------------------------------------------

  // The rest of your ExperienceManager code remains unchanged...

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

  void init(BuildContext context) {

  }

  // ADS MANAGER

  void setAdsEnabled(bool value) {
    _adsEnabled = value;
    _saveAdsPreference();
    notifyListeners();
  }

  Future<void> _saveAdsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adsEnabled', _adsEnabled);
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rewardTimer?.cancel();
    _delayedRestartTimer?.cancel();
    super.dispose();
  }
}
