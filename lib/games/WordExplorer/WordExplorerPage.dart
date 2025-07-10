import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class WordExplorer extends StatelessWidget {
  const WordExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageSelectionPage();
  }
}

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Language')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LanguageButton('English', context),
            LanguageButton('Français', context),
            LanguageButton('العربية', context),
          ],
        ),
      ),
    );
  }

  Widget LanguageButton(String lang, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WordGamePage(language: lang)),
          );
        },
        child: Text(lang),
      ),
    );
  }
}



class WordGamePage extends StatefulWidget {
  final String language;
  const WordGamePage({super.key, required this.language});

  @override
  _WordGamePageState createState() => _WordGamePageState();
}

class _WordGamePageState extends State<WordGamePage> {
  final Map<String, List<String>> wordBank = {
    'English': ['APPLE',
      'BREAD',
      'CHAIR',
      'DREAM',
      'FLOOR',
      'GHOST',
      'HEART',
      'JELLY',
      'KNIFE',
      'LIGHT'],
    'Français': ['LIVRES', 'BOUTON', 'JARDIN', 'ÉCOLES', 'VOYAGE', 'ANIMAUX', 'MONDE', 'IMAGES'],
    'العربية': ['مدرسة', 'كوكب', 'زجاجة', 'مفتاح', 'مطبخ', 'مملكة', 'صورة', 'حديقة'],
  };

  late List<String> currentWords;
  late String currentWord;
  List<String> choices = [];
  List<String> placedLetters = ['', '', '', ''];
  List<String> remainingChoices = [];
  int level = 1;
  int score = 0;
  int timer = 20;
  Timer? countdown;
  bool showHint = false;

  @override
  void initState() {
    super.initState();
    currentWords = wordBank[widget.language]!;
    loadNewWord();
  }

  void loadNewWord() {
    countdown?.cancel();
    setState(() {
      List<String> levelWords = currentWords.toList(); // accept all words
      currentWord = (levelWords..shuffle()).first.toUpperCase();
      placedLetters = ['', '', '', ''];
      choices = getChoices();
      remainingChoices = List.from(choices);
      showHint = false;
      startTimer();
    });
  }

  void startTimer() {
    timer = 10 + (level * 5);
    countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer == 0) {
        t.cancel();
        showEndDialog('Time’s up!');
      } else {
        setState(() => timer--);
      }
    });
  }

  void checkAnswer() {
    if (placedLetters.every((l) => l != '')) {
      final guess = currentWord[0] +
          placedLetters[0] +
          placedLetters[1] +
          placedLetters[2] +
          placedLetters[3] +
          currentWord.substring(5);
      if (guess == currentWord) {
        countdown?.cancel();
        setState(() {
          score += level * 10;
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Correct!'),
            content: Text('You wrote "$currentWord"'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    level = level < 3 ? level + 1 : 1;
                  });
                  loadNewWord();
                },
                child: const Text('Next'),
              )
            ],
          ),
        );
      } else {
        showEndDialog('Incorrect. Try again!');
      }
    }
  }

  void showEndDialog(String message) {
    countdown?.cancel();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              loadNewWord();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  List<String> getChoices() {
    Set<String> chars = currentWord.substring(1, 5).split('').toSet();
    while (chars.length < 8) {
      chars.add(String.fromCharCode(Random().nextInt(26) + 65));
    }
    return chars.toList()..shuffle();
  }

  Widget buildDropBox(int index) {
    bool isEmpty = placedLetters[index] == '';
    bool shouldHint = showHint && isEmpty;

    return DragTarget<String>(
      onAccept: (val) {
        setState(() {
          placedLetters[index] = val;
          remainingChoices.remove(val);
          checkAnswer();
        });
      },
      builder: (context, candidateData, rejectedData) => Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
              color: shouldHint ? Colors.orange : Colors.green, width: 3),
          borderRadius: BorderRadius.circular(10),
          color: isEmpty ? Colors.white : Colors.green[100],
        ),
        alignment: Alignment.center,
        child: Text(
          placedLetters[index],
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildDraggable(String letter) {
    return Draggable<String>(
      data: letter,
      child: LetterTile(letter: letter),
      feedback:
      Material(color: Colors.transparent, child: LetterTile(letter: letter)),
      childWhenDragging: LetterTile(letter: '', faded: true),
    );
  }

  Widget buildTimerBar() {
    double progress = timer / (10 + (level * 5));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        color: Colors.red,
        backgroundColor: Colors.red.shade100,
      ),
    );
  }

  @override
  void dispose() {
    countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String first = currentWord[0];
    String last = currentWord.length > 5 ? currentWord[5] : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.language} | Level $level'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backGround.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('Score: $score',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            buildTimerBar(),
            const SizedBox(height: 20),
            Text(widget.language == 'العربية'
                ? 'اكتب هذه الكلمة'
                : 'Write this word'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(first,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ...List.generate(4, (i) => buildDropBox(i)),
                Text(last,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                for (int i = 0; i < 4; i++) {
                  if (placedLetters[i].isEmpty) {
                    String correctLetter = currentWord[i + 1]; // positions 1 to 4
                    setState(() {
                      placedLetters[i] = correctLetter;
                      remainingChoices.remove(correctLetter);
                    });
                    break; // only reveal one letter
                  }
                }
                checkAnswer(); // in case it completes the word
              },
              child: Text(widget.language == 'العربية'
                  ? 'كشف حرف'
                  : 'Reveal a Letter'),
            ),

            const SizedBox(height: 30),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: remainingChoices.map((c) => buildDraggable(c)).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                countdown?.cancel();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('← Back'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class LetterTile extends StatelessWidget {
  final String letter;
  final bool faded;
  const LetterTile({super.key, required this.letter, this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: faded ? Colors.grey[300] : Colors.white,
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}

