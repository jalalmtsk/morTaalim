import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mortaalim/Pet/pet_widget.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Pet_Tools/InventoryPet_Card.dart';
import 'Pet_Tools/PetStatProgress.dart';

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

  int _feedProgress = 0;
  int _waterProgress = 0;
  int _playProgress = 0;

  bool _isEvolving = false;
  int _evolveSecondsLeft = 0;

  Timer? _evolveTimer;
  Timer? _decayTimer;

  late AnimationController _animationController;
  late SharedPreferences prefs;

  bool _showEffect = false; // For visual effect on interaction

  int get requiredStat => 4;
  int get actionMaxStat => 5;

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

      _feedProgress = prefs.getInt('feedProgress') ?? 0;
      _waterProgress = prefs.getInt('waterProgress') ?? 0;
      _playProgress = prefs.getInt('playProgress') ?? 0;

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

    await prefs.setInt('feedProgress', _feedProgress);
    await prefs.setInt('waterProgress', _waterProgress);
    await prefs.setInt('playProgress', _playProgress);

    await prefs.setBool('isEvolving', _isEvolving);
    await prefs.setInt('evolveSecondsLeft', _evolveSecondsLeft);
  }

  void _checkLevelUp() {
    if (!_isEvolving &&
        _feedProgress >= requiredStat &&
        _waterProgress >= requiredStat &&
        _playProgress >= requiredStat) {
      if (_level % 5 == 0) {
        _checkEvolutionStart();
      } else {
        setState(() {
          _level++;
          _feedProgress = 0;
          _waterProgress = 0;
          _playProgress = 0;
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
          _feed = (_feed - 1).clamp(0, actionMaxStat);
          _water = (_water - 1).clamp(0, actionMaxStat);
          _play = (_play - 1).clamp(0, actionMaxStat);
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
      _feedProgress = 0;
      _waterProgress = 0;
      _playProgress = 0;
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

    if (_isEvolving) return;

    setState(() {
      _showEffect = true; // show sparkle
      Timer(const Duration(seconds: 1), () => setState(() => _showEffect = false));

      switch (action) {
        case 'feed':
          if (_feedProgress >= requiredStat) return;
          if (inventory.food > 0 && _feed < actionMaxStat) {
            _feed++;
            xpManager.spendFood(1);
            if (_feed >= actionMaxStat) {
              _feed = 0;
              _feedProgress++;
            }
          }
          break;
        case 'water':
          if (_waterProgress >= requiredStat) return;
          if (inventory.water > 0 && _water < actionMaxStat) {
            _water++;
            xpManager.spendWater(1);
            if (_water >= actionMaxStat) {
              _water = 0;
              _waterProgress++;
            }
          }
          break;
        case 'play':
          if (_playProgress >= requiredStat) return;
          if (inventory.energy > 0 && _play < actionMaxStat) {
            _play++;
            xpManager.spendEnergy(1);
            if (_play >= actionMaxStat) {
              _play = 0;
              _playProgress++;
            }
          }
          break;
      }
    });

    _checkLevelUp();
    _savePetState();
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
      _feedProgress = 0;
      _waterProgress = 0;
      _playProgress = 0;
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
    final scaleAnim = Tween(begin: 1.0, end: 1.1).animate(_animationController);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final inventory = xpManager.inventoryManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 Virtual Pet Evolution'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Inventory & Level
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InventoryCard(
                      foodLeft: inventory.food,
                      waterLeft: inventory.water,
                      energyLeft: inventory.energy,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Level $_level',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    PetStatMiniCardProgress(
                      requiredStat: requiredStat,
                      feedProgress: _feedProgress,
                      waterProgress: _waterProgress,
                      playProgress: _playProgress,
                      maxPerLevel: requiredStat,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pet View / Evolution
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _isEvolving
                        ? EvolvingView(
                      scaleAnim: scaleAnim,
                      evolveSecondsLeft: _evolveSecondsLeft,
                      formatDuration: formatDuration,
                    )
                        : PetView(
                      petImage: petImage,
                      scaleAnim: scaleAnim,
                      feed: _feed,
                      water: _water,
                      play: _play,
                      onFeed: () => _tryInteract('feed'),
                      onWater: () => _tryInteract('water'),
                      onPlay: () => _tryInteract('play'),
                      maxStat: actionMaxStat,
                      isEvolving: _isEvolving,
                    ),
                    if (_showEffect)
                      const Icon(
                        Icons.star,
                        color: Colors.yellowAccent,
                        size: 80,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Reset Game", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    xpManager.addFood(200);
                    xpManager.addWater(200);
                    xpManager.addEnergy(200);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
