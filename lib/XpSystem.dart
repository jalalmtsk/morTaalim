import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/Services/YoutubeProgressManager.dart';
import 'package:mortaalim/Manager/models/CourseProgressionManager.dart';
import 'package:mortaalim/Manager/models/InventoryPet.dart';

import 'package:mortaalim/ManagerTools/StarCountPulse.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

//MANAGERS/MODELS
import 'Manager/models/LearningPrefrences.dart';
import 'Manager/models/customazationSetting.dart';
import 'Manager/models/user_profile.dart';

// Manager TOOLS BANNERS STAR /XP /TOLIM /LEVEL UP
import 'ManagerTools/AnimatedSpendingStarBanner.dart';
import 'ManagerTools/AnimatedSpendingTolimBanner.dart';
import 'ManagerTools/AnimatedStarBanner.dart';
import 'ManagerTools/AnimatedTolimBanner.dart';
import 'ManagerTools/AnimatedXpBanner.dart';
import 'package:mortaalim/ManagerTools/LevelUpOverlayHelper.dart';

import 'ManagerTools/StarDeductionOverlay.dart';
import 'main.dart';

class ExperienceManager extends ChangeNotifier with WidgetsBindingObserver {
  // User progress & rewards
  int _xp = 0;
  int _stars = 5;
  int Tolims = 20;

  //------------------------------------------------------------------//

  // Customization
  List<String> _unlockedCourses = [];
  List<String> _unlockedLanguages = ['arabic', 'french'];

  // User personal info
  String? _userId;

  UserProfile userProfile = UserProfile();
  YoutubeProgressManager youtubeProgressManager = YoutubeProgressManager();
  CourseProgressionManager courseProgressionManager = CourseProgressionManager();
  Inventory inventoryManager = Inventory();
  // Customazation
  CustomizationSettings customization = CustomizationSettings();

  //LearningPreferenes
  LearningPreferences learningPreferences = LearningPreferences();

  // UX & animations
  int _recentlyAddedTokens = 0;
  int _recentlyAddedStars = 0;
  bool _showTokenFlash = false;
  bool _showStarFlash = false;

  Timer? _rewardTimer;
  Timer? _delayedRestartTimer;

  bool get isFirstLogin => lastLogin == null;

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

  //------------------------------------------------------------------//


  List<String> get unlockedAvatars => customization.unlockedAvatars;
  String get selectedAvatar => customization.selectedAvatar;

  Locale get locale => Locale(userProfile.preferredLanguage);
  List<String> get unlockedCourses => _unlockedCourses;
  List<String> get unlockedLanguages => _unlockedLanguages;

  List<String> get unlockedBanners => customization.unlockedBanners;
  String get selectedBannerImage => customization.selectedBannerImage;

  String get selectedAvatarFrame => customization.selectedAvatarFrame;
  List<String> get unlockedAvatarFrames => customization.unlockedAvatarFrames;

  int get recentlyAddedTokens => _recentlyAddedTokens;
  int get recentlyAddedStars => _recentlyAddedStars;

  bool get showTokenFlash => _showTokenFlash;
  bool get showStarFlash => _showStarFlash;

  bool get adsEnabled => _adsEnabled;

  DateTime? get lastLogin => _lastLogin;
  DateTime? get lastLogout => _lastLogout;



  // ---------------- User setters -------------------

  void setFullName(String name) {
    if (userProfile.fullName != name) {
      userProfile.fullName = name;
      _saveData(); // ✅ Save change
      notifyListeners();
    }
  }

  void setLastName(String name) {
    if (userProfile.lastName != name) {
      userProfile.lastName = name;
      _saveData(); // ✅ Save change
      notifyListeners();
    }
  }

  void setSchoolName(String schoolName) {
    if (userProfile.schoolName != schoolName) {
      userProfile.schoolName = schoolName;
      _saveData(); // ✅ Save change
      notifyListeners();
    }
  }

