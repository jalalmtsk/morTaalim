import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

class LoadingPage extends StatefulWidget {
  final Future<void> loadingFuture;
  final String nextRouteName;

  const LoadingPage({
    super.key,
    required this.loadingFuture,
    required this.nextRouteName,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late String selectedPhraseKey;
  bool showBottomCat = false;

  final List<String> phraseKeys = [
    'loadingPhrase1',
    'loadingPhrase2',
    'loadingPhrase3',
    'loadingPhrase4',
    'loadingPhrase5',
    'loadingPhrase6',
    'loadingPhrase7',
    'loadingPhrase8',
    'loadingPhrase9',
    'loadingPhrase10',
  ];

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final random = Random();
    selectedPhraseKey = phraseKeys[random.nextInt(phraseKeys.length)];

    // 50% chance to show bottom cat
    showBottomCat = random.nextBool();

    if (showBottomCat) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (mounted) {
          audioManager.playAlert("assets/audios/sound_effects/catMeow.mp3");
        }
      });
    }

    widget.loadingFuture.then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(widget.nextRouteName);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    // Map phrase key to localized string
    final Map<String, String> phraseMap = {
      'loadingPhrase1': tr.loadingPhrase1,
      'loadingPhrase2': tr.loadingPhrase2,
      'loadingPhrase3': tr.loadingPhrase3,
      'loadingPhrase4': tr.loadingPhrase4,
      'loadingPhrase5': tr.loadingPhrase5,
      'loadingPhrase6': tr.loadingPhrase6,
      'loadingPhrase7': tr.loadingPhrase7,
      'loadingPhrase8': tr.loadingPhrase8,
      'loadingPhrase9': tr.loadingPhrase9,
      'loadingPhrase10': tr.loadingPhrase10,
    };

    final phrase = phraseMap[selectedPhraseKey] ?? tr.loadingPhrase1;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              /// Top Lottie
              Center(
                child: Lottie.asset(
                  'assets/animations/UI_Animations/CuteGiraffe.json',
                  width: 350,
                  height: 340,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 16),

              /// Random funny phrase
              Text(
                phrase,
                style: const TextStyle(fontSize: 24, color: Colors.black),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              /// Optional bottom cat animation (50% chance)
              if (showBottomCat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Lottie.asset(
                    'assets/animations/cuteCat.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
