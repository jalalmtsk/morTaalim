import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/Pet/pet_widget.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Pet_Tools/InventoryPet_Card.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage>
    with SingleTickerProviderStateMixin {
  int _level = 1;
  int _feed = 0;
  int _water = 0;
  int _play = 0;

  bool _isEvolving = false;
  int _evolveSecondsLeft = 0;

  Timer? _evolveTimer;
  Timer? _decayTimer;

  late AnimationController _animationController;
  late SharedPreferences prefs;

  static const int maxStat = 10;

  @override
  void initState() {
    super.initState();
    _loadPetState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _animationController.forward();
    _startDecayTimer();
  }

  Future<void> _loadPetState() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _level = prefs.getInt('level') ?? 1;
      _feed = prefs.getInt('feed') ?? 0;
      _water = prefs.getInt('water') ?? 0;
      _play = prefs.getInt('play') ?? 0;
      _isEvolving = prefs.getBool('isEvolving') ?? false;
      _evolveSecondsLeft = prefs.getInt('evolveSecondsLeft') ?? 0;

      if (_isEvolving && _evolveSecondsLeft > 0) {
        _startEvolveTimer();
      }
    });
  }

  Future<void> _savePetState() async {
    await prefs.setInt('level', _level);
    await prefs.setInt('feed', _feed);
    await prefs.setInt('water', _water);
    await prefs.setInt('play', _play);
    await prefs.setBool('isEvolving', _isEvolving);
    await prefs.setInt('evolveSecondsLeft', _evolveSecondsLeft);
  }

  void _checkLevelUp() {
    if (!_isEvolving &&
        _feed == maxStat &&
        _water == maxStat &&
        _play == maxStat) {
      if (_level % 5 == 0) {
        _checkEvolutionStart();
      } else {
        setState(() {
          _level++;
          _feed = 0;
          _water = 0;
          _play = 0;
        });
        _savePetState();
      }
    }
  }

  void _startDecayTimer() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isEvolving) {
        setState(() {
          _feed = (_feed - 1).clamp(0, maxStat);
          _water = (_water - 1).clamp(0, maxStat);
          _play = (_play - 1).clamp(0, maxStat);
        });
        _savePetState();
      }
    });
  }

  void _startEvolveTimer() {
    _evolveTimer?.cancel();
    _evolveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_evolveSecondsLeft > 0) {
          _evolveSecondsLeft--;
        } else {
          _finishEvolution();
        }
      });
      _savePetState();
    });
  }

  void _finishEvolution() {
    _evolveTimer?.cancel();
    _decayTimer?.cancel();

    setState(() {
      _isEvolving = false;
      _level++;
      _feed = 0;
      _water = 0;
      _play = 0;
      _evolveSecondsLeft = 0;
    });
    _savePetState();
    _startDecayTimer();
  }

  void _tryInteract(String action) {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final inventory = xpManager.inventoryManager;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    if (_isEvolving) return;
    setState(() {
      switch (action) {
        case 'feed':
          if(inventory.food > 0){
            audioManager.playSfx('assets/audios/sound_effects/spin.mp3');
            _feed = (_feed + 1).clamp(0, maxStat);
            xpManager.spendFood(1);
          }else{
            audioManager.playSfx('assets/audios/sound_effects/retro-rightLeft.mp3');
          }
          break;
        case 'water':
          if(inventory.water > 0){
            audioManager.playSfx('assets/audios/sound_effects/spin.mp3');
            _water = (_water + 1).clamp(0, maxStat);
            xpManager.spendWater(1);
          }
          break;
        case 'play':
          if(inventory.energy > 0){
            _play = (_play + 1).clamp(0, maxStat);
            xpManager.spendEnergy(1);
          }
          break;
      }
    });

    _savePetState();
    _checkLevelUp();
  }

  void _checkEvolutionStart() {
    if (_level % 5 == 0 && !_isEvolving) {
      int baseSeconds = 5 * 60;
      int additional = ((_level ~/ 5) - 1) * 4 * 60;
      _evolveSecondsLeft = baseSeconds + additional;

      setState(() {
        _isEvolving = true;
      });

      _startEvolveTimer();
    }
  }

  void _resetGame() async {
    _evolveTimer?.cancel();
    _decayTimer?.cancel();

    setState(() {
      _level = 1;
      _feed = 0;
      _water = 0;
      _play = 0;
      _isEvolving = false;
      _evolveSecondsLeft = 0;
    });

    await prefs.clear();
    _startDecayTimer();
  }

  String get petImage {
    if (_level < 6) return 'assets/images/PetImages/17.png';
    if (_level < 11) return 'assets/images/PetImages/18.png';
    if (_level < 16) return 'assets/images/PetImages/19.png';
    return 'assets/images/PetImages/20.png';
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _evolveTimer?.cancel();
    _decayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final scaleAnim =
    Tween(begin: 1.0, end: 1.1).animate(_animationController);
final xpManager = Provider.of<ExperienceManager>(context, listen: false);
final inventory = xpManager.inventoryManager;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Pet Evolution'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            InventoryCard(foodLeft: inventory.food, waterLeft: inventory.water,energyLeft: inventory.energy),
            Text('Level $_level',
                style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_isEvolving)
              EvolvingView(
                scaleAnim: scaleAnim,
                evolveSecondsLeft: _evolveSecondsLeft,
                formatDuration: formatDuration,
              )
            else
              PetView(
                petImage: petImage,
                scaleAnim: scaleAnim,
                feed: _feed,
                water: _water,
                play: _play,
                onFeed: () => _tryInteract('feed'),
                onWater: () => _tryInteract('water'),
                onPlay: () => _tryInteract('play'),
                maxStat: maxStat,
                isEvolving: _isEvolving,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Reset Game',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            ElevatedButton(onPressed: ()
            {
              xpManager.addFood(200);
              xpManager.addWater(200);
              xpManager.addEnergy(200);
            }, child: Text("Add"))
          ],
        ),
      ),
    );
  }
}