  void setSpecialNeeds(String specialNeeds) {
    if (userProfile.specialNeeds != specialNeeds) {
      userProfile.specialNeeds = specialNeeds;
      _saveData();
      notifyListeners();
    }
  }

  void setParentGuardianName(String parentGuardianName) {
    if (userProfile.parentGuardianName != parentGuardianName) {
      userProfile.parentGuardianName = parentGuardianName;
      _saveData();
      notifyListeners();
    }
  }

  void setBirthday(String birthday) {
    if (userProfile.birthday != birthday) {
      userProfile.birthday = birthday;
      _saveData();
      notifyListeners();
    }
  }

  void setSchoolType(String schoolType) {
    if (userProfile.schoolType != schoolType) {
      userProfile.schoolType = schoolType;
      _saveData();
      notifyListeners();
    }
  }

  void setSchoolGrade(String schoolGrade) {
    if (userProfile.schoolGrade != schoolGrade) {
      userProfile.schoolGrade = schoolGrade;
      _saveData();
      notifyListeners();
    }
  }

  String get schoolLevel => userProfile.schoolLevel ?? '';
  String get lyceeTrack => userProfile.lyceeTrack ?? '';

  void setSchoolLevel(String value) {
    if (userProfile.schoolLevel != value) {
      userProfile.schoolLevel = value;
      _saveData();
      notifyListeners();
    }
  }

  void setLyceeTrack(String value) {
    if (userProfile.lyceeTrack != value) {
      userProfile.lyceeTrack = value;
      _saveData();
      notifyListeners();
    }
  }

  void setAge(int age) {
    userProfile.age = age;
    _saveData();
    notifyListeners();
  }

  void setCountry(String country) {
    userProfile.country = country;
    _saveData();
    notifyListeners();
  }

  void setCity(String city) {
    userProfile.city = city;
    _saveData();
    notifyListeners();
  }

  void setGender(String gender) {
    userProfile.gender = gender;
    _saveData();
    notifyListeners();
  }

  void setEmail(String email) {
    userProfile.email = email;
    _saveData();
    notifyListeners();
  }


  // ---------------- Other setters (customization) -------------------

  void unlockAvatar(String emoji) {
    if (!customization.unlockedAvatars.contains(emoji)) {
      customization.unlockedAvatars.add(emoji);
      _saveData();
      notifyListeners();
    }
  }

  void selectAvatar(String emoji) {
    if (customization.unlockedAvatars.contains(emoji)) {
      customization.selectedAvatar = emoji;
      _saveData();
      notifyListeners();
    }
  }

  void unlockBanner(String path) {
    if (!customization.unlockedBanners.contains(path)) {
      customization.unlockedBanners.add(path);
      _saveData();
      notifyListeners();
    }
  }

  void selectBannerImage(String path) {
    if (customization.unlockedBanners.contains(path)) {
      customization.selectedBannerImage = path;
      _saveData();
      notifyListeners();
    }
  }

  void unlockAvatarFrame(String path) {
    if (!customization.unlockedAvatarFrames.contains(path)) {
      customization.unlockedAvatarFrames.add(path);
      _saveData();
      notifyListeners();
    }
  }

  void selectAvatarFrame(String path) {
    if (customization.unlockedAvatarFrames.contains(path)) {
      customization.selectedAvatarFrame = path;
      _saveData();
      notifyListeners();
    }
  }

