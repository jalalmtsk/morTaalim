import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

class BotWithGreeting extends StatefulWidget {
  const BotWithGreeting({super.key});

  @override
  State<BotWithGreeting> createState() => _BotWithGreetingState();
}

class _BotWithGreetingState extends State<BotWithGreeting> {
  final greetings = [
    // English
    "Hi 👋",
    "Hello!",
    "Hey there!",
    "Howdy!",
    "What's up?",
    "Nice to see you!",
    "Welcome!",
    "Good day!",
    "Hi friend!",
    "Hey buddy!",

    // French
    "Salut 👋",
    "Bonjour !",
    "Coucou !",
    "Allô !",
    "Bienvenue !",
    "Bonne journée !",
    "Enchanté !",
    "Salut mon ami !",
    "Salut toi !",
    "Hé !",

    // Arabic
    "مرحباً 👋",
    "أهلاً وسهلاً!",
    "السلام عليكم",
    "أهلاً بك!",
    "كيف حالك؟",
    "صباح الخير",
    "مساء الخير",
    "تشرفت بلقائك",
    "أهلاً يا صديقي!",
    "مرحباً بك!"
  ];
  String? currentGreeting;

  void _showGreeting() {
  final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('clickButton2');

    setState(() {
      currentGreeting = greetings[Random().nextInt(greetings.length)];
    });

    // Hide bubble after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => currentGreeting = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context, listen:false);
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Chat bubble
        if (currentGreeting != null)
          Positioned(
            bottom: 150, // Bubble above bot
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$currentGreeting ${xpManager.userProfile.fullName}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

        // Bot Lottie with tap
        Align(
          alignment: Alignment.bottomRight,
          child: GestureDetector(
            onTap: _showGreeting,
            child: Lottie.asset(
              "assets/animations/UI_Animations/WakiBot.json",
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
