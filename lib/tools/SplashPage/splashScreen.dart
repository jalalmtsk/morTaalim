import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/User_Input_Info_DataForm/User_Info_FirstCon/UserInfoForm_Introduction.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';

import 'CompanyLogoScreen.dart';
import 'LoadingScreen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key}); // ❌ Removed onChangeLocale

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  bool _showLoadingScreen = false;
  double _progress = 0.0;
  final FlutterTts _tts = FlutterTts();
  late List<_PreloadTask> _tasks;
  bool _loadingComplete = false;

  late AnimationController _logoFadeController;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = CurvedAnimation(
      parent: _logoFadeController,
      curve: Curves.easeInOut,
    );

    _tasks = [
      _PreloadTask("Preload Assets", _preloadAssets),
      _PreloadTask("Initialize AdMob", _initAdMob),
      _PreloadTask("Initialize TTS", _initTTS),
      _PreloadTask("Final Setup", _finalSetup),
    ];

    _startIntro();
  }

  void _startIntro() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/SplashScreen_Audio/modern_logo.mp3");
    audioManager.playSfx("assets/audios/SplashScreen_Audio/openingZoom.mp3");

    _logoFadeController.forward();

    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() => _showLoadingScreen = true);
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    for (var i = 0; i < _tasks.length; i++) {
      await _runWithTimeout(_tasks[i].name, _tasks[i].action);
      await _animateProgress((i + 1) / _tasks.length);
    }

    if (mounted) {
      setState(() => _loadingComplete = true);
      await Future.delayed(const Duration(milliseconds: 500));

      final xpManager = Provider.of<ExperienceManager>(context, listen: false);
      final user = xpManager.userProfile;
      debugPrint("Loaded language: ${user.preferredLanguage}");

      // ✅ Check if onboarding is needed
      final bool needsOnboarding = xpManager.isFirstLogin;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => needsOnboarding
              ? const UserInfoForm() // 👈 Go to onboarding
              : const Index(),          // 👈 Or go to main index page
        ),
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
    _logoFadeController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _preloadAssets() async {
    await rootBundle.load('assets/audios/SplashScreen_Audio/openingZoom.mp3');
    await rootBundle.load('assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3');
    await rootBundle.load('assets/audios/AppLogoSound.mp3');
    await precacheImage(const AssetImage('assets/icons/logo3.png'), context);
  }

  Future<void> _initAdMob() async {
    await MobileAds.instance.initialize();
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
        duration: const Duration(milliseconds: 800),
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
          fadeAnimation: _logoFade,
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
