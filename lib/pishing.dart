import 'package:flutter/material.dart';


class BearWordGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  WordGamePage();
  }
}

class WordGamePage extends StatefulWidget {
  @override
  _WordGamePageState createState() => _WordGamePageState();
}

class _WordGamePageState extends State<WordGamePage> {
  final List<String> choices = ['A', 'E', 'R', 'S'];
  final List<String> wordList = ['BEAR', 'TREE', 'FROG', 'LION', 'DUCK', 'FISH', 'BIRD', 'GOAT', 'MONK', 'WOLF'];
  final Map<String, String> wordTranslations = {
    'BEAR': 'Ours',
    'TREE': 'Arbre',
    'FROG': 'Grenouille',
    'LION': 'Lion',
    'DUCK': 'Canard',
    'FISH': 'Poisson',
    'BIRD': 'Oiseau',
    'GOAT': 'Chèvre',
    'MONK': 'Moine',
    'WOLF': 'Loup'
  };

  int currentWordIndex = 0;
  String? letter1;
  String? letter2;

  String get currentWord => wordList[currentWordIndex];
  String get translation => wordTranslations[currentWord] ?? '';

  void checkAnswer() {
    if (letter1 != null && letter2 != null) {
      final completedWord = currentWord[0] + letter1! + letter2! + currentWord[3];
      if (completedWord == currentWord) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Bravo !'),
            content: Text('Tu as bien écrit "$currentWord" ("$translation") !'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  loadNextWord();
                },
                child: Text('Suivant'),
              )
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Essaie encore !'),
            content: Text('Ce n’est pas correct. Essaie encore.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    letter1 = null;
                    letter2 = null;
                  });
                },
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    }
  }


  void loadNextWord() {
    setState(() {
      letter1 = null;
      letter2 = null;
      currentWordIndex = (currentWordIndex + 1) % wordList.length;
    });
  }

  Widget buildDropBox(String? letter, void Function(String) onAccept) {
    return DragTarget<String>(
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) => Container(
        width: 80,
        height: 80,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(10),
          color: letter == null ? Colors.white : Colors.green[100],
        ),
        alignment: Alignment.center,
        child: Text(
          letter ?? '',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[900]),
        ),
      ),
    );
  }

  Widget buildDraggable(String letter) {
    return Draggable<String>(
      data: letter,
      child: LetterTile(letter: letter),
      feedback: Material(
        color: Colors.transparent,
        child: LetterTile(letter: letter),
      ),
      childWhenDragging: LetterTile(letter: '', faded: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backGround.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Écris le mot en anglais :', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('"$translation" → ?', style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic)),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(currentWord[0], style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green[800])),
                buildDropBox(letter1, (value) {
                  setState(() {
                    letter1 = value;
                    checkAnswer();
                  });
                }),
                buildDropBox(letter2, (value) {
                  setState(() {
                    letter2 = value;
                    checkAnswer();
                  });
                }),
                Text(currentWord[3], style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green[800])),
              ],
            ),
            SizedBox(height: 50),
            Wrap(
              spacing: 16,
              children: choices.map((c) => buildDraggable(c)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class LetterTile extends StatelessWidget {
  final String letter;
  final bool faded;

  const LetterTile({required this.letter, this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: faded ? Colors.grey[300] : Colors.white,
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter,
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
    );
  }
}
