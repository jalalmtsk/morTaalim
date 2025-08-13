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

  // Current round stats
  int _feed = 0;
  int _water = 0;
  int _play = 0;

  // Permanent progress counters
  int _feedProgress = 0;
  int _waterProgress = 0;
  int _playProgress = 0;

  bool _isEvolving = false;
  int _evolveSecondsLeft = 0;

  Timer? _evolveTimer;
  Timer? _decayTimer;

  late AnimationController _animationController;
  late SharedPreferences prefs;

  // Level-up requirement
  int get requiredStat => 4; // Fixed per your example (12/12)

  // Max stat per action
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    if (_isEvolving) return;

    setState(() {
      switch (action) {
        case 'feed':
          if (_feedProgress >= requiredStat) return; // lock if max
          if (inventory.food > 0) {
            _feed++;
            xpManager.spendFood(1);
            if (_feed >= actionMaxStat) {
              _feed = 0; // reset at 5
              _feedProgress++;
            }
          } else {
          }
          break;

        case 'water':
          if (_waterProgress >= requiredStat) return; // lock if max
          if (inventory.water > 0) {
            _water++;
            xpManager.spendWater(1);
            if (_water >= actionMaxStat) {
              _water = 0; // reset at 5
              _waterProgress++;
            }
          } else {

          }
          break;

        case 'play':
          if (_playProgress >= requiredStat) return; // lock if max
          if (inventory.energy > 0) {
            _play++;
            xpManager.spendEnergy(1);
            if (_play >= actionMaxStat) {
              _play = 0; // reset at 5
              _playProgress++;
            }
          } else {

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
            InventoryCard(
                foodLeft: inventory.food,
                waterLeft: inventory.water,
                energyLeft: inventory.energy),
            Text('Level $_level',
                style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            PetStatMiniCardProgress(
              requiredStat: requiredStat,
              feedProgress: _feedProgress,
              waterProgress: _waterProgress,
              playProgress: _playProgress,
              maxPerLevel: requiredStat,
            ),
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
                maxStat: actionMaxStat,
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
            ElevatedButton(
                onPressed: () {
                  xpManager.addFood(200);
                  xpManager.addWater(200);
                  xpManager.addEnergy(200);
                },
                child: const Text("Add"))
          ],
        ),
      ),
    );
  }
}
