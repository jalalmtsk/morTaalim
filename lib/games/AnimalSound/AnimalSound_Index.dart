import 'package:flutter/material.dart';
import 'package:mortaalim/games/AnimalSound/AnimalSound_ListenMode.dart';
import 'package:mortaalim/games/AnimalSound/AnimalSound_GuessTheSound.dart';
import 'package:mortaalim/games/AnimalSound/AnimalSound_MatchAndDrop.dart';

class AnimalsoundIndex extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🐾 Animal Sound Game'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameModeCard(
                  title: '🎧 Listen Mode',
                  description: 'Tap animals to hear their sounds!',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ListenMode()),
                    );
                  },
                ),
                SizedBox(height: 20),
                GameModeCard(
                  title: '❓ Guess the Sound',
                  description: 'Listen and select the correct animal!',
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GuessSound()),
                    );
                  },
                ),
                SizedBox(height: 20),
                GameModeCard(
                  title: '🖐 Match & Drop',
                  description: 'Drag animals to match their sounds!',
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AS_MatchDrop()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameModeCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const GameModeCard({
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.pets,
              size: 50,
              color: Colors.white,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 5),
                  Text(description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      )),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }
}
