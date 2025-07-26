import 'package:flutter/material.dart';

// Simple model for the object
class ColorObject {
  final String name;
  final String emoji;
  final String colorName;

  ColorObject({
    required this.name,
    required this.emoji,
    required this.colorName,
  });
}

// Sample objects
final List<ColorObject> objects = [
  ColorObject(name: 'Apple', emoji: '🍎', colorName: 'Red'),
  ColorObject(name: 'Banana', emoji: '🍌', colorName: 'Yellow'),
  ColorObject(name: 'Grapes', emoji: '🍇', colorName: 'Purple'),
  ColorObject(name: 'Broccoli', emoji: '🥦', colorName: 'Green'),
  ColorObject(name: 'Blueberries', emoji: '🫐', colorName: 'Blue'),
  ColorObject(name: 'Orange', emoji: '🍊', colorName: 'Orange'),
];

// Map of color names to Flutter Colors
final Map<String, Color> colorMap = {
  'Red': Colors.red,
  'Yellow': Colors.yellow,
  'Purple': Colors.purple,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Orange': Colors.orange,
};

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Match Object to Color'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Color drop targets
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: colorMap.entries.map((entry) {
                final colorName = entry.key;
                final color = entry.value;
                final isMatched = matched.containsValue(colorName);

                return DragTarget<String>(
                  onWillAccept: (data) => !isMatched,
                  onAccept: (data) {
                    final obj = currentItems.firstWhere((e) => e.name == data);
                    if (obj.colorName == colorName) {
                      setState(() => matched[data] = colorName);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('✅ Correct!'),
                        duration: Duration(milliseconds: 400),
                        backgroundColor: Colors.green,
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('❌ Try Again!'),
                        duration: Duration(milliseconds: 400),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  builder: (context, candidate, rejected) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        colorName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('🖐️ Drag the correct object to its color',
                style: TextStyle(fontSize: 16)),
          ),
          // Draggable emojis
          Expanded(
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: currentItems.map((item) {
                final alreadyMatched = matched.containsKey(item.name);
                return alreadyMatched
                    ? const SizedBox(width: 60)
                    : Draggable<String>(
                  data: item.name,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Text(item.emoji, style: const TextStyle(fontSize: 48)),
                  ),
                  childWhenDragging: const SizedBox(width: 48),
                  child: Column(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 44)),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 14),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (matched.length == currentItems.length)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    matched.clear();
                    currentItems = [...objects]..shuffle();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Play Again"),
              ),
            )
        ],
      ),
    );
  }
}