  void setPreferredLanguage(String lang) {
    if (userProfile.preferredLanguage != lang) {
      userProfile.preferredLanguage = lang;
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
    userProfile.preferredLanguage = locale.languageCode;
    await _saveData(); // save to SharedPreferences
    notifyListeners();
  }

  bool buySaveTokens({int amount = 3}) {
    if (Tolims >= amount && amount > 0) {
      int starsToAdd = amount ~/ 3; // 3 Tolims per star
      Tolims -= starsToAdd * 3;
      _stars += starsToAdd;
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }



  //----------------------------Learning Preferences--------------------------------
  void setBetterSubjects(List<String> subjects) {
    learningPreferences.betterSubjects = subjects;
    _saveData();
    notifyListeners();
  }

  void setPreferredLearningStyle(String style) {
    learningPreferences.preferredLearningStyle = style;
    _saveData();
    notifyListeners();
  }

  void setStudyTimePreference(String timePreference) {
    learningPreferences.studyTimePreference = timePreference;
    _saveData();
    notifyListeners();
  }

  void setDifficultyPreference(String difficulty) {
    learningPreferences.difficultyPreference = difficulty;
    _saveData();
    notifyListeners();
  }

  void setGoalType(String goalType) {
    learningPreferences.goalType = goalType;
    _saveData();
    notifyListeners();
  }

  void setWeeklyGoal(String weeklyGoal) {
    learningPreferences.weeklyGoal = weeklyGoal;
    _saveData();
    notifyListeners();
  }

  void setLongTermGoal(String longTermGoal) {
    learningPreferences.longTermGoal = longTermGoal;
    _saveData();
    notifyListeners();
  }


  //-------------------YoutubeVideoReward----------------------------

  /// Mark a video as completed
  Future<void> markVideoCompleted({required String videoId}) async {
    if (!youtubeProgressManager.completedVideoIds.contains(videoId)) {
      youtubeProgressManager.completedVideoIds.add(videoId);
       _saveData();
      notifyListeners();
    }
  }

  // Methods to add or remove completed videos
  void addCompletedVideo(String videoId) {
    youtubeProgressManager.completedVideoIds.add(videoId);
     _saveData();
    notifyListeners();
  }

  void removeCompletedVideo(String videoId) {
    youtubeProgressManager.completedVideoIds.remove(videoId);
     _saveData();
    notifyListeners();
  }


  //--------------------InvetoryPet Methods-----------------------------------

  /// Add food and notify listeners
  Future<void> addFood(int amount) async {
    if (amount <= 0) return;
    inventoryManager.food += amount;
    await _saveData();
    notifyListeners();
  }

  /// Spend food if possible; return true if success
  Future<bool> spendFood(int amount) async {
    if (amount <= 0 || amount > inventoryManager.food) return false;
    inventoryManager.food -= amount;
    await _saveData();
    notifyListeners();
    return true;
  }

  /// Add water and notify listeners
  Future<void> addWater(int amount) async {
    if (amount <= 0) return;
    inventoryManager.water += amount;
    await _saveData();
    notifyListeners();
  }

  /// Spend water if possible; return true if success
  Future<bool> spendWater(int amount) async {
    if (amount <= 0 || amount > inventoryManager.water) return false;
    inventoryManager.water -= amount;
    await _saveData();
    notifyListeners();
    return true;
  }

  /// Add energy and notify listeners
  Future<void> addEnergy(int amount) async {
    if (amount <= 0) return;
    inventoryManager.energy += amount;
    await _saveData();
    notifyListeners();
  }

  /// Spend energy if possible; return true if success
  Future<bool> spendEnergy(int amount) async {
    if (amount <= 0 || amount > inventoryManager.energy) return false;
    inventoryManager.energy -= amount;
    await _saveData();
    notifyListeners();
    return true;
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


  void addXP(int amount, {BuildContext? context}) async {
    final int oldLevel = level;
    _xp += amount;
    final int newLevel = level;

    if (newLevel > oldLevel) {
      addStarBanner(context!, newLevel - oldLevel);
    }
    _saveData();
    notifyListeners();

    if (context != null && context.mounted) {
      // Slight delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 100));

      // 1️⃣ Show XP banner and wait until it disappears
      await AnimatedXPBanner.show(context, amount);

      // 2️⃣ Only after XP banner ends, show Level Up banner if level increased
      if (newLevel > oldLevel && context.mounted) {
        await LevelUpOverlayHelper.showOverlayLevelUpBanner(context, newLevel);
      }
    }
  }



//----------------------------------------------------------------------------------
  void resetData() {
    userProfile.clearPrefs(prefs);
    learningPreferences.clearPrefs(prefs);
    inventoryManager.clearPrefs(prefs);
    _xp = 0;
    _stars = 0;
    Tolims = 20;
    customization.unlockedAvatars = ["🐱", "🐻"];
    customization.selectedAvatar = 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png';
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

    _unlockedCourses = prefs.getStringList('unlockedCourses') ?? ['AlphaDraw', 'BrainQuest'];
    _unlockedLanguages = prefs.getStringList('unlockedLanguages') ?? ['arabic', 'french'];

    userProfile = UserProfile.fromPrefs(prefs);
    customization = CustomizationSettings.fromPrefs(prefs);
    courseProgressionManager = await CourseProgressionManager.fromPrefs(prefs);
    youtubeProgressManager = await YoutubeProgressManager.fromPrefs(prefs);
    inventoryManager = await Inventory.fromPrefs(prefs);
    _adsEnabled = prefs.getBool('adsEnabled') ?? true;

    notifyListeners();
  }


  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', _xp);
    await prefs.setInt('stars', _stars);
    await prefs.setInt('saveTokens', Tolims);

    await prefs.setStringList('unlockedCourses', _unlockedCourses);
    await prefs.setStringList('unlockedLanguages', _unlockedLanguages);

    await courseProgressionManager.saveToPrefs(prefs);
    // Personal info
    await userProfile.saveToPrefs(prefs);
    //Customazations
    await customization.saveToPrefs(prefs);

    await inventoryManager.saveToPrefs(prefs);
    // YoutubeProgressManager
    youtubeProgressManager.saveToPrefs(prefs);
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

        "unlockedLanguages": _unlockedLanguages,
        "unlockedCourses": _unlockedCourses,

        "adsEnabled": _adsEnabled,

        ...userProfile.toMap(),
        ...customization.toMap(), // <-- include AVATAR/ BANNER
        ...learningPreferences.toMap(),
        ...courseProgressionManager.toMap(),
        ...inventoryManager.toMap(),
        ...youtubeProgressManager.toMap(),

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

    while (true) {
      backupCode = generateBackupCode(length: 6);
      final doc = await _firestore.collection('backups').doc(backupCode).get();

      if (!doc.exists) break;
      backupCode = "${backupCode}_${DateTime.now().millisecondsSinceEpoch}";
      break;
    }

    final backupData = {
      ...userProfile.toMap(),
      ...customization.toMap(),
      ...courseProgressionManager.toMap(),
      ...inventoryManager.toMap(),
      ...youtubeProgressManager.toMap(),

      "xp": _xp,
      "stars": _stars,
      "tolims": Tolims,
      "unlockedLanguages": _unlockedLanguages,
      "unlockedCourses": _unlockedCourses,
      "adsEnabled": _adsEnabled,
      "createdAt": FieldValue.serverTimestamp(),
    };

    await _firestore.collection('backups').doc(backupCode).set(backupData);

    print("✅ Backup saved with code: $backupCode");
    return backupCode;
  }

  Future<void> loadBackup(String backupCode) async {
    final backupDoc = await _firestore.collection('backups').doc(backupCode).get();

    if (!backupDoc.exists) {
      print("❌ Backup not found");
      throw Exception("Backup not found");
    }

    final data = backupDoc.data()!;
    userProfile.loadFromMap(data);

    _xp = data["xp"] ?? 0;
    _stars = data["stars"] ?? 0;
    Tolims = data["tolims"] ?? 0;

    _unlockedLanguages = List<String>.from(data["unlockedLanguages"] ?? []);
    _unlockedCourses = List<String>.from(data["unlockedCourses"] ?? []);

    customization.loadFromMap(data);
    courseProgressionManager.loadFromMap(data);
    inventoryManager.loadFromMap(data);
    youtubeProgressManager.loadFromMap(data);

    _adsEnabled = data["adsEnabled"] ?? _adsEnabled;

    await _saveData();
    print("✅ Backup loaded successfully from code: $backupCode");

    // Navigate to Auth screen (restart flow)
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
