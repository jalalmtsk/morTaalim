import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../main.dart';

class HeavyLightApp extends StatelessWidget {
  const HeavyLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const HeavyLightGame();
  }
}

class HeavyLightGame extends StatefulWidget {
  const HeavyLightGame({super.key});

  @override
  _HeavyLightGameState createState() => _HeavyLightGameState();
}

class _HeavyLightGameState extends State<HeavyLightGame> {
  // Raw levels with localization keys
  final List<List<Map<String, dynamic>>> rawLevels = [
    [
      {
        "key": "elephant",
        "image": "assets/images/PractiseImage/HeavyLightImages/elephant.jpg",
        "type": "heavy",
        "sound": "assets/sounds/elephant.mp3",
        "wrongSound": "assets/sounds/wrong.mp3"
      },
      {
        "key": "rock",
        "image": "assets/images/PractiseImage/HeavyLightImages/rock.png",
        "type": "heavy",
        "sound": "assets/sounds/rock.mp3",
        "wrongSound": "assets/sounds/wrong.mp3"
      },
      {
        "key": "book",
        "image": "assets/images/PractiseImage/HeavyLightImages/book.png",
        "type": "heavy",
        "sound": "assets/sounds/book.mp3",
        "wrongSound": "assets/sounds/wrong.mp3"
      },
      {
        "key": "feather",
        "image": "assets/images/PractiseImage/HeavyLightImages/feather.png",
        "type": "light",
        "sound": "assets/sounds/feather.mp3",
        "wrongSound": "assets/sounds/wrong.mp3"
      },
      {
        "key": "balloon",
        "image": "assets/images/PractiseImage/HeavyLightImages/ball.png",
        "type": "light",
        "sound": "assets/sounds/balloon.mp3",
        "wrongSound": "assets/sounds/wrong.mp3"
      },
      {
        "key": "leaf",
        "image": "assets/images/PractiseImage/HeavyLightImages/leaf.png",
        "type": "light",
        "sound": "assets/sounds/leaf.mp3",
        "wrongSound": "assets/sounds/wrong.mp3"
      },
    ],
  ];

  late List<Map<String, dynamic>> currentItems;
  final Map<String, bool> score = {};
  int currentLevel = 0;

  final ValueNotifier<String?> hoveredZone = ValueNotifier(null);
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Populate localized labels after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentItems = rawLevels[currentLevel].map((item) {
          return {
            ...item,
            "label": _getLocalizedLabel(item['key']),
          };
        }).toList();
      });
    });
  }

  String _getLocalizedLabel(String key) {
    switch (key) {
      case "elephant":
        return tr(context).elephant;
      case "rock":
        return tr(context).rock;
      case "book":
        return tr(context).book;
      case "feather":
        return tr(context).feather;
      case "balloon":
        return tr(context).balloon;
      case "leaf":
        return tr(context).leaf;
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      score.clear();
      currentItems = rawLevels[currentLevel].map((item) {
        return {
          ...item,
          "label": _getLocalizedLabel(item['key']),
        };
      }).toList();
    });
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      _audioPlayer.play();
    } catch (e) {
      // silent error
    }
  }

  void _onCorrectDrop() {
    if (score.length == currentItems.length) {
      if (currentLevel + 1 < rawLevels.length) {
        setState(() {
          currentLevel++;
          score.clear();
          currentItems = rawLevels[currentLevel].map((item) {
            return {
              ...item,
              "label": _getLocalizedLabel(item['key']),
            };
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(context).levelStart(currentLevel + 1)),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(context).finishedAllLevels),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingItems =
    currentItems.where((item) => !score.containsKey(item['label'])).toList();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          '${tr(context).heavyLight} - ${tr(context).level} ${currentLevel + 1}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'ComicSans',
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        elevation: 8,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: hoveredZone,
                    builder: (context, value, _) {
                      return _buildDropZone(
                        tr(context).light,
                        'light',
                        isHighlighted: value == 'light',
                      );
                    },
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: hoveredZone,
                    builder: (context, value, _) {
                      return _buildDropZone(
                        tr(context).heavy,
                        'heavy',
                        isHighlighted: value == 'heavy',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: remainingItems.length,
                itemBuilder: (context, index) {
                  final item = remainingItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Draggable<Map<String, dynamic>>(
                      data: item,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _buildItem(item, dragging: true),
                        elevation: 6,
                      ),
                      childWhenDragging: Container(
                        width: 110,
                        height: 150,
                        color: Colors.transparent,
                      ),
                      child: _buildItem(item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, {bool dragging = false}) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
            dragging ? Colors.teal.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Image.asset(
            item['image'],
            height: dragging ? 90 : 110,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            item['label'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'ComicSans',
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(String label, String type, {bool isHighlighted = false}) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) {
        hoveredZone.value = type;
        return true;
      },
      onLeave: (data) {
        hoveredZone.value = null;
      },
      onAccept: (receivedItem) {
        hoveredZone.value = null;

        final bool correct = receivedItem['type'] == type;

        if (correct) {
          _playSound(receivedItem['sound']);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(context).greatJob),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          setState(() {
            score[receivedItem['label']] = true;
          });
          _onCorrectDrop();
        } else {
          _playSound(receivedItem['wrongSound'] ?? 'assets/sounds/wrong.mp3');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(context).wrongDrop),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));

          setState(() {
            currentItems.removeWhere((item) => item['label'] == receivedItem['label']);
            currentItems.add(receivedItem);
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 180,
          height: 220,
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.teal.shade300 : Colors.teal.shade100,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isHighlighted
                    ? Colors.teal.shade700.withOpacity(0.6)
                    : Colors.teal.shade300.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: isHighlighted ? Colors.teal.shade800 : Colors.teal.shade600,
              width: 4,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicSans',
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
