import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/UserInfoForm_Introduction.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Authentification/LogIn.dart';
import '../../tools/Ads_Manager.dart';
import 'CompanyLogoScreen.dart';
import 'LoadingScreen.dart';

// ─── NOTE : AgeCheckPage et setChildMode supprimés ───────────────────────────
// MoorTaalim est une appli 100% enfants. La config COPPA est appliquée une
// seule fois dans AdHelper.initializeAds() et ne change jamais.
// ─────────────────────────────────────────────────────────────────────────────

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  bool _showLoadingScreen = false;
  double _progress = 0.0;
  final FlutterTts _tts = FlutterTts();
  late List<_PreloadTask> _tasks;
  bool _loadingComplete = false;

  @override
  void initState() {
    super.initState();

    _tasks = [
      _PreloadTask("Preload Assets", _preloadAssets),
      _PreloadTask("Initialize TTS", _initTTS),
      _PreloadTask("Final Setup", _finalSetup),
    ];
  }

  // Called by CompanyLogoScreen itself the instant its Lottie animation
  // actually finishes (or its own safety-net timeout fires) — so this
  // phase takes exactly as long as the animation is designed to take,
  // not a guessed delay that could cut it off early or pad it with dead
  // air.
  void _onLogoFinished() {
    if (!mounted) return;
    setState(() => _showLoadingScreen = true);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    for (var i = 0; i < _tasks.length; i++) {
      await _runWithTimeout(_tasks[i].name, _tasks[i].action);
      await _animateProgress((i + 1) / _tasks.length);
    }

    if (!mounted) return;

    // The Lottie/audio intro is now the very first thing shown on app
    // launch (see main.dart's initialRoute), ahead of any auth check —
    // previously AuthGate ran first and showed a bare CircularProgress-
    // Indicator while Firebase resolved, so users never actually saw the
    // splash animation before reaching either the login screen or the
    // app. The sign-in check now happens here instead, after the intro
    // has already played.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    if (xpManager.lastLogin == null ||
        xpManager.lastLogin!.isBefore(DateTime.now().subtract(const Duration(seconds: 2)))) {
      xpManager.onAppStart(user.uid);
    }

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserInfoForm()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Index()),
      );
    }
  }

  Future<void> _runWithTimeout(String name, Future<void> Function() action) async {
    debugPrint("Starting $name...");
    try {
      await action().timeout(const Duration(seconds: 4));
      debugPrint("$name completed!");
    } catch (e) {
      debugPrint("$name failed or timed out: $e");
    }
  }

  Future<void> _animateProgress(double target) async {
    final completer = Completer<void>();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final animation = Tween<double>(begin: _progress, end: target)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    animation.addListener(() {
      setState(() => _progress = animation.value);
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) completer.complete();
    });

    controller.forward();
    await completer.future;
    controller.dispose();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _preloadAssets() async {
    await rootBundle.load('assets/audios/SplashScreen_Audio/openingZoom.mp3');
    await rootBundle.load('assets/audios/HappyIntranceIndex.mp3');
    await rootBundle.load('assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3');
    await rootBundle.load('assets/audios/AppLogoSound.mp3');
    await precacheImage(const AssetImage('assets/icons/logo3.png'), context);
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.9);
  }

  Future<void> _finalSetup() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _showLoadingScreen
            ? LoadingScreen(
          key: const ValueKey('LoadingScreen'),
          progress: _progress,
          loadingComplete: _loadingComplete,
        )
            : CompanyLogoScreen(
          key: const ValueKey('CompanyLogoScreen'),
          onFinished: _onLogoFinished,
        ),
      ),
    );
  }
}

class _PreloadTask {
  final String name;
  final Future<void> Function() action;
  _PreloadTask(this.name, this.action);
}