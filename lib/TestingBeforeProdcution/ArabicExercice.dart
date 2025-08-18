import 'package:flutter/material.dart';


class WordArabic extends StatefulWidget {
  const WordArabic({super.key});

  @override
  State<WordArabic> createState() => _WordGameState();
}

class _WordGameState extends State<WordArabic> {
  // Example word: "باب"
  final String correctWord = "باب";
  List<String> shuffledLetters = ["ب", "ا", "ب"];
  List<String?> answerSlots = [];

  @override
  void initState() {
    super.initState();
    shuffledLetters.shuffle();
    answerSlots = List<String?>.filled(correctWord.length, null);
  }

  void checkAnswer() {
    final answer = answerSlots.join();
    if (answer == correctWord) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("أحسنت! 🎉"),
          content: const Text("لقد كونت الكلمة بشكل صحيح"),
          actions: [
            TextButton(
              child: const Text("استمر"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text("لعبة تكوين الكلمات"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Target slots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(correctWord.length, (index) {
              return DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      color: answerSlots[index] == null
                          ? Colors.white
                          : Colors.orange.shade100,
                    ),
                    child: Center(
                      child: Text(
                        answerSlots[index] ?? "",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                onAccept: (letter) {
                  setState(() {
                    answerSlots[index] = letter;
                  });
                  checkAnswer();
                },
              );
            }),
          ),

          const SizedBox(height: 40),

          // Draggable letters
          Wrap(
            spacing: 16,
            children: shuffledLetters.map((letter) {
              return Draggable<String>(
                data: letter,
                feedback: Material(
                  color: Colors.transparent,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    letter,
                    style: const TextStyle(fontSize: 40, color: Colors.grey),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
