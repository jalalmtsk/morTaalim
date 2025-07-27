import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../tools/audio_tool.dart';

class ColorObject {
  final String name;
  final String emoji;
  final String colorName;

  ColorObject({required this.name, required this.emoji, required this.colorName});
}

final List<ColorObject> objects = [
  ColorObject(name: 'Apple', emoji: '🍎', colorName: 'Rouge'),
  ColorObject(name: 'Banana', emoji: '🍌', colorName: 'Jaune'),
  ColorObject(name: 'Grapes', emoji: '🍇', colorName: 'Mauve'),
  ColorObject(name: 'Broccoli', emoji: '🥦', colorName: 'Vert'),
  ColorObject(name: 'Blueberries', emoji: '🫐', colorName: 'Bleu'),
  ColorObject(name: 'Orange', emoji: '🍊', colorName: 'Orange'),
];

final Map<String, Color> colorMap = {
  'Rouge': Colors.redAccent,
  'Jaune': Colors.amber,
  'Mauve': Colors.deepPurpleAccent,
  'Vert': Colors.lightGreen,
  'Bleu': Colors.blueAccent,
  'Orange': Colors.deepOrange,
};

final MusicPlayer _player = MusicPlayer();

class ColorMatchingGame extends StatefulWidget {
  const ColorMatchingGame({super.key});

  @override
  State<ColorMatchingGame> createState() => _ColorMatchingGameState();
}

class _ColorMatchingGameState extends State<ColorMatchingGame> {
  final Map<String, String> matched = {};
  late List<ColorObject> currentItems;

  @override
  void initState() {
    super.initState();
    currentItems = [...objects]..shuffle();
  }

  void showCompletedOverlay() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Bravo !'),
        content: const Text('Tu as bien associé toutes les couleurs !'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                matched.clear();
                currentItems = [...objects]..shuffle();
              });
            },
            child: const Text("🔁 Rejouer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('🎨 Match les couleurs'),
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          const Userstatutbar(),
          const SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              children: colorMap.entries.map((entry) {
                final colorName = entry.key;
                final color = entry.value;
                final isMatched = matched.containsValue(colorName);

                return DragTarget<String>(
                  onWillAccept: (data) => !isMatched,
                  onAccept: (data) {
                    _player.play("assets/audios/QuizGame_Sounds/correct.mp3");
                    final obj = currentItems.firstWhere((e) => e.name == data);
                    if (obj.colorName == colorName) {

                      setState(() {
                        matched[data] = colorName;
                        if (matched.length == currentItems.length) {
                          Future.delayed(const Duration(milliseconds: 500), showCompletedOverlay);
                        }
                      });
                    } else {
                      _player.play("assets/audios/QuizGame_Sounds/incorrect.mp3");

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Mauvais choix !'),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(milliseconds: 600),
                        ),
                      );
                    }
                  },
                  builder: (context, candidate, rejected) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isMatched ? color.withOpacity(0.5) : color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMatched ? Colors.black : color,
                          width: 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        colorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              '🖐️ Glisse le fruit ou légume sur la bonne couleur',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: currentItems.map((item) {
                final isUsed = matched.containsKey(item.name);
                return isUsed
                    ? const SizedBox(width: 64)
                    : Draggable<String>(
                  data: item.name,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  childWhenDragging: const SizedBox(width: 48),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 42)),
                        const SizedBox(height: 4),
                        Text(item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
