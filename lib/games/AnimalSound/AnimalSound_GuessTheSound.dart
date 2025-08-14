import 'package:flutter/material.dart';
import 'dart:math';

import 'package:just_audio/just_audio.dart';

class GuessSound extends StatefulWidget {
  @override
  _GuessSoundState createState() => _GuessSoundState();
}

class _GuessSoundState extends State<GuessSound> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final Random random = Random();

  final List<Map<String, String>> animals = [
    {'name': 'Dog', 'sound': 'sounds/dog.mp3', 'image': 'images/dog.png'},
    {'name': 'Cat', 'sound': 'sounds/cat.mp3', 'image': 'images/cat.png'},
    {'name': 'Lion', 'sound': 'sounds/lion.mp3', 'image': 'images/lion.png'},
    {'name': 'Elephant', 'sound': 'sounds/elephant.mp3', 'image': 'images/elephant.png'},
    {'name': 'Monkey', 'sound': 'sounds/monkey.mp3', 'image': 'images/monkey.png'},
  ];

  late Map<String, String> currentAnimal;
  String message = 'Listen and choose the correct animal';

  @override
  void initState() {
    super.initState();
    nextAnimal();
  }

  void playSound(String path) async {
    await audioPlayer.stop();
    await audioPlayer.play();
  }

  void nextAnimal() {
    currentAnimal = animals[random.nextInt(animals.length)];
    playSound(currentAnimal['sound']!);
  }

  void checkAnswer(String name) {
    setState(() {
      if (name == currentAnimal['name']) {
        message = 'Correct!';
      } else {
        message = 'Try again!';
      }
    });
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        message = 'Listen and choose the correct animal';
        nextAnimal();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercise Mode 1')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: TextStyle(fontSize: 22)),
          SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: animals.map((animal) {
              return ElevatedButton(
                onPressed: () => checkAnswer(animal['name']!),
                child: Text(animal['name']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
